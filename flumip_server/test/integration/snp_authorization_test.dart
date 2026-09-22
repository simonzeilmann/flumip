import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Who may see, change and delete an SNP.
///
/// ⚠️ Every signed-in caller here is built from a **real `AuthSession` row** via
/// [seedSignedInUser], not from an [AuthenticationOverride] alone. That is
/// load-bearing: `AuthorizationService` resolves the user id by parsing `authId`
/// as an AuthSession id and reading it, so an override on its own yields a null
/// `userId` — which owns nothing, matches nothing, and would make every ownership
/// assertion below pass without testing anything.
void main() {
  const issuer = 'https://idp.example.org';
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

  withServerpod('Custom SNP authorization', (sessionBuilder, endpoints) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    setUp(() => http.reset());

    /// A session builder for a caller backed by a real AuthSession row.
    Future<({TestSessionBuilder builder, FlumipUser user})> signIn(
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
            authId: '${seeded.authSession.id}',
          ),
        ),
        user: seeded.user,
      );
    }

    group('seeing a private SNP', () {
      test('the owner sees it, another user does not, an admin does', () async {
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final root = await signIn('root@uni.example', isAdmin: true);
        await seedSnp(
          session,
          name: 'alice panel',
          genome: genome.id,
          owner: alice.user.id,
          custom: true,
          private: true,
        );

        expect(
          (await endpoints.snp.listSnpsForGenome(
            alice.builder,
            genome.id!,
          )).map((s) => s.name),
          ['alice panel'],
        );
        expect(
          await endpoints.snp.listSnpsForGenome(bob.builder, genome.id!),
          isEmpty,
        );
        expect(
          (await endpoints.snp.listSnpsForGenome(
            root.builder,
            genome.id!,
          )).map((s) => s.name),
          ['alice panel'],
        );
      }, tags: ['integration']);

      test('sharing makes it visible to everybody', () async {
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final snp = await seedSnp(
          session,
          name: 'alice panel',
          genome: genome.id,
          owner: alice.user.id,
          custom: true,
          private: true,
        );

        await endpoints.snp.setShared(alice.builder, snp.id!, true);

        expect(
          (await endpoints.snp.listSnpsForGenome(
            bob.builder,
            genome.id!,
          )).map((s) => s.name),
          ['alice panel'],
        );
      }, tags: ['integration']);

      test('a global SNP is visible to everyone', () async {
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final bob = await signIn('bob@uni.example');
        await seedSnp(session, name: 'dbsnp', genome: genome.id);

        expect(
          (await endpoints.snp.listSnpsForGenome(
            bob.builder,
            genome.id!,
          )).map((s) => s.name),
          ['dbsnp'],
        );
      }, tags: ['integration']);

      test('somebody else\'s half-finished import stays hidden', () async {
        // A shared SNP that is still importing is nobody's business but its
        // owner's until it works.
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        await seedSnp(
          session,
          name: 'downloading',
          genome: genome.id,
          owner: alice.user.id,
          custom: true,
          private: false,
          status: SnpImportStatus.downloading,
        );

        expect(
          await endpoints.snp.listSnpsForGenome(bob.builder, genome.id!),
          isEmpty,
        );
        expect(
          await endpoints.snp.listSnpsForGenome(alice.builder, genome.id!),
          hasLength(1),
        );
      }, tags: ['integration']);
    });

    group('listMySnps', () {
      test('shows only your own, in any state', () async {
        await enforceSso(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        await seedSnp(
          session,
          name: 'mine-failed',
          owner: alice.user.id,
          custom: true,
          status: SnpImportStatus.failed,
        );
        await seedSnp(session, name: 'bobs', owner: bob.user.id, custom: true);
        await seedSnp(session, name: 'global');

        expect(
          (await endpoints.snp.listMySnps(alice.builder)).map((s) => s.name),
          ['mine-failed'],
        );
      }, tags: ['integration']);

      test('an admin sees every custom SNP, but no globals', () async {
        await enforceSso(session);
        final alice = await signIn('alice@uni.example');
        final root = await signIn('root@uni.example', isAdmin: true);
        await seedSnp(
          session,
          name: 'alices',
          owner: alice.user.id,
          custom: true,
        );
        await seedSnp(session, name: 'dbsnp');

        expect(
          (await endpoints.snp.listMySnps(root.builder)).map((s) => s.name),
          ['alices'],
        );
      }, tags: ['integration']);
    });

    group('changing and deleting', () {
      test('another user cannot rename or unshare a shared SNP', () async {
        // Ownership survives sharing: visible to everybody, writable by one.
        await enforceSso(session);
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final snp = await seedSnp(
          session,
          name: 'shared panel',
          owner: alice.user.id,
          custom: true,
          private: false,
        );

        await expectLater(
          endpoints.snp.renameSnp(bob.builder, snp.id!, 'hijacked', ''),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        await expectLater(
          endpoints.snp.setShared(bob.builder, snp.id!, false),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      }, tags: ['integration']);

      test(
        'another user cannot delete it, the owner and an admin can',
        () async {
          await enforceSso(session);
          final alice = await signIn('alice@uni.example');
          final bob = await signIn('bob@uni.example');
          final root = await signIn('root@uni.example', isAdmin: true);

          final theirs = await seedSnp(
            session,
            name: 'a',
            owner: alice.user.id,
            custom: true,
            folder: '',
          );
          await expectLater(
            endpoints.snp.deleteCustomSnp(bob.builder, theirs.id!),
            throwsA(isA<ProjectAccessDeniedException>()),
          );

          await endpoints.snp.deleteCustomSnp(alice.builder, theirs.id!);
          expect(await Snp.db.findById(session, theirs.id!), isNull);

          final another = await seedSnp(
            session,
            name: 'b',
            owner: alice.user.id,
            custom: true,
            folder: '',
          );
          await endpoints.snp.deleteCustomSnp(root.builder, another.id!);
          expect(await Snp.db.findById(session, another.id!), isNull);
        },
        tags: ['integration'],
      );

      test('nobody can reach a global SNP through the ordinary delete', () async {
        // The separation that keeps a user's delete button away from the shared
        // genome tree. Even an admin has to use the other endpoint, which is
        // what makes the type-the-name confirmation unavoidable.
        await enforceSso(session);
        final root = await signIn('root@uni.example', isAdmin: true);
        final global = await seedSnp(session, name: 'dbsnp');

        await expectLater(
          endpoints.snp.deleteCustomSnp(root.builder, global.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
        expect(await Snp.db.findById(session, global.id!), isNotNull);
      }, tags: ['integration']);
    });

    group('deleteSnpAsAdmin', () {
      test('a signed-in non-admin is refused, password or not', () async {
        await enforceSso(session);
        final bob = await signIn('bob@uni.example');
        final global = await seedSnp(session, name: 'dbsnp', folder: '');

        await expectLater(
          endpoints.snp.deleteSnpAsAdmin(
            bob.builder,
            global.id!,
            null,
            force: false,
          ),
          throwsA(isA<ArgumentException>()),
        );
        // ⚠️ The settings password stops being accepted once sign-in is
        // enforced, so knowing it is not a way around the admin list.
        await expectLater(
          endpoints.snp.deleteSnpAsAdmin(
            bob.builder,
            global.id!,
            'changeme',
            force: false,
          ),
          throwsA(isA<ArgumentException>()),
        );
        expect(await Snp.db.findById(session, global.id!), isNotNull);
      }, tags: ['integration']);

      test('an admin session needs no password', () async {
        await enforceSso(session);
        final root = await signIn('root@uni.example', isAdmin: true);
        final global = await seedSnp(session, name: 'dbsnp', folder: '');

        await endpoints.snp.deleteSnpAsAdmin(
          root.builder,
          global.id!,
          null,
          force: false,
        );

        expect(await Snp.db.findById(session, global.id!), isNull);
      }, tags: ['integration']);

      test(
        'it refuses while projects still use the SNP, and names them',
        () async {
          await enforceSso(session);
          final root = await signIn('root@uni.example', isAdmin: true);
          final snp = await seedSnp(session, name: 'dbsnp', folder: '');
          final options = await seedOptions(session);
          await seedProject(
            session,
            name: 'Cardio panel',
            options: options.id!,
            snp: snp.id,
          );

          await expectLater(
            endpoints.snp.deleteSnpAsAdmin(
              root.builder,
              snp.id!,
              null,
              force: false,
            ),
            throwsA(
              isA<ArgumentException>().having(
                (e) => e.message,
                'message',
                contains('Cardio panel'),
              ),
            ),
          );
          expect(await Snp.db.findById(session, snp.id!), isNotNull);
        },
        tags: ['integration'],
      );

      test('force deletes it anyway and releases the projects', () async {
        await enforceSso(session);
        final root = await signIn('root@uni.example', isAdmin: true);
        final snp = await seedSnp(session, name: 'dbsnp', folder: '');
        final options = await seedOptions(session);
        final project = await seedProject(
          session,
          name: 'Cardio panel',
          options: options.id!,
          snp: snp.id,
        );

        await endpoints.snp.deleteSnpAsAdmin(
          root.builder,
          snp.id!,
          null,
          force: true,
        );

        expect(await Snp.db.findById(session, snp.id!), isNull);
        expect((await Project.db.findById(session, project.id!))!.snp, isNull);
      }, tags: ['integration']);
    });
  });

  // ---------------------------------------------------------------------------
  // The default deployment. Nothing here may be locked out of its own data.
  // ---------------------------------------------------------------------------
  withServerpod('Custom SNPs without authentication', (
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

    test('every SNP is listed, private or not', () async {
      final genome = await seedGenome(session, name: 'hg38');
      await seedSnp(
        session,
        name: 'private one',
        genome: genome.id,
        custom: true,
        private: true,
      );
      await seedSnp(session, name: 'global', genome: genome.id);

      expect(
        (await endpoints.snp.listSnpsForGenome(
          sessionBuilder,
          genome.id!,
        )).map((s) => s.name),
        containsAll(['private one', 'global']),
      );
    }, tags: ['integration']);

    test('a custom SNP can be deleted without an identity', () async {
      final snp = await seedSnp(
        session,
        name: 'mine',
        custom: true,
        folder: '',
      );
      await endpoints.snp.deleteCustomSnp(sessionBuilder, snp.id!);
      expect(await Snp.db.findById(session, snp.id!), isNull);
    }, tags: ['integration']);

    test('the settings password is the admin credential for a global', () async {
      // ⚠️ Why this uses SettingsService.requireAdmin and not
      // authz.requireAdmin: the latter deliberately throws while sign-in is off,
      // which would leave a no-auth install with no way to remove a broken global
      // SNP at all.
      final global = await seedSnp(session, name: 'dbsnp', folder: '');

      await expectLater(
        endpoints.snp.deleteSnpAsAdmin(
          sessionBuilder,
          global.id!,
          'wrong',
          force: false,
        ),
        throwsA(isA<ArgumentException>()),
      );
      expect(await Snp.db.findById(session, global.id!), isNotNull);

      await endpoints.snp.deleteSnpAsAdmin(
        sessionBuilder,
        global.id!,
        'changeme',
        force: false,
      );
      expect(await Snp.db.findById(session, global.id!), isNull);
    }, tags: ['integration']);
  });
}
