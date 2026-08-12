import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/search_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// What search finds, and — more importantly — what it does not.
///
/// ⚠️ Every signed-in caller here is built from a **real `AuthSession` row** via
/// [seedSignedInUser], for the reason `snp_authorization_test.dart` spells out: an
/// [AuthenticationOverride] alone yields a principal with a null `userId`, which
/// owns nothing and would make every ownership assertion below pass vacuously.
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

  withServerpod('Search without authentication', (sessionBuilder, endpoints) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    /// Names only, which is what every assertion here is about.
    Future<List<String>> namesOf(String query, {SearchHitKind? kind}) async {
      final hits = await endpoints.search.search(sessionBuilder, query);
      return hits
          .where((h) => kind == null || h.kind == kind)
          .map((h) => h.name)
          .toList();
    }

    test('it finds all three kinds in one call', () async {
      final options = await seedOptions(session);
      final genome = await seedGenome(session, name: 'brca-build');
      await seedProject(session, name: 'BRCA panel', options: options.id!);
      await seedSnp(session, name: 'ClinVar brca', genome: genome.id);

      final hits = await endpoints.search.search(sessionBuilder, 'brca');

      expect(
        hits.map((h) => h.kind),
        containsAll([
          SearchHitKind.project,
          SearchHitKind.genome,
          SearchHitKind.snpSet,
        ]),
      );
      // Grouped in a fixed order, because the client renders them in that order.
      expect(hits.first.kind, SearchHitKind.project);
      expect(hits.last.kind, SearchHitKind.snpSet);
    });

    test('matching ignores case', () async {
      final options = await seedOptions(session);
      await seedProject(session, name: 'Exon Tiling', options: options.id!);

      expect(await namesOf('exon tiling'), contains('Exon Tiling'));
      expect(await namesOf('EXON'), contains('Exon Tiling'));
    });

    test('a description matches as well as a name', () async {
      final options = await seedOptions(session);
      await seedProject(
        session,
        name: 'panel 7',
        description: 'cardiomyopathy follow-up',
        options: options.id!,
      );
      await seedGenome(
        session,
        name: 'hs1',
        description: 'telomere-to-telomere assembly',
      );
      await seedSnp(
        session,
        name: 'set 3',
        description: 'gnomAD frequencies',
        genome: (await seedGenome(session, name: 'carrier')).id,
      );

      expect(await namesOf('cardiomyopathy'), contains('panel 7'));
      expect(await namesOf('telomere'), contains('hs1'));
      expect(await namesOf('gnomAD'), contains('set 3'));
    });

    test('a one-character query answers with nothing, not everything', () async {
      final options = await seedOptions(session);
      await seedProject(session, name: 'aardvark', options: options.id!);

      expect(await endpoints.search.search(sessionBuilder, 'a'), isEmpty);
      expect(await endpoints.search.search(sessionBuilder, ''), isEmpty);
      expect(await endpoints.search.search(sessionBuilder, '  '), isEmpty);
      // Two characters is where it starts working, so the boundary is pinned from
      // both sides rather than only from below.
      expect(await namesOf('aa'), contains('aardvark'));
    });

    test(
      '⚠️ a query of % matches a literal per cent sign, not every row',
      () async {
        final options = await seedOptions(session);
        await seedProject(session, name: 'coverage', options: options.id!);
        await seedProject(session, name: '95% on target', options: options.id!);

        final names = await namesOf('5%');
        expect(names, contains('95% on target'));
        expect(
          names,
          isNot(contains('coverage')),
          reason: 'an unescaped % turns the pattern into a match-all',
        );
      },
    );

    test(
      'an underscore is a literal, not a single-character wildcard',
      () async {
        final options = await seedOptions(session);
        await seedProject(session, name: 'a_c naming', options: options.id!);
        await seedProject(session, name: 'abc naming', options: options.id!);

        final names = await namesOf('a_c');
        expect(names, contains('a_c naming'));
        expect(names, isNot(contains('abc naming')));
      },
    );

    test('a genome hit carries its category, an SNP hit its genome', () async {
      final genome = await seedGenome(
        session,
        name: 'mm39',
        category: 'Mus musculus',
      );
      await seedSnp(session, name: 'mm39 commons', genome: genome.id);

      final hits = await endpoints.search.search(sessionBuilder, 'mm39');
      final genomeHit = hits.firstWhere((h) => h.kind == SearchHitKind.genome);
      final snpHit = hits.firstWhere((h) => h.kind == SearchHitKind.snpSet);

      expect(genomeHit.genomeId, genome.id);
      expect(genomeHit.category, 'Mus musculus');
      expect(genomeHit.context, 'Mus musculus');

      // Everything the client needs to open the set: which genome, and which rail
      // category that genome is filed under.
      expect(snpHit.genomeId, genome.id);
      expect(snpHit.category, 'Mus musculus');
      expect(snpHit.context, 'mm39');
    });

    test('an SNP set whose genome is gone is not offered', () async {
      // Navigable to nowhere — the model already says such a row appears in no
      // picker, and search is a picker.
      await seedSnp(session, name: 'orphan calls', genome: null);

      expect(await namesOf('orphan'), isEmpty);
    });

    test('each kind is capped, and the cap is per kind', () async {
      final options = await seedOptions(session);
      for (var i = 0; i < 12; i++) {
        await seedGenome(session, name: 'capped genome $i');
        await seedProject(
          session,
          name: 'capped project $i',
          options: options.id!,
        );
      }

      final hits = await endpoints.search.search(sessionBuilder, 'capped');
      expect(
        hits.where((h) => h.kind == SearchHitKind.genome),
        hasLength(SearchService.hitsPerKind),
      );
      expect(
        hits.where((h) => h.kind == SearchHitKind.project),
        hasLength(SearchService.hitsPerKind),
      );
    });

    test('with the gate open every SNP set is found, private or not', () async {
      final genome = await seedGenome(session, name: 'open');
      await seedSnp(
        session,
        name: 'open secret',
        genome: genome.id,
        custom: true,
        private: true,
      );

      expect(await namesOf('open secret'), ['open secret']);
    });
  });

  withServerpod('Search authorization', (sessionBuilder, endpoints) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    setUp(() => http.reset());

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

    Future<List<String>> namesOf(
      TestSessionBuilder who,
      String query, {
      SearchHitKind? kind,
    }) async {
      final hits = await endpoints.search.search(who, query);
      return hits
          .where((h) => kind == null || h.kind == kind)
          .map((h) => h.name)
          .toList();
    }

    test(
      'a private SNP set: owner and admin find it, another user does not',
      () async {
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final alice = await signIn('alice@uni.example');
        final bob = await signIn('bob@uni.example');
        final root = await signIn('root@uni.example', isAdmin: true);
        await seedSnp(
          session,
          name: 'alice private calls',
          genome: genome.id,
          owner: alice.user.id,
          custom: true,
          private: true,
        );

        expect(await namesOf(alice.builder, 'private calls'), [
          'alice private calls',
        ]);
        expect(await namesOf(bob.builder, 'private calls'), isEmpty);
        expect(await namesOf(root.builder, 'private calls'), [
          'alice private calls',
        ]);
      },
    );

    test(
      '⚠️ a shared but half-finished import stays hidden from everybody else',
      () async {
        await enforceSso(session);
        final genome = await seedGenome(session, name: 'hg38');
        final alice = await signIn('alice2@uni.example');
        final bob = await signIn('bob2@uni.example');
        await seedSnp(
          session,
          name: 'downloading clinvar',
          genome: genome.id,
          owner: alice.user.id,
          custom: true,
          // Shared, so `visibleSnps` alone would let Bob see it. Only the second
          // pass hides it — which is what makes this the test proving
          // `listableSnps`, and not just `visibleSnps`, is on the search path.
          private: false,
          status: SnpImportStatus.downloading,
        );

        expect(await namesOf(alice.builder, 'downloading clinvar'), [
          'downloading clinvar',
        ]);
        expect(await namesOf(bob.builder, 'downloading clinvar'), isEmpty);
      },
    );

    test("an owned project is not found by somebody else", () async {
      await enforceSso(session);
      final options = await seedOptions(session);
      final alice = await signIn('alice3@uni.example');
      final bob = await signIn('bob3@uni.example');
      // Owned on purpose: an unowned project is accessible to everybody by
      // design, so seeding one would prove nothing.
      await seedProject(
        session,
        name: 'alice deletion panel',
        options: options.id!,
        owner: alice.user.id,
      );

      expect(await namesOf(alice.builder, 'deletion panel'), [
        'alice deletion panel',
      ]);
      expect(await namesOf(bob.builder, 'deletion panel'), isEmpty);
    });

    test('⚠️ the per-kind cap does not eat projects the caller may see', () async {
      // The regression test for the no-SQL-`LIMIT` decision. A `LIMIT 8` in the
      // project query would return eight rows, of which Bob owns six, leaving
      // Alice two of her four — silently. If this test starts failing, somebody
      // has pushed a `limit:` into `visibleProjects`.
      await enforceSso(session);
      final options = await seedOptions(session);
      final alice = await signIn('alice4@uni.example');
      final bob = await signIn('bob4@uni.example');
      for (var i = 0; i < 6; i++) {
        await seedProject(
          session,
          name: 'shared prefix bob $i',
          options: options.id!,
          owner: bob.user.id,
        );
      }
      for (var i = 0; i < 4; i++) {
        await seedProject(
          session,
          name: 'shared prefix alice $i',
          options: options.id!,
          owner: alice.user.id,
        );
      }

      expect(
        await namesOf(alice.builder, 'shared prefix'),
        hasLength(4),
        reason: 'all four of Alice\'s projects match and all four are hers',
      );
      expect(await namesOf(bob.builder, 'shared prefix'), hasLength(6));
    });
  });
}
