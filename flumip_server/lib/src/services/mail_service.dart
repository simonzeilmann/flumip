import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mail_sender.dart';
import 'package:flumip_server/src/services/mail_templates.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Sends the application's email notifications.
///
/// Delivery itself is delegated to [MailSender] (resolved from the service
/// locator) so tests can substitute a fake.
class MailService {
  MailService();

  /// Sends a test message to [to] so an administrator can validate the SMTP
  /// configuration without running a job.
  ///
  /// Unlike the notification path this deliberately does **not** swallow
  /// errors: the caller wants to see why delivery failed. It also ignores
  /// [Settings.mailActive] so the configuration can be verified before mail is
  /// switched on.
  Future<void> sendTestMail(Session session, String to) async {
    final settingsService = sl<SettingsService>();
    final mailSender = sl<MailSender>();

    if (to.isEmpty) {
      session.log('No recipient supplied for test mail', level: LogLevel.error);
      throw ArgumentException(
        message: 'Enter an address to send the test email to.',
      );
    }

    final settings = await settingsService.getSettings(session);
    if (settings.smtpServer.isEmpty) {
      session.log('No SMTP server configured', level: LogLevel.error);
      throw ArgumentException(
        message:
            'No SMTP server is configured. Fill in the mail settings and '
            'save them before sending a test email.',
      );
    }

    session.log('Sending test mail to $to', level: LogLevel.info);
    // Deliberately the same layout as a real notification, so clicking "Send
    // test email" previews what users will actually receive — a styling problem
    // then surfaces here rather than in somebody's first genuine notification.
    // The SMTP settings are echoed back because confirming those is the whole
    // reason for sending it.
    final site = settings.authPublicUrl.trim();
    final details = TestMailDetails(
      smtpServer: settings.smtpServer,
      smtpPort: settings.smtpPort,
      from: settings.smtpFrom,
      startTLS: settings.startTLS,
      siteUrl: site.isEmpty ? null : site,
    );
    await mailSender.send(
      settings: settings,
      to: to,
      subject: buildTestSubject(),
      body: buildTestTextBody(details),
      html: buildTestHtmlBody(details),
    );
    session.log('Test mail sent to $to', level: LogLevel.info);
  }

  /// Notifies the owner of [project] that MIP generation has finished.
  ///
  /// [failed] selects the failure wording. Sending is skipped (with a log
  /// entry) when mail is disabled globally, when the project opted out, or when
  /// no recipient can be resolved. Delivery errors are logged but never
  /// rethrown — a notification must not fail the job it reports on.
  Future<void> notifyProjectFinished(
    Session session,
    Project project, {
    required bool failed,
  }) async {
    final settingsService = sl<SettingsService>();
    final mailSender = sl<MailSender>();

    final settings = await settingsService.getSettings(session);
    if (!settings.mailActive) {
      session.log(
        'Mail is disabled, skipping notification for project ${project.id}',
        level: LogLevel.info,
      );
      return;
    }
    if (!project.emailNotification) {
      session.log(
        'Project ${project.id} has notifications disabled, skipping',
        level: LogLevel.info,
      );
      return;
    }

    final recipient = await resolveRecipient(session, project);
    if (recipient == null || recipient.isEmpty) {
      session.log(
        'No recipient available for project ${project.id}, skipping '
        'notification (the project is unowned, so there is nobody to notify)',
        level: LogLevel.warning,
      );
      return;
    }

    final details = await _detailsFor(
      session,
      project,
      settings,
      failed: failed,
    );

    try {
      await mailSender.send(
        settings: settings,
        to: recipient,
        subject: buildSubject(details),
        body: buildTextBody(details),
        html: buildHtmlBody(details),
      );
      session.log(
        'Notification sent for project ${project.id} to $recipient',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      // Never let a mail failure surface into the job that triggered it.
      session.log(
        'Failed to send notification for project ${project.id}: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Gathers what the message says, resolving the names behind the ids.
  ///
  /// Every lookup is best-effort: a missing genome or SNP row leaves that line
  /// out of the mail rather than failing the send. A notification is worth less
  /// than the job it reports on, so nothing here may throw — the caller already
  /// swallows delivery errors, and this runs before that guard.
  Future<ProjectMailDetails> _detailsFor(
    Session session,
    Project project,
    Settings settings, {
    required bool failed,
  }) async {
    String? genomeName;
    String? snpName;
    try {
      if (project.genome != null) {
        genomeName = (await Genome.db.findById(session, project.genome!))?.name;
      }
      if (project.snp != null) {
        snpName = (await Snp.db.findById(session, project.snp!))?.name;
      }
    } catch (e) {
      session.log(
        'Could not resolve genome/SNP names for the notification: $e',
        level: LogLevel.warning,
      );
    }

    final site = settings.authPublicUrl.trim();
    return ProjectMailDetails(
      projectName: project.name,
      failed: failed,
      error: project.error,
      completedIn: project.completedIn,
      sizeBytes: project.size,
      genomeName: genomeName,
      snpName: snpName,
      geneCount: project.genes?.length ?? 0,
      // Empty is the default, and a link to nowhere is worse than no link.
      siteUrl: site.isEmpty ? null : site,
    );
  }

  /// Resolves the email address to notify for [project]: its owner's.
  ///
  /// Null when the project is unowned, which means nobody is notified. That is
  /// not an edge case — it is every project created before authorization
  /// existed, and every project created while single sign-on is off, since
  /// nothing sets an owner without an identity to set it to. A no-auth install
  /// therefore sends no project notifications at all; giving it any would need a
  /// fallback address on [Settings], which nothing currently asks for.
  ///
  /// Null again when the owner row is gone. `Project.owner` is `onDelete=SetNull`
  /// so a deleted identity normally leaves the column null on its own, but a
  /// [Project] read before that deletion still carries the old id.
  ///
  /// This deliberately asks *who owns the project* rather than who is calling.
  /// The only production caller is [notifyProjectFinished], reached from the
  /// mipgen future call, which runs with no authenticated user — an ownership
  /// lookup works there, an authorization check would not. Do not "tidy" it into
  /// one.
  ///
  /// Overridable (rather than private) so tests can supply a recipient without
  /// seeding an identity.
  Future<String?> resolveRecipient(Session session, Project project) async {
    final owner = project.owner;
    if (owner == null) return null;

    final user = await FlumipUser.db.findById(session, owner);
    return user?.email;
  }
}
