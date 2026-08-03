import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  const issuer = 'https://idp.example.org';

  // One shared fake for the whole file, reset per test: `withServerpod` group
  // bodies run at collection time, so anything built in a body is shared whether
  // or not that was intended.
  final http = FakeHttpJsonClient();

  Future<void> enforceSso(Session session) async {
    final settings = await Settings.db.findFirstRow(session) ?? Settings();
    settings
      ..loginRequired = true
      ..oidcIssuer = issuer
      ..oidcClientId = 'flumip'
      ..oidcClientSecret = 's3cret'
      ..authPublicUrl = 'https://flumip.example';
    if (settings.id == null) {
      await Settings.db.insertRow(session, settings);
    } else {
      await Settings.db.updateRow(session, settings);
    }
    http.stubProvider(issuer: issuer);
    await sl<AuthRuntime>().refresh(session);
    expect(
      sl<AuthRuntime>().isEnforcing,
      isTrue,
      reason: 'the test setup itself must actually close the gate',
    );
  }

  // ---------------------------------------------------------------------------
  // The default deployment. If anything here fails, an install that never turns
  // authentication on has lost access to its own projects — which matters more
  // than every other test in this file put together.
  // ---------------------------------------------------------------------------
  withServerpod('Projects without authentication (the default)', (
    sessionBuilder,
    endpoints,
  ) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    setUp(() async {
      http.reset();
      await sl<AuthRuntime>().refresh(session);
      expect(sl<AuthRuntime>().isEnforcing, isFalse);
    });

    test('every project is listed, owned or not', () async {
      final options = await seedOptions(session);
      await seedProject(session, name: 'unowned', options: options.id!);
      final user = await seedSignedInUser(
        session,
        email: 'someone@uni.example',
      );
      await seedProject(
        session,
        name: 'owned',
        options: options.id!,
        owner: user.user.id,
      );

      final visible = await endpoints.project.getProjects(sessionBuilder);
      expect(visible.map((p) => p.name), containsAll(['unowned', 'owned']));
    });

    test(
      'a project owned by somebody else is still readable and writable',
      () async {
        // Nobody is signed in, so "somebody else's project" is everybody's. This is
        // the behaviour that existed before authorization and must survive it.
        final options = await seedOptions(session);
        final user = await seedSignedInUser(
          session,
          email: 'other@uni.example',
        );
        final project = await seedProject(
          session,
          name: 'theirs',
          options: options.id!,
          owner: user.user.id,
        );

        await expectLater(
          endpoints.project.getProject(sessionBuilder, project.id!),
          completes,
        );
        await expectLater(
          endpoints.project.addGeneToProject(
            sessionBuilder,
            project.id!,
            'BRCA1',
          ),
          completes,
        );
      },
    );

    test('a new project is left unowned', () async {
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        options: options.id!,
        owner: null,
      );
      final reloaded = await Project.db.findById(session, project.id!);
      expect(reloaded!.owner, isNull);
    });

    test('the project options of any project are reachable', () async {
      final options = await seedOptions(session);
      final user = await seedSignedInUser(session, email: 'other@uni.example');
      await seedProject(session, options: options.id!, owner: user.user.id);

      await expectLater(
        endpoints.options.getProjectOptions(sessionBuilder, options.id!),
        completes,
      );
    });

    test('reassigning ownership is refused, not allowed', () async {
      // The one place that fails *closed* while single sign-on is off, against
      // the grain of every other rule here. There is no administrator to be, so
      // there is nothing to fail open to — and failing open would hand an
      // unauthenticated caller a way to strip the owners that an install
      // collected while single sign-on was on. Invisible at the time, because
      // access is unrestricted anyway, and destructive the moment it came back.
      final options = await seedOptions(session);
      final user = await seedSignedInUser(session, email: 'other@uni.example');
      final project = await seedProject(
        session,
        options: options.id!,
        owner: user.user.id,
      );

      await expectLater(
        endpoints.project.setProjectOwner(sessionBuilder, project.id!, null),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
      await expectLater(
        endpoints.project.assignableOwners(sessionBuilder),
        throwsA(isA<ProjectAccessDeniedException>()),
      );

      final reloaded = await Project.db.findById(session, project.id!);
      expect(reloaded!.owner, user.user.id, reason: 'the owner survived');
    });
  });

  // ---------------------------------------------------------------------------
  // Enforcing.
  // ---------------------------------------------------------------------------
  withServerpod('Projects with authorization enforced', (
    sessionBuilder,
    endpoints,
  ) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    setUp(() async {
      http.reset();
      // The database is rolled back after each test but the local cache is not,
      // and row ids restart — so without this a cached AuthSession from an
      // earlier test can be handed back for a *different* row with the same id.
      await session.caches.localPrio.clear();
    });

    /// A session builder authenticated as a freshly seeded user.
    Future<({TestSessionBuilder builder, int userId})> signIn(
      String email, {
      bool isAdmin = false,
    }) async {
      final seeded = await seedSignedInUser(
        session,
        email: email,
        isAdmin: isAdmin,
      );
      return (
        builder: sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            email,
            isAdmin ? {adminScope} : const <Scope>{},
            // The real thing: AuthorizationService parses this as an AuthSession
            // id to find the user. A generated UUID here would silently yield a
            // principal that owns nothing.
            authId: '${seeded.authSession.id}',
          ),
        ),
        userId: seeded.user.id!,
      );
    }

    group('listing', () {
      test('a user sees their own projects and unowned ones, not other '
          "people's", () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');

        await seedProject(
          session,
          name: 'alice-project',
          options: options.id!,
          owner: alice.userId,
        );
        await seedProject(
          session,
          name: 'bob-project',
          options: options.id!,
          owner: bob.userId,
        );
        await seedProject(session, name: 'legacy', options: options.id!);

        final visible = await endpoints.project.getProjects(alice.builder);
        expect(
          visible.map((p) => p.name),
          containsAll(['alice-project', 'legacy']),
        );
        expect(visible.map((p) => p.name), isNot(contains('bob-project')));
      });

      test('an admin sees everything', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final bob = await signIn('bob@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);

        await seedProject(
          session,
          name: 'bob-project',
          options: options.id!,
          owner: bob.userId,
        );
        await seedProject(session, name: 'legacy', options: options.id!);

        final visible = await endpoints.project.getProjects(boss.builder);
        expect(
          visible.map((p) => p.name),
          containsAll(['bob-project', 'legacy']),
        );
      });
    });

    group('opening a project', () {
      test('the owner may', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        );

        final loaded = await endpoints.project.getProject(
          alice.builder,
          project.id!,
        );
        expect(loaded.id, project.id);
      });

      test('somebody else may not', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        );

        await expectLater(
          endpoints.project.getProject(bob.builder, project.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('an admin may', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        );

        await expectLater(
          endpoints.project.getProject(boss.builder, project.id!),
          completes,
        );
      });

      test('an unowned project is open to anyone signed in', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final bob = await signIn('bob@uni.example');
        final project = await seedProject(session, options: options.id!);

        await expectLater(
          endpoints.project.getProject(bob.builder, project.id!),
          completes,
        );
        await expectLater(
          endpoints.project.addGeneToProject(bob.builder, project.id!, 'TP53'),
          completes,
        );
      });
    });

    group('every project-scoped call refuses a stranger', () {
      // The point of enumerating these rather than trusting the shared helper:
      // the guard is one line per endpoint method, and a method added later
      // without it is exactly the failure this file has to catch.
      test('on ProjectEndpoint', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;
        final b = bob.builder;

        await expectLater(
          endpoints.project.getProject(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.deleteProject(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.addGeneToProject(b, id, 'BRCA1'),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.removeGeneFromProject(b, id, 'BRCA1'),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.addGenesToProject(b, id, ['BRCA1']),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.setGeneById(b, id, 1),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.setSnpById(b, id, 1),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.project.setEmailNotification(b, id, true),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        // Guarded by requireAdmin rather than requireProject, but it takes a
        // project id, so it belongs in this enumeration all the same.
        await expectLater(
          endpoints.project.setProjectOwner(b, id, null),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('on FileEndpoint', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;
        final b = bob.builder;

        await expectLater(
          endpoints.file.deleteByProducts(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.file.showSnpMipsResult(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.file.showMipsResult(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.file.showMipsProgress(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.file.showUSCSTrack(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.file.getUcscTrackToken(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('on MipgenEndpoint', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;
        final b = bob.builder;

        await expectLater(
          endpoints.mipgen.createBedFile(b, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.mipgen.generateMips(b, id, false),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('on OptionsEndpoint, via the project that owns the options', () async {
        // ProjectOptions rows are addressed by their own id, so guarding only
        // Project would leave a project's whole mipgen configuration readable and
        // writable by anyone willing to count upwards.
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        await seedProject(session, options: options.id!, owner: alice.userId);
        final b = bob.builder;

        await expectLater(
          endpoints.options.getProjectOptions(b, options.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.options.updateProjectOptions(b, options.id!, options),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.options.deleteProjectOptions(b, options.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('but options no project points at yet stay usable', () async {
        // The create-project flow inserts the options row before the project that
        // will reference it, so refusing an unreferenced row would make creating
        // a project impossible.
        await enforceSso(session);
        final orphan = await seedOptions(session);
        final bob = await signIn('bob@uni.example');

        await expectLater(
          endpoints.options.getProjectOptions(bob.builder, orphan.id!),
          completes,
        );
      });
    });

    group('reassigning ownership', () {
      test('an admin can hand a project to somebody else', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;

        await endpoints.project.setProjectOwner(boss.builder, id, bob.userId);

        // The point of reassignment: it moves who can reach it, both ways.
        await expectLater(
          endpoints.project.getProject(bob.builder, id),
          completes,
        );
        await expectLater(
          endpoints.project.getProject(alice.builder, id),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('a null owner releases the project to everyone', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;

        await endpoints.project.setProjectOwner(boss.builder, id, null);

        // Unowned means shared, not orphaned — the state every project that
        // predates authorization is already in.
        await expectLater(
          endpoints.project.getProject(bob.builder, id),
          completes,
        );
        await expectLater(
          endpoints.project.getProject(alice.builder, id),
          completes,
        );
      });

      test('the owner themselves may not give their project away', () async {
        // Being allowed to use something is not being allowed to hand it over.
        // alice passes requireProject for her own project, so this would slip
        // through if the guard were requireProject rather than requireAdmin.
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;

        await expectLater(
          endpoints.project.setProjectOwner(alice.builder, id, bob.userId),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });

      test('an unknown user is refused, and the owner is unchanged', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);
        final id = (await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
        )).id!;

        await expectLater(
          endpoints.project.setProjectOwner(boss.builder, id, 999999),
          throwsA(isA<FlumipFileNotFoundException>()),
        );

        final reloaded = await Project.db.findById(session, id);
        expect(reloaded!.owner, alice.userId);
      });

      test('only an admin may list the users', () async {
        await enforceSso(session);
        final alice = await signIn('alice@uni.example');
        final boss = await signIn('boss@uni.example', isAdmin: true);

        await expectLater(
          endpoints.project.assignableOwners(alice.builder),
          throwsA(isA<ProjectAccessDeniedException>()),
        );

        final owners = await endpoints.project.assignableOwners(boss.builder);
        expect(
          owners.map((u) => u.email),
          containsAll(['alice@uni.example', 'boss@uni.example']),
        );
        // The id is the whole reason this DTO exists — it is what gets sent back.
        expect(owners.every((u) => u.id > 0), isTrue);
      });
    });

    group('what the guard must not change', () {
      test('a missing project still reports not-found, not access denied', () async {
        // The guard sits in front of the operation and must not rewrite the error
        // that operation reports for an unrelated failure. FileEndpoint answers a
        // bad id with Serverpod's FileNotFoundException and the app catches the
        // two separately.
        await enforceSso(session);
        final bob = await signIn('bob@uni.example');

        await expectLater(
          endpoints.file.showMipsProgress(bob.builder, -1),
          throwsA(isA<FileNotFoundException>()),
        );
        await expectLater(
          endpoints.project.getProject(bob.builder, -1),
          throwsA(isA<FlumipFileNotFoundException>()),
        );
      });

      test('the settings endpoint is unaffected by project authorization',
          () async {
        // Its gate is its own — an admin session, not project access — so an
        // admin who owns no projects at all still reaches the configuration.
        // The settings password is refused here because sign-in is enforced;
        // that is the settings rule, and nothing to do with this file.
        await enforceSso(session);
        final boss = await signIn('boss@uni.example', isAdmin: true);
        final settings =
            await endpoints.settings.getSettings(boss.builder, null);
        expect(settings.loginRequired, isTrue);
      });
    });

    group('revocation', () {
      test(
        'signing out costs the user their access on the very next call',
        () async {
          // The regression test for the principal cache. A read-through cache that
          // outlives revocation is the one way this optimisation turns into a
          // security bug, so it shares AuthService's invalidation group.
          await enforceSso(session);
          final options = await seedOptions(session);
          final seeded = await seedSignedInUser(
            session,
            email: 'alice@uni.example',
          );
          final alice = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'alice@uni.example',
              const <Scope>{},
              authId: '${seeded.authSession.id}',
            ),
          );
          final project = await seedProject(
            session,
            options: options.id!,
            owner: seeded.user.id,
          );

          // Warm the cache with a successful call first, or the test proves nothing.
          await expectLater(
            endpoints.project.getProject(alice, project.id!),
            completes,
          );

          await sl<AuthService>().revokeSession(
            session,
            seeded.authSession.id!,
          );

          await expectLater(
            endpoints.project.getProject(alice, project.id!),
            throwsA(isA<ProjectAccessDeniedException>()),
          );
        },
      );
    });

    group('the UCSC track token', () {
      // The public route is keyed on this, so these properties are what stands in
      // for authentication there.
      test('is minted once and then reused', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
          trackToken: null,
        );

        final first = await endpoints.file.getUcscTrackToken(
          alice.builder,
          project.id!,
        );
        final second = await endpoints.file.getUcscTrackToken(
          alice.builder,
          project.id!,
        );

        expect(first, isNotEmpty);
        expect(
          second,
          first,
          reason:
              'a new token per request would break '
              'every URL the user already pasted into UCSC',
        );
      });

      test('is not the project id, and differs between projects', () async {
        // The whole point: two adjacent projects must not have guessable,
        // adjacent track URLs.
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final one = await seedProject(
          session,
          name: 'one',
          options: options.id!,
          owner: alice.userId,
        );
        final two = await seedProject(
          session,
          name: 'two',
          options: options.id!,
          owner: alice.userId,
        );

        final tokenOne = await endpoints.file.getUcscTrackToken(
          alice.builder,
          one.id!,
        );
        final tokenTwo = await endpoints.file.getUcscTrackToken(
          alice.builder,
          two.id!,
        );

        expect(tokenOne, isNot(tokenTwo));
        expect(tokenOne, isNot('${one.id}'));
        expect(
          tokenOne.length,
          greaterThan(30),
          reason: 'a UUID, not a counter',
        );
      });

      test(
        'is stored so the public route can find the project by it',
        () async {
          await enforceSso(session);
          final options = await seedOptions(session);
          final alice = await signIn('alice@uni.example');
          final project = await seedProject(
            session,
            options: options.id!,
            owner: alice.userId,
          );

          final token = await endpoints.file.getUcscTrackToken(
            alice.builder,
            project.id!,
          );

          // Exactly the lookup UCSCTrackRoute performs.
          final found = await Project.db.findFirstRow(
            session,
            where: (t) => t.trackToken.equals(token),
          );
          expect(found?.id, project.id);
        },
      );

      test('is never handed to the browser as part of the project', () async {
        // trackToken is serverOnly. If it ever reached the client through Project
        // itself, an unauthorized list response would leak every capability URL.
        await enforceSso(session);
        final options = await seedOptions(session);
        final alice = await signIn('alice@uni.example');
        final project = await seedProject(
          session,
          options: options.id!,
          owner: alice.userId,
          trackToken: 'secret-token',
        );

        expect(project.toJsonForProtocol(), isNot(contains('trackToken')));
      });
    });

    group('an authId that is not an AuthSession id', () {
      test('keeps an admin admin', () async {
        // Serverpod's own AuthenticationOverride defaults authId to a UUID, and a
        // future auth source might too. Losing the admin flag there would demote
        // an administrator silently.
        await enforceSso(session);
        final options = await seedOptions(session);
        final owner = await seedSignedInUser(
          session,
          email: 'alice@uni.example',
        );
        final project = await seedProject(
          session,
          options: options.id!,
          owner: owner.user.id,
        );

        final uuidAdmin = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'boss@uni.example',
            {adminScope},
          ),
        );

        await expectLater(
          endpoints.project.getProject(uuidAdmin, project.id!),
          completes,
        );
      });

      test('gives a non-admin no ownership', () async {
        await enforceSso(session);
        final options = await seedOptions(session);
        final owner = await seedSignedInUser(
          session,
          email: 'alice@uni.example',
        );
        final project = await seedProject(
          session,
          options: options.id!,
          owner: owner.user.id,
        );

        final uuidUser = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            'alice@uni.example',
            const <Scope>{},
          ),
        );

        await expectLater(
          endpoints.project.getProject(uuidUser, project.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      });
    });
  });
}
