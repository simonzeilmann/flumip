import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:test/test.dart';

import '../support/matchers.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/seed.dart';

void main() {
  withServerpod('GenomeService genomes', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final genomeService = GenomeService();

    test('getAllGenomes returns an empty list when none exist', () async {
      expect(await genomeService.getAllGenomes(session), isEmpty);
    }, tags: ['unit']);

    test('getAllGenomes returns all seeded genomes', () async {
      await seedGenome(session, name: 'hg38');
      await seedGenome(session, name: 'hg19');
      final genomes = await genomeService.getAllGenomes(session);
      expect(genomes.map((g) => g.name), containsAll(['hg38', 'hg19']));
    }, tags: ['unit']);

    test('getGenome returns the requested genome', () async {
      final seeded = await seedGenome(session, name: 'hs1');
      final genome = await genomeService.getGenome(session, seeded.id!);
      expect(genome.name, 'hs1');
    }, tags: ['unit']);

    test('getGenome throws FileNotFoundException for a missing id', () async {
      expect(
        () => genomeService.getGenome(session, -1),
        throwsMessage('Genome not found'),
      );
    }, tags: ['unit']);

    test('getGenomeCategories returns the distinct categories', () async {
      await seedGenome(session, name: 'a', category: 'human');
      await seedGenome(session, name: 'b', category: 'human');
      await seedGenome(session, name: 'c', category: 'mouse');
      final categories = await genomeService.getGenomeCategories(session);
      expect(categories.toSet(), {'human', 'mouse'});
    }, tags: ['unit']);

    test('getGenomeByCategory returns only matching genomes', () async {
      await seedGenome(session, name: 'a', category: 'human');
      await seedGenome(session, name: 'b', category: 'mouse');
      final human = await genomeService.getGenomeByCategory(session, 'human');
      expect(human.map((g) => g.name), ['a']);
    }, tags: ['unit']);

    test('updateGenome persists changes', () async {
      final seeded = await seedGenome(session, name: 'hg38');
      seeded.description = 'updated';
      await genomeService.updateGenome(session, seeded.id!, seeded);
      final reloaded = await genomeService.getGenome(session, seeded.id!);
      expect(reloaded.description, 'updated');
    }, tags: ['unit']);

    test(
      'updateGenome throws FileNotFoundException for a missing id',
      () async {
        final ghost = Genome(id: 9999, name: 'ghost');
        expect(
          () => genomeService.updateGenome(session, 9999, ghost),
          throwsMessage('Genome not found'),
        );
      },
      tags: ['unit'],
    );
  });

  withServerpod('GenomeService snps', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final genomeService = GenomeService();

    test('getAllSnps returns all seeded snps', () async {
      await seedSnp(session, name: 'common');
      await seedSnp(session, name: 'private');
      final snps = await genomeService.getAllSnps(session);
      expect(snps.map((s) => s.name), containsAll(['common', 'private']));
    }, tags: ['unit']);

    test('getSnp returns the requested snp', () async {
      final seeded = await seedSnp(session, name: 'common');
      final snp = await genomeService.getSnp(session, seeded.id!);
      expect(snp.name, 'common');
    }, tags: ['unit']);

    test('getSnp throws FileNotFoundException for a missing id', () async {
      expect(
        () => genomeService.getSnp(session, -1),
        throwsMessage('SNP not found'),
      );
    }, tags: ['unit']);

    test(
      'getAllSnpForGenome returns the SNPs pointing at the genome',
      () async {
        final genome = await seedGenome(session, name: 'hg38');
        await seedSnp(session, name: 'common', genome: genome.id);
        await seedSnp(session, name: 'private', genome: genome.id);
        final snps = await genomeService.getAllSnpForGenome(
          session,
          genome.id!,
        );
        expect(snps.map((s) => s.name), containsAll(['common', 'private']));
      },
      tags: ['unit'],
    );

    test(
      'getAllSnpForGenome ignores SNPs belonging to another genome',
      () async {
        final hg38 = await seedGenome(session, name: 'hg38');
        final hs1 = await seedGenome(session, name: 'hs1');
        await seedSnp(session, name: 'for-hg38', genome: hg38.id);
        await seedSnp(session, name: 'for-hs1', genome: hs1.id);
        final snps = await genomeService.getAllSnpForGenome(session, hg38.id!);
        expect(snps.map((s) => s.name), ['for-hg38']);
      },
      tags: ['unit'],
    );

    test(
      'getAllSnpForGenome returns an empty list for a genome with none',
      () async {
        // Used to be a `genome.snp!` that threw. The endpoint is reachable
        // directly, so a genome that never had an SNP crashed rather than
        // answering "none".
        final genome = await seedGenome(session, name: 'hg38');
        expect(
          await genomeService.getAllSnpForGenome(session, genome.id!),
          isEmpty,
        );
      },
      tags: ['unit'],
    );

    test('getAllSnpForGenome throws for a missing genome', () async {
      expect(
        () => genomeService.getAllSnpForGenome(session, -1),
        throwsMessage('Genome not found'),
      );
    }, tags: ['unit']);
  });
}
