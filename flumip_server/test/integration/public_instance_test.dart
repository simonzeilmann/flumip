import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/future_calls/demo_mode_cleanup_future_call.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/seed.dart';
import '../support/temp_dir.dart';
import 'test_tools/serverpod_test_tools.dart';

/// A public instance: anonymous visitors accept the entry notice, become
/// guests, and see only their own projects — which expire.
///
/// The routes themselves (`/auth/guest`, `/auth/session`) are thin wrappers
/// over [AuthService.acceptAsGuest] and [AuthService.issueApiToken], so the
/// rules are tested here through those; the HTTP shape is checked against a
/// running server.
void main() {
  withServerpod('A public instance', (sessionBuilder, endpoints) {
    setup(authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final auth = sl<AuthService>();

    late Directory base;

    Future<Settings> configure({
      bool publicMode = true,
      int retentionHours = 168,
      int maxLifetimeDays = 30,
      int guestMaxProjects = 10,
      int termsVersion = 1,
    }) async {
      final settings = await overrideSettingsDirs(
        session,
        projectDir: base.path,
      );
      settings
        ..publicMode = publicMode
        ..demoModeRetentionHours = retentionHours
        ..maxProjectLifetimeDays = maxLifetimeDays
        ..guestMaxProjects = guestMaxProjects
        ..termsVersion = termsVersion;
      final saved = await Settings.db.updateRow(session, settings);
      await sl<AuthRuntime>().refresh(session);
      return saved;
    }

    setUp(() async {
      base = createTempDir('public');
      // Rows are rolled back between tests, the local cache is not, and ids
      // restart — a cached session from an earlier test would otherwise answer
      // for a different row with the same id.
      await session.caches.localPrio.clear();
      await configure();
    });

    /// A guest who has just accepted the notice, and a session builder that
    /// calls endpoints as them — with the bearer the handler would resolve.
    Future<({TestSessionBuilder builder, int userId, String cookie})>
    acceptAsGuest() async {
      final accepted = await auth.acceptAsGuest(session);
      return (
        builder: sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            AuthService.guestEmail,
            const <Scope>{},
            authId: '${accepted.session.id}',
          ),
        ),
        userId: accepted.session.userId,
        cookie: accepted.cookieValue,
      );
    }

    group('the entry notice', () {
      test('public mode enforces with no identity provider', () async {
        expect(sl<AuthRuntime>().isEnforcing, isTrue);
      });

      test('accepting creates a guest and records what was accepted', () async {
        await configure(termsVersion: 3);
        final guest = await acceptAsGuest();

        final user = await FlumipUser.db.findById(session, guest.userId);
        expect(user!.issuer, AuthService.guestIssuer);
        expect(user.email, isEmpty, reason: 'keeps guests out of every mail');
        expect(user.termsAcceptedAt, isNotNull);
        expect(user.termsVersion, 3);

        final row = await AuthSession.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(guest.userId),
        );
        expect(row!.isGuest, isTrue);
        expect(row.isAdmin, isFalse);
      });

      test('there is nothing to accept on an internal install', () async {
        await configure(publicMode: false);
        await expectLater(
          auth.acceptAsGuest(session),
          throwsA(isA<AuthFlowException>()),
        );
      });

      test('the guest cookie mints a bearer that says it is a guest', () async {
        final guest = await acceptAsGuest();
        final issued = await auth.issueApiToken(session, guest.cookie);
        expect(issued, isNotNull);
        expect(issued!.isGuest, isTrue);
      });

      test(
        'a guest session slides forward by the longest project life',
        () async {
          await configure(maxLifetimeDays: 30);
          final guest = await acceptAsGuest();
          final issued = await auth.issueApiToken(session, guest.cookie);
          final days = issued!.sessionExpires
              .difference(DateTime.now().toUtc())
              .inDays;
          expect(days, inInclusiveRange(29, 30));
        },
      );

      test(
        'raising the terms version asks again, keeping the identity',
        () async {
          final guest = await acceptAsGuest();
          await configure(termsVersion: 2);

          await expectLater(
            auth.issueApiToken(session, guest.cookie),
            throwsA(isA<TermsNotAcceptedException>()),
          );

          final again = await auth.acceptAsGuest(
            session,
            cookieValue: guest.cookie,
          );
          expect(again.session.userId, guest.userId, reason: 'same guest');
          expect(await auth.issueApiToken(session, guest.cookie), isNotNull);
        },
      );

      test('a guest cookie stops working once public mode is off', () async {
        // On an install that requires sign-in it would otherwise get straight
        // past the gate.
        final guest = await acceptAsGuest();
        await configure(publicMode: false);
        expect(await auth.issueApiToken(session, guest.cookie), isNull);
      });

      test("a guest's bearer is refused once public mode is off", () async {
        final guest = await acceptAsGuest();
        final issued = await auth.issueApiToken(session, guest.cookie);
        expect(
          await flumipAuthenticationHandler(session, issued!.token),
          isNotNull,
        );

        await configure(publicMode: false);
        expect(
          await flumipAuthenticationHandler(session, issued.token),
          isNull,
          reason: 'even a bearer minted moments ago and still cached',
        );
      });

      test('guests without a session are pruned, with their projects '
          'falling to administrators', () async {
        final guest = await acceptAsGuest();
        final options = await seedOptions(session);
        final project = await seedProject(
          session,
          options: options.id!,
          owner: guest.userId,
        );
        // Old enough to be past the grace period, and its session gone.
        final user = await FlumipUser.db.findById(session, guest.userId);
        user!.created = DateTime.now().toUtc().subtract(
          const Duration(days: 2),
        );
        await FlumipUser.db.updateRow(session, user);
        await AuthSession.db.deleteWhere(
          session,
          where: (t) => t.userId.equals(guest.userId),
        );

        await auth.pruneExpired(session);

        expect(await FlumipUser.db.findById(session, guest.userId), isNull);
        final orphan = await Project.db.findById(session, project.id!);
        expect(orphan!.owner, isNull);
      });
    });

    group('isolation', () {
      test("a guest neither lists nor opens another guest's project", () async {
        final alice = await acceptAsGuest();
        final bob = await acceptAsGuest();
        final options = await seedOptions(session);
        final project = await seedProject(
          session,
          name: 'alice-only',
          options: options.id!,
          owner: alice.userId,
        );

        final bobs = await endpoints.project.getProjects(bob.builder);
        expect(bobs.map((p) => p.name), isNot(contains('alice-only')));
        await expectLater(
          endpoints.project.getProject(bob.builder, project.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );

        final alices = await endpoints.project.getProjects(alice.builder);
        expect(alices.map((p) => p.name), contains('alice-only'));
      });

      test('an unowned project is hidden from guests', () async {
        final guest = await acceptAsGuest();
        final options = await seedOptions(session);
        await seedProject(session, name: 'orphan', options: options.id!);

        final visible = await endpoints.project.getProjects(guest.builder);
        expect(visible.map((p) => p.name), isNot(contains('orphan')));
      });

      test('a new project belongs to the guest who made it', () async {
        final guest = await acceptAsGuest();
        final options = await seedOptions(session);

        final project = await endpoints.project.createProject(
          guest.builder,
          'mine',
          options,
        );
        expect(project.owner, guest.userId);
      });
    });

    group('what a guest may not do', () {
      test('add an SNP set', () async {
        final guest = await acceptAsGuest();
        final genome = await seedGenome(session, name: 'hg38');
        final request = CustomSnpRequestDto(
          genomeId: genome.id!,
          name: 'mine',
          description: '',
          private: true,
        );

        await expectLater(
          endpoints.snp.createUpload(guest.builder, request),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.snp.importFromUrls(guest.builder, request),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.snp.collectCustomSnps(guest.builder),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('manage genomes', () async {
        final guest = await acceptAsGuest();
        final genome = await seedGenome(session, name: 'hg38');

        await expectLater(
          endpoints.genome.collectGenomes(guest.builder),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.genome.indexFasta(guest.builder, genome.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.genome.deleteFastaIndex(guest.builder, genome.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.genome.updateGenome(guest.builder, genome.id!, genome),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('have more projects than the quota', () async {
        await configure(guestMaxProjects: 2);
        final guest = await acceptAsGuest();

        for (final name in ['one', 'two']) {
          await endpoints.project.createProject(
            guest.builder,
            name,
            await seedOptions(session),
          );
        }
        await expectLater(
          endpoints.project.createProject(
            guest.builder,
            'three',
            await seedOptions(session),
          ),
          throwsA(isA<ArgumentException>()),
        );
      });

      test('be offered mail notifications', () async {
        final settings = await Settings.db.findFirstRow(session);
        settings!.mailActive = true;
        await Settings.db.updateRow(session, settings);
        final guest = await acceptAsGuest();

        expect(
          await endpoints.project.notificationsAvailable(guest.builder),
          isFalse,
        );
      });
    });

    group('share links', () {
      test('opening a link puts the project in your own list', () async {
        final alice = await acceptAsGuest();
        final bob = await acceptAsGuest();
        final options = await seedOptions(session);
        final project = await seedProject(
          session,
          name: 'shared',
          options: options.id!,
          owner: alice.userId,
        );

        final token = await endpoints.project.getShareToken(
          alice.builder,
          project.id!,
        );
        expect(
          await endpoints.project.getShareToken(alice.builder, project.id!),
          token,
          reason: 'the same link every time it is copied',
        );

        final opened = await endpoints.project.redeemShareToken(
          bob.builder,
          token,
        );
        expect(opened.id, project.id);

        final bobs = await endpoints.project.getProjects(bob.builder);
        expect(bobs.map((p) => p.name), contains('shared'));
        await expectLater(
          endpoints.project.getProject(bob.builder, project.id!),
          completes,
        );
      });

      test('the token is long and unguessable', () async {
        final alice = await acceptAsGuest();
        final options = await seedOptions(session);
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        );
        final token = await endpoints.project.getShareToken(
          alice.builder,
          project.id!,
        );
        // 32 random bytes, base64url without padding.
        expect(token.length, AuthTokens.newToken().length);
        expect(token, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      });

      test('an unknown token is simply not found', () async {
        final bob = await acceptAsGuest();
        await expectLater(
          endpoints.project.redeemShareToken(bob.builder, 'no-such-token'),
          throwsA(isA<FlumipFileNotFoundException>()),
        );
      });

      test(
        'resetting withdraws the old link and everybody it let in',
        () async {
          final alice = await acceptAsGuest();
          final bob = await acceptAsGuest();
          final options = await seedOptions(session);
          final project = await seedProject(
            session,
            options: options.id!,
            owner: alice.userId,
          );
          final old = await endpoints.project.getShareToken(
            alice.builder,
            project.id!,
          );
          await endpoints.project.redeemShareToken(bob.builder, old);

          final fresh = await endpoints.project.resetShareToken(
            alice.builder,
            project.id!,
          );

          expect(fresh, isNot(old));
          await expectLater(
            endpoints.project.getProject(bob.builder, project.id!),
            throwsA(isA<ProjectAccessDeniedException>()),
          );
          await expectLater(
            endpoints.project.redeemShareToken(bob.builder, old),
            throwsA(isA<FlumipFileNotFoundException>()),
          );
        },
      );
    });

    group('expiry', () {
      test('a new project is stamped with its deletion date', () async {
        await configure(retentionHours: 24);
        final guest = await acceptAsGuest();
        final project = await endpoints.project.createProject(
          guest.builder,
          'dated',
          await seedOptions(session),
        );

        // The end of the day the window runs out in, not the minute.
        expect(
          project.expires,
          endOfDay(project.created.add(const Duration(hours: 24))),
        );
      });

      test('an internal install stamps nothing', () async {
        await configure(publicMode: false);
        final project = await endpoints.project.createProject(
          sessionBuilder,
          'kept',
          await seedOptions(session),
        );
        expect(project.expires, isNull);
      });

      test('"Keep longer" adds a whole window each time', () async {
        // It used to set "now plus the window" — on a fresh project, the date it
        // already had, so pressing it changed nothing.
        await configure(retentionHours: 24 * 7, maxLifetimeDays: 30);
        final guest = await acceptAsGuest();
        final project = await endpoints.project.createProject(
          guest.builder,
          'fresh',
          await seedOptions(session),
        );

        final once = await endpoints.project.extendProject(
          guest.builder,
          project.id!,
        );
        expect(
          once.expires,
          endOfDay(project.expires!.add(const Duration(days: 7))),
        );

        final twice = await endpoints.project.extendProject(
          guest.builder,
          project.id!,
        );
        expect(
          twice.expires,
          endOfDay(once.expires!.add(const Duration(days: 7))),
        );
      });

      test('"Keep longer" never goes past the maximum', () async {
        await configure(retentionHours: 24, maxLifetimeDays: 2);
        final guest = await acceptAsGuest();
        final options = await seedOptions(session);
        final created = DateTime.now().toUtc().subtract(
          const Duration(hours: 30),
        );
        final project = await Project.db.insertRow(
          session,
          Project(
            name: 'old',
            options: options.id!,
            owner: guest.userId,
            created: created,
            expires: endOfDay(created.add(const Duration(hours: 24))),
          ),
        );
        final cap = endOfDay(created.add(const Duration(days: 2)));

        final extended = await endpoints.project.extendProject(
          guest.builder,
          project.id!,
        );
        expect(extended.expires, cap);

        final again = await endpoints.project.extendProject(
          guest.builder,
          project.id!,
        );
        expect(again.expires, cap, reason: 'already at the cap');
      });

      test(
        'there is nothing to extend on an install that keeps projects',
        () async {
          await configure(publicMode: false);
          final options = await seedOptions(session);
          final project = await seedProject(session, options: options.id!);

          await expectLater(
            endpoints.project.extendProject(sessionBuilder, project.id!),
            throwsA(isA<ArgumentException>()),
          );
        },
      );
    });
  });

  withServerpod('Keeping a project indefinitely', (sessionBuilder, endpoints) {
    setup(authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final cleanup = DemoModeCleanupFutureCall();

    late TestSessionBuilder admin;
    late ({TestSessionBuilder builder, int userId}) guest;

    setUp(() async {
      await session.caches.localPrio.clear();
      final settings = await overrideSettingsDirs(
        session,
        projectDir: createTempDir('kept').path,
      );
      settings
        ..publicMode = true
        ..demoModeRetentionHours = 24;
      await Settings.db.updateRow(session, settings);
      await sl<AuthRuntime>().refresh(session);

      final boss = await seedSignedInUser(
        session,
        email: 'boss@uni.example',
        isAdmin: true,
      );
      admin = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'boss@uni.example',
          {adminScope},
          authId: '${boss.authSession.id}',
        ),
      );
      final accepted = await sl<AuthService>().acceptAsGuest(session);
      guest = (
        builder: sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            AuthService.guestEmail,
            const <Scope>{},
            authId: '${accepted.session.id}',
          ),
        ),
        userId: accepted.session.userId,
      );
    });

    /// A guest's project whose deletion is long overdue.
    Future<Project> overdueProject() async {
      final project = await endpoints.project.createProject(
        guest.builder,
        'cited-in-a-paper',
        await seedOptions(session),
      );
      project
        ..created = DateTime.now().toUtc().subtract(const Duration(days: 30))
        ..expires = DateTime.now().toUtc().subtract(const Duration(days: 20));
      return Project.db.updateRow(session, project);
    }

    test('an administrator may, and cleanup then leaves it alone', () async {
      final project = await overdueProject();

      final kept = await endpoints.project.setKeptIndefinitely(
        admin,
        project.id!,
        true,
      );
      expect(kept.keptIndefinitely, isTrue);

      await cleanup.run(session, kept);
      expect(await Project.db.findById(session, project.id!), isNotNull);
    });

    test('the owner may not — only an administrator lifts the limit', () async {
      final project = await overdueProject();
      await expectLater(
        endpoints.project.setKeptIndefinitely(guest.builder, project.id!, true),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
    });

    test(
      'clearing it starts a fresh window rather than deleting at once',
      () async {
        // The old deadline passed long ago; reusing it would delete the project
        // the moment the flag came off.
        final project = await overdueProject();
        await endpoints.project.setKeptIndefinitely(admin, project.id!, true);

        final released = await endpoints.project.setKeptIndefinitely(
          admin,
          project.id!,
          false,
        );

        expect(released.keptIndefinitely, isFalse);
        expect(
          released.expires,
          endOfDay(DateTime.now().toUtc().add(const Duration(hours: 24))),
        );
        await cleanup.run(session, released);
        expect(await Project.db.findById(session, project.id!), isNotNull);
      },
    );

    test('Keep longer leaves a kept project as it is', () async {
      final project = await overdueProject();
      final kept = await endpoints.project.setKeptIndefinitely(
        admin,
        project.id!,
        true,
      );
      final after = await endpoints.project.extendProject(
        guest.builder,
        project.id!,
      );
      expect(after.expires, kept.expires);
      expect(after.keptIndefinitely, isTrue);
    });
  });

  withServerpod('Switching public mode', (sessionBuilder, endpoints) {
    setup(authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    setUp(() async {
      await session.caches.localPrio.clear();
      await sl<AuthRuntime>().refresh(session);
    });

    test('is refused with only the settings password', () async {
      // Public mode refuses the password from the moment it is saved, so the
      // person saving it this way would be locked out of Settings.
      final settings =
          await Settings.db.findFirstRow(session) ??
          await Settings.db.insertRow(session, Settings());
      settings.publicMode = true;

      // The message, not just the type: a wrong password is an
      // ArgumentException too, and would pass this for the wrong reason.
      await expectLater(
        endpoints.settings.updateSettings(sessionBuilder, 'changeme', settings),
        throwsA(
          isA<ArgumentException>().having(
            (e) => e.message,
            'message',
            contains('Sign in as an administrator'),
          ),
        ),
      );
      expect(sl<AuthRuntime>().config.publicMode, isFalse);
    });

    test('is allowed for a signed-in administrator', () async {
      final admin = await seedSignedInUser(
        session,
        email: 'boss@uni.example',
        isAdmin: true,
      );
      final builder = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'boss@uni.example',
          {adminScope},
          authId: '${admin.authSession.id}',
        ),
      );
      final settings = await endpoints.settings.getSettings(builder, null);
      settings.publicMode = true;

      await endpoints.settings.updateSettings(builder, null, settings);

      expect(sl<AuthRuntime>().config.publicMode, isTrue);
      expect(sl<AuthRuntime>().isEnforcing, isTrue);
    });

    test('switching it off ends the guest sessions', () async {
      final admin = await seedSignedInUser(
        session,
        email: 'boss@uni.example',
        isAdmin: true,
      );
      final builder = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          'boss@uni.example',
          {adminScope},
          authId: '${admin.authSession.id}',
        ),
      );
      final settings = await endpoints.settings.getSettings(builder, null);
      settings.publicMode = true;
      await endpoints.settings.updateSettings(builder, null, settings);
      await sl<AuthService>().acceptAsGuest(session);

      settings.publicMode = false;
      await endpoints.settings.updateSettings(builder, null, settings);

      final guests = await AuthSession.db.find(
        session,
        where: (t) => t.isGuest.equals(true),
      );
      expect(guests, isEmpty);
    });
  });
}
