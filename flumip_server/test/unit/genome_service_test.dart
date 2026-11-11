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

    test(
      'getGenome throws FlumipFileNotFoundException for a missing id',
      () async {
        expect(
          () => genomeService.getGenome(session, -1),
          throwsMessage('This genome no longer exists.'),
        );
      },
      tags: ['unit'],
    );

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
      'updateGenome takes the switch and nothing that names a file',
      () async {
        // The whole client object used to be written. That let anyone who may
        // flip the switch point the reference at a path of their choosing, which
        // mipgen then pastes into a shell command.
        final seeded = await seedGenome(
          session,
          name: 'hg38',
          path: '/data/hg38',
          fastaPath: '/data/hg38/fa/hg38.fa',
          refPath: '/data/hg38/refGene.txt',
          snpFolder: '/data/hg38/snp',
          category: 'human',
          indexed: true,
          indexPID: 41,
        );

        await genomeService.updateGenome(
          session,
          seeded.id!,
          Genome(
            id: seeded.id,
            name: 'renamed',
            active: false,
            path: '/tmp/elsewhere',
            fastaPath: '/x;id;#',
            refPath: '/etc/passwd',
            snpFolder: '/tmp',
            category: 'other',
            indexed: false,
            indexing: true,
            indexPID: 1,
          ),
        );

        final reloaded = await genomeService.getGenome(session, seeded.id!);
        expect(reloaded.active, isFalse);
        expect(reloaded.name, 'hg38');
        expect(reloaded.path, '/data/hg38');
        expect(reloaded.fastaPath, '/data/hg38/fa/hg38.fa');
        expect(reloaded.refPath, '/data/hg38/refGene.txt');
        expect(reloaded.snpFolder, '/data/hg38/snp');
        expect(reloaded.category, 'human');
        expect(reloaded.indexed, isTrue);
        expect(reloaded.indexing, isFalse);
        expect(reloaded.indexPID, 41);
      },
      tags: ['unit'],
    );

    test('updateGenome changes the genome it was asked about', () async {
      // It used to update the row named by the object, not by the id.
      final asked = await seedGenome(session, name: 'asked');
      final other = await seedGenome(session, name: 'other');

      await genomeService.updateGenome(
        session,
        asked.id!,
        Genome(id: other.id, name: 'other', active: false),
      );

      expect((await genomeService.getGenome(session, asked.id!)).active, false);
      expect((await genomeService.getGenome(session, other.id!)).active, true);
    }, tags: ['unit']);

    test(
      'updateGenome throws FlumipFileNotFoundException for a missing id',
      () async {
        final ghost = Genome(id: 9999, name: 'ghost');
        expect(
          () => genomeService.updateGenome(session, 9999, ghost),
          throwsMessage('This genome no longer exists.'),
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

    test(
      'getSnp throws FlumipFileNotFoundException for a missing id',
      () async {
        expect(
          () => genomeService.getSnp(session, -1),
          throwsMessage('This SNP set no longer exists.'),
        );
      },
      tags: ['unit'],
    );

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
        throwsMessage('This genome no longer exists.'),
      );
    }, tags: ['unit']);
  });
}
