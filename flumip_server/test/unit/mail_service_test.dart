import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mail_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_mail_sender.dart';
import '../support/fake_process_runner.dart';
import '../support/matchers.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// MailService with a resolvable recipient, standing in for the user system
/// that will eventually supply one.
class RecipientMailService extends MailService {
  final String? recipient;
  RecipientMailService(this.recipient);

  @override
  Future<String?> resolveRecipient(Session session, Project project) async =>
      recipient;
}

/// Fails on notification, to prove a mail problem cannot break finalization.
class ThrowingMailService extends MailService {
  @override
  Future<void> notifyProjectFinished(
    Session session,
    Project project, {
    required bool failed,
  }) async {
    throw Exception('mail exploded');
  }
}

/// Records how the trigger invoked the notification.
class RecordingMailService extends MailService {
  int calls = 0;
  bool? lastFailed;

  @override
  Future<void> notifyProjectFinished(
    Session session,
    Project project, {
    required bool failed,
  }) async {
    calls++;
    lastFailed = failed;
  }
}

// One shared set of fakes registered once: withServerpod group bodies run at
// collection time, so registering different fakes per group would leave only
// the last ones active. Reset before each test instead.
final fake = FakeMailSender();
final fakeProcess = FakeProcessRunner();

void main() {
  withServerpod('MailService.sendTestMail', (sessionBuilder, endpoints) {
    // The mipgen trigger group runs _generateUCSCTrack, so stub the process
    // runner too rather than invoking a real `python`.
    setup(processRunner: fakeProcess, mailSender: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final mailService = sl<MailService>();

    test('sends a test message using the configured SMTP settings', () async {
      await overrideMailSettings(
        session,
        smtpServer: 'smtp.example.test',
        smtpPort: 2525,
        smtpFrom: 'flumip@example.test',
        startTLS: false,
      );

      await mailService.sendTestMail(session, 'admin@example.test');

      expect(fake.sent.length, 1);
      final mail = fake.lastSent!;
      expect(mail.to, 'admin@example.test');
      expect(mail.host, 'smtp.example.test');
      expect(mail.port, 2525);
      expect(mail.from, 'flumip@example.test');
      expect(mail.startTLS, isFalse);
      expect(mail.subject, contains('test'));
    }, tags: ['unit']);

    test('works even when mail is globally disabled', () async {
      // The point of a test mail is to validate config before switching on.
      await overrideMailSettings(
        session,
        mailActive: false,
        smtpServer: 'smtp.example.test',
      );
      await mailService.sendTestMail(session, 'admin@example.test');
      expect(fake.sent.length, 1);
    }, tags: ['unit']);

    test('throws when no recipient is supplied', () async {
      await overrideMailSettings(session, smtpServer: 'smtp.example.test');
      expect(
        () => mailService.sendTestMail(session, ''),
        throwsMessage('No recipient supplied'),
      );
    }, tags: ['unit']);

    test('throws when no SMTP server is configured', () async {
      await overrideMailSettings(session, smtpServer: '');
      expect(
        () => mailService.sendTestMail(session, 'admin@example.test'),
        throwsMessage('No SMTP server configured'),
      );
    }, tags: ['unit']);

    test('propagates SMTP failures so the admin sees them', () async {
      await overrideMailSettings(session, smtpServer: 'smtp.example.test');
      fake.error = Exception('connection refused');
      expect(
        () => mailService.sendTestMail(session, 'admin@example.test'),
        throwsMessage('connection refused'),
      );
    }, tags: ['unit']);
  });

  withServerpod('MailService.notifyProjectFinished', (
    sessionBuilder,
    endpoints,
  ) {
    setUp(fake.reset);
    var session = sessionBuilder.build();

    Future<Project> seedNotifiableProject(
      Session session, {
      bool emailNotification = true,
      int? owner,
    }) async {
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        owner: owner,
      );
      project.emailNotification = emailNotification;
      project.completedIn = const Duration(minutes: 3);
      project.size = 4096;
      await ProjectService().updateProject(session, project);
      return project;
    }

    test('skips when mail is globally disabled', () async {
      await overrideMailSettings(
        session,
        mailActive: false,
        smtpServer: 'smtp.example.test',
      );
      final project = await seedNotifiableProject(session);
      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);
      expect(fake.sent, isEmpty);
    }, tags: ['unit']);

    test('skips when the project opted out', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final project = await seedNotifiableProject(
        session,
        emailNotification: false,
      );
      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);
      expect(fake.sent, isEmpty);
    }, tags: ['unit']);

    test(
      'skips when the project is unowned, with the real MailService',
      () async {
        await overrideMailSettings(
          session,
          mailActive: true,
          smtpServer: 'smtp.example.test',
        );
        final project = await seedNotifiableProject(session);
        // No override: the production resolveRecipient finds no owner on a
        // project seeded without one, which is every project on a no-auth
        // install.
        await MailService().notifyProjectFinished(
          session,
          project,
          failed: false,
        );
        expect(fake.sent, isEmpty);
      },
      tags: ['unit'],
    );

    test('sends to the owner, with the real MailService', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
        smtpFrom: 'flumip@example.test',
      );
      final owner = await seedSignedInUser(
        session,
        email: 'owner@example.test',
      );
      final project = await seedNotifiableProject(
        session,
        owner: owner.user.id,
      );

      // The whole path, unoverridden: owner id -> FlumipUser -> email -> send.
      await MailService().notifyProjectFinished(
        session,
        project,
        failed: false,
      );

      expect(fake.sent.length, 1);
      expect(fake.lastSent!.to, 'owner@example.test');
      expect(fake.lastSent!.subject, contains('demo'));
    }, tags: ['unit']);

    test('sends a success notification when a recipient exists', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
        smtpFrom: 'flumip@example.test',
      );
      final project = await seedNotifiableProject(session);
      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);

      expect(fake.sent.length, 1);
      final mail = fake.lastSent!;
      expect(mail.to, 'user@example.test');
      expect(mail.subject, contains('finished'));
      expect(mail.subject, contains('demo'));
      expect(mail.body, contains('successfully'));
    }, tags: ['unit']);

    test('sends both an HTML and a text part, with the run detail', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(session, name: 'common');
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        genome: genome.id,
        snp: snp.id,
        genes: ['BRCA1', 'TP53'],
      );
      project.emailNotification = true;
      project.completedIn = const Duration(minutes: 4, seconds: 9);
      project.size = 2400000000;
      await ProjectService().updateProject(session, project);

      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);

      final mail = fake.lastSent!;
      // Both parts, so a plain-text reader does not receive a blank message.
      expect(mail.html, isNotNull);
      expect(mail.html, contains('<!doctype html>'));
      expect(mail.body, isNot(contains('<')));
      // The names behind the ids were resolved, not printed as numbers.
      for (final part in [mail.body, mail.html!]) {
        expect(part, contains('hg38'));
        expect(part, contains('common'));
        expect(part, contains('2 genes'));
        expect(part, contains('4 min 09 s'));
        expect(part, contains('2.40 GB'));
      }
    }, tags: ['unit']);

    test('a missing genome row costs a line, not the notification', () async {
      // Best-effort lookups: the mail is worth less than the job it reports on.
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        genome: 999999,
      );
      project.emailNotification = true;
      await ProjectService().updateProject(session, project);

      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);

      expect(fake.sent, hasLength(1));
      expect(fake.lastSent!.body, isNot(contains('999999')));
    }, tags: ['unit']);

    test('sends a failure notification including the error', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final project = await seedNotifiableProject(session);
      project.error = 'MIP generation failed';
      await ProjectService().updateProject(session, project);

      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: true);

      expect(fake.sent.length, 1);
      expect(fake.lastSent!.subject, contains('failed'));
      expect(fake.lastSent!.body, contains('MIP generation failed'));
    }, tags: ['unit']);

    test('swallows SMTP failures so the job is unaffected', () async {
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final project = await seedNotifiableProject(session);
      fake.error = Exception('connection refused');
      // Must NOT throw.
      await RecipientMailService(
        'user@example.test',
      ).notifyProjectFinished(session, project, failed: false);
      expect(fake.sent.length, 1);
    }, tags: ['unit']);
  });

  withServerpod('MailService.resolveRecipient', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();

    test('resolves the owning user\'s email address', () async {
      final options = await seedOptions(session);
      final owner = await seedSignedInUser(
        session,
        email: 'owner@example.test',
      );
      final project = await seedProject(
        session,
        options: options.id!,
        owner: owner.user.id,
      );

      expect(
        await MailService().resolveRecipient(session, project),
        'owner@example.test',
      );
    }, tags: ['unit']);

    test('resolves null for an unowned project', () async {
      // Not an edge case: this is every project predating authorization, and
      // every project created while single sign-on is off.
      final options = await seedOptions(session);
      final project = await seedProject(session, options: options.id!);

      expect(await MailService().resolveRecipient(session, project), isNull);
    }, tags: ['unit']);

    test('resolves null when the owning user no longer exists', () async {
      final options = await seedOptions(session);
      final owner = await seedSignedInUser(
        session,
        email: 'ghost@example.test',
      );
      final project = await seedProject(
        session,
        options: options.id!,
        owner: owner.user.id,
      );

      // onDelete=SetNull clears the column in the database, but this in-memory
      // Project was read before the delete and still carries the stale id — so
      // the lookup, not the column, is what has to cope.
      await FlumipUser.db.deleteRow(session, owner.user);

      expect(project.owner, isNotNull);
      expect(await MailService().resolveRecipient(session, project), isNull);
    }, tags: ['unit']);
  });

  withServerpod('mipgenIsFinished notification trigger', (
    sessionBuilder,
    endpoints,
  ) {
    setUp(() {
      fake.reset();
      fakeProcess.reset();
    });
    // These tests swap the registered MailService; restore the real one so the
    // locator is not left polluted for other groups.
    tearDown(() => sl.registerSingleton<MailService>(MailService()));
    var session = sessionBuilder.build();

    Future<Project> prepare({required bool withProgress}) async {
      final base = createTempDir('mailtrigger');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        ucscTrackGenerator: 'ucsc-gen',
      );
      await overrideMailSettings(
        session,
        mailActive: true,
        smtpServer: 'smtp.example.test',
      );
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        pid: 999,
        active: true,
        started: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final dir = '${base.path}/proj';
      Directory(dir).createSync(recursive: true);
      if (withProgress) {
        File('$dir/run.progress.txt').writeAsStringSync('done\n');
      }
      return project;
    }

    test('notifies with failed=false on success', () async {
      final recording = RecordingMailService();
      sl.registerSingleton<MailService>(recording);
      final project = await prepare(withProgress: true);

      await sl<MipgenService>().mipgenIsFinished(session, project);

      expect(recording.calls, 1);
      expect(recording.lastFailed, isFalse);
    }, tags: ['unit']);

    test('notifies with failed=true when generation failed', () async {
      final recording = RecordingMailService();
      sl.registerSingleton<MailService>(recording);
      final project = await prepare(withProgress: false);

      await sl<MipgenService>().mipgenIsFinished(session, project);

      expect(recording.calls, 1);
      expect(recording.lastFailed, isTrue);
    }, tags: ['unit']);

    test('a failing notification still leaves the project finalized', () async {
      sl.registerSingleton<MailService>(ThrowingMailService());
      final project = await prepare(withProgress: true);

      // Must NOT throw despite the notification blowing up.
      await sl<MipgenService>().mipgenIsFinished(session, project);

      final reloaded = await ProjectService().getProject(session, project.id!);
      expect(reloaded.active, isFalse);
      expect(reloaded.pid, 0);
    }, tags: ['unit']);
  });
}
