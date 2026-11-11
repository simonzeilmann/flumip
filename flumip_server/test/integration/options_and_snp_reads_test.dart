import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Who may read and write project options, and what of them a client may set;
/// and who may read an SNP row through `GenomeEndpoint`.
///
/// Every signed-in caller is built from a real `AuthSession` row, for the
/// reason `snp_authorization_test.dart` spells out: an override alone has no
/// user id, owns nothing, and would make every assertion here vacuous.
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
    expect(sl<AuthRuntime>().isEnforcing, isTrue);
  }

  withServerpod('Project options with authorization enforced', (
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
      await session.caches.localPrio.clear();
    });

    Future<({TestSessionBuilder builder, int userId})> signIn(
      String email,
    ) async {
      final seeded = await seedSignedInUser(session, email: email);
      return (
        builder: sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            email,
            const <Scope>{},
            authId: '${seeded.authSession.id}',
          ),
        ),
        userId: seeded.user.id!,
      );
    }

    /// Alice's project and its options, and Mallory signed in.
    Future<
      ({ProjectOptions victim, ProjectOptions own, TestSessionBuilder mallory})
    >
    twoProjects() async {
      await enforceSso(session);
      final alice = await signIn('alice@uni.example');
      final mallory = await signIn('mallory@uni.example');
      final victim = await seedOptions(session);
      await seedProject(
        session,
        name: 'alice',
        options: victim.id!,
        owner: alice.userId,
      );
      final own = await seedOptions(session);
      await seedProject(
        session,
        name: 'mallory',
        options: own.id!,
        owner: mallory.userId,
      );
      return (victim: victim, own: own, mallory: mallory.builder);
    }

    test(
      'an update writes the row it names, not the one in the body',
      () async {
        // The IDOR: the gate checked `id`, and `updateRow` wrote `options.id`.
        final t = await twoProjects();

        await endpoints.options.updateProjectOptions(
          t.mallory,
          t.own.id!,
          t.victim.copyWith(minCaptureSize: 99, silentMode: true),
        );

        final victim = await ProjectOptions.db.findById(session, t.victim.id!);
        expect(victim!.minCaptureSize, 162, reason: "Alice's row was written");
        expect(victim.silentMode, isFalse);
        final own = await ProjectOptions.db.findById(session, t.own.id!);
        expect(own!.minCaptureSize, 99, reason: 'the named row was not');
      },
    );

    test("somebody else's options cannot be named at all", () async {
      final t = await twoProjects();
      await expectLater(
        endpoints.options.updateProjectOptions(
          t.mallory,
          t.victim.id!,
          t.victim.copyWith(minCaptureSize: 99),
        ),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
      await expectLater(
        endpoints.options.getProjectOptions(t.mallory, t.victim.id!),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
      await expectLater(
        endpoints.options.deleteProjectOptions(t.mallory, t.victim.id!),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
    });

    test('an insert carrying an existing id makes a new row', () async {
      final t = await twoProjects();
      final inserted = await endpoints.options.insertProjectOptions(
        t.mallory,
        t.victim.copyWith(minCaptureSize: 99),
      );
      expect(inserted.id, isNot(t.victim.id));
      final victim = await ProjectOptions.db.findById(session, t.victim.id!);
      expect(victim!.minCaptureSize, 162);
    });

    test("a project cannot be created on somebody else's options", () async {
      // Otherwise the new project counts as "the project owning those
      // options", and deleting it deletes Alice's options with it.
      final t = await twoProjects();
      await expectLater(
        endpoints.project.createProject(t.mallory, 'hijack', t.victim),
        throwsA(isA<ArgumentException>()),
      );
      expect(
        await Project.db.count(
          session,
          where: (p) => p.options.equals(t.victim.id!),
        ),
        1,
      );
    });

    test('options a project uses are not deleted on their own', () async {
      final t = await twoProjects();
      await expectLater(
        endpoints.options.deleteProjectOptions(t.mallory, t.own.id!),
        throwsA(isA<ArgumentException>()),
      );
      expect(await ProjectOptions.db.findById(session, t.own.id!), isNotNull);
    });

    test('a genome directory from the client is never stored', () async {
      final t = await twoProjects();
      final inserted = await endpoints.options.insertProjectOptions(
        t.mallory,
        ProjectOptions(genomeDir: '/etc'),
      );
      expect(inserted.genomeDir, isNull);

      await endpoints.options.updateProjectOptions(
        t.mallory,
        t.own.id!,
        t.own.copyWith(genomeDir: '-file_of_parameters'),
      );
      final own = await ProjectOptions.db.findById(session, t.own.id!);
      expect(own!.genomeDir, isNull);
    });

    for (final (what, options) in [
      ('a negative number', ProjectOptions(featureFlank: -1)),
      ('an option name as arm lengths', ProjectOptions(armLengths: '-bwa')),
      ('a command as tag sizes', ProjectOptions(tagSizes: r'5,0;$(id)')),
      ('a negative score', ProjectOptions(svrOptimalScore: -1.5)),
    ]) {
      test('$what is refused when saving', () async {
        final t = await twoProjects();
        await expectLater(
          endpoints.options.insertProjectOptions(t.mallory, options),
          throwsA(isA<ArgumentException>()),
        );
        await expectLater(
          endpoints.options.updateProjectOptions(t.mallory, t.own.id!, options),
          throwsA(isA<ArgumentException>()),
        );
      });
    }
  });

  withServerpod('Reading SNP rows through the genome endpoint', (
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
      await session.caches.localPrio.clear();
    });

    Future<({TestSessionBuilder builder, int userId})> signIn(
      String email,
    ) async {
      final seeded = await seedSignedInUser(session, email: email);
      return (
        builder: sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            email,
            const <Scope>{},
            authId: '${seeded.authSession.id}',
          ),
        ),
        userId: seeded.user.id!,
      );
    }

    test("somebody else's private set is not readable", () async {
      await enforceSso(session);
      final alice = await signIn('alice@uni.example');
      final mallory = await signIn('mallory@uni.example');
      final genome = await seedGenome(session);
      final secret = await seedSnp(
        session,
        name: 'secret',
        genome: genome.id,
        private: true,
        owner: alice.userId,
        custom: true,
      );
      final shared = await seedSnp(session, name: 'shared', genome: genome.id);

      await expectLater(
        endpoints.genome.getSnp(mallory.builder, secret.id!),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
      final listed = await endpoints.genome.getAllSnpForGenome(
        mallory.builder,
        genome.id!,
      );
      expect(listed.map((s) => s.name), ['shared']);

      // And the owner still sees both, in full.
      final own = await endpoints.genome.getSnp(alice.builder, secret.id!);
      expect(own.vcfPath, secret.vcfPath);
      expect(
        (await endpoints.genome.getAllSnpForGenome(
          alice.builder,
          genome.id!,
        )).map((s) => s.id),
        containsAll([secret.id, shared.id]),
      );
    });

    test('a private set on a project the caller can open is named, but '
        'not located', () async {
      await enforceSso(session);
      final alice = await signIn('alice@uni.example');
      final bob = await signIn('bob@uni.example');
      final genome = await seedGenome(session);
      final secret = await seedSnp(
        session,
        name: 'secret',
        genome: genome.id,
        private: true,
        owner: alice.userId,
        custom: true,
        sourceVcfUrl: 'https://internal.example/x.vcf.gz',
      );
      final options = await seedOptions(session);
      // Unowned, so Bob can open it — the same position a share link or a
      // department puts him in.
      await seedProject(session, options: options.id!, snp: secret.id);

      final seen = await endpoints.genome.getSnp(bob.builder, secret.id!);
      expect(seen.name, 'secret');
      expect(seen.vcfPath, isEmpty);
      expect(seen.tbiPath, isEmpty);
      expect(seen.folder, isEmpty);
      expect(seen.sourceVcfUrl, isNull);
    });
  });
}
