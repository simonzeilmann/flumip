import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/matchers.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// GenomeService with future-call scheduling stubbed so indexFasta can be
/// tested without the serverpod future-call machinery.
class NoScheduleGenomeService extends GenomeService {
  @override
  Future<void> scheduleIndexProgressCheck(Session session, Genome genome) async {}
}

// Single shared fake registered once (see mipgen_service_test.dart for why).
final fake = FakeProcessRunner();

/// Writes the five bwa index files (plus the .fa) into [faDir].
void writeIndexedFa(String faDir) {
  Directory(faDir).createSync(recursive: true);
  File('$faDir/hg38.fa').writeAsStringSync('>chr1\nACGT\n');
  for (final ext in ['.fa.amb', '.fa.pac', '.fa.sa', '.fa.bwt', '.fa.ann']) {
    File('$faDir/hg38$ext').writeAsStringSync('x');
  }
}

void main() {
  withServerpod('GenomeService.indexFasta', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();

    test('indexFasta starts bwa and records the pid', () async {
      final genome = await seedGenome(session,
          name: 'hg38', path: '/data/hg38', fastaPath: '/data/hg38/fa/hg38.fa');
      fake.stubRun('pgrep', exitCode: 0, stdout: '321 bwa index /data/hg38/fa/hg38.fa\n');
      await NoScheduleGenomeService().indexFasta(session, genome.id!);
      final reloaded = await GenomeService().getGenome(session, genome.id!);
      expect(reloaded.indexing, isTrue);
      expect(reloaded.indexPID, 321);
      final started = fake.startCalls.firstWhere((c) => c.executable == 'bwa');
      expect(started.arguments, ['index', '/data/hg38/fa/hg38.fa']);
    }, tags: ['unit']);

    test('indexFasta throws for a missing genome', () async {
      expect(
        () => NoScheduleGenomeService().indexFasta(session, -1),
        throwsA(isA<ArgumentError>()),
      );
    }, tags: ['unit']);

    test('indexFasta throws when already indexed', () async {
      final genome = await seedGenome(session,
          name: 'hg38', path: '/data/hg38', fastaPath: '/x.fa', indexed: true);
      expect(
        () => NoScheduleGenomeService().indexFasta(session, genome.id!),
        throwsA(isA<ArgumentError>()),
      );
    }, tags: ['unit']);

    test('indexFasta throws when already indexing', () async {
      final genome = await seedGenome(session,
          name: 'hg38', path: '/data/hg38', fastaPath: '/x.fa', indexing: true);
      expect(
        () => NoScheduleGenomeService().indexFasta(session, genome.id!),
        throwsA(isA<ArgumentError>()),
      );
    }, tags: ['unit']);

    test('indexFasta throws when the genome has no fasta path', () async {
      final genome = await seedGenome(session, name: 'hg38', path: '/data/hg38');
      expect(
        () => NoScheduleGenomeService().indexFasta(session, genome.id!),
        throwsA(isA<ArgumentError>()),
      );
    }, tags: ['unit']);
  });

  withServerpod('GenomeService.indexIsFinished', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final genomeService = GenomeService();

    test('marks indexed when all bwa index files are present', () async {
      final base = createTempDir('idxfin');
      writeIndexedFa('${base.path}/fa');
      final genome = await seedGenome(session,
          name: 'hg38', path: base.path, indexing: true, indexPID: 5);
      await genomeService.indexIsFinished(session, genome);
      final reloaded = await genomeService.getGenome(session, genome.id!);
      expect(reloaded.indexed, isTrue);
      expect(reloaded.indexResults, 0);
      expect(reloaded.indexing, isFalse);
      expect(reloaded.indexPID, 0);
    }, tags: ['unit']);

    test('marks failure when the index files are missing', () async {
      final base = createTempDir('idxfin');
      Directory('${base.path}/fa').createSync(recursive: true);
      File('${base.path}/fa/hg38.fa').writeAsStringSync('>chr1\n');
      final genome =
          await seedGenome(session, name: 'hg38', path: base.path, indexing: true);
      await genomeService.indexIsFinished(session, genome);
      final reloaded = await genomeService.getGenome(session, genome.id!);
      expect(reloaded.indexed, isFalse);
      expect(reloaded.indexResults, 1);
      expect(reloaded.indexing, isFalse);
    }, tags: ['unit']);
  });

  withServerpod('GenomeService.deleteFastaIndex', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final genomeService = GenomeService();

    test('deletes the bwa index files but keeps the fasta', () async {
      final base = createTempDir('delidx');
      writeIndexedFa('${base.path}/fa');
      final genome = await seedGenome(session,
          name: 'hg38', path: base.path, indexed: true);
      await genomeService.deleteFastaIndex(session, genome.id!);
      expect(File('${base.path}/fa/hg38.fa').existsSync(), isTrue);
      expect(File('${base.path}/fa/hg38.fa.amb').existsSync(), isFalse);
      expect(File('${base.path}/fa/hg38.fa.bwt').existsSync(), isFalse);
      final reloaded = await genomeService.getGenome(session, genome.id!);
      expect(reloaded.indexed, isFalse);
    }, tags: ['unit']);

    test('throws when the genome is not indexed', () async {
      final base = createTempDir('delidx');
      Directory('${base.path}/fa').createSync(recursive: true);
      final genome = await seedGenome(session,
          name: 'hg38', path: base.path, indexed: false);
      expect(
        () => genomeService.deleteFastaIndex(session, genome.id!),
        throwsA(isA<ArgumentError>()),
      );
    }, tags: ['unit']);
  });

  withServerpod('GenomeService.collectGenomes', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    var session = sessionBuilder.build();
    final genomeService = GenomeService();

    test('discovers a genome tree with reference, fasta index and snp',
        () async {
      final base = createTempDir('collect');
      final genomeDir = '${base.path}/genomes';
      final hg38 = '$genomeDir/human/hg38';
      Directory(hg38).createSync(recursive: true);
      File('$hg38/refGene.txt').writeAsStringSync('gene\n');
      writeIndexedFa('$hg38/fa');
      final snpDir = '$hg38/snp/00-common';
      Directory(snpDir).createSync(recursive: true);
      File('$snpDir/common.vcf.gz').writeAsStringSync('v');
      File('$snpDir/common.vcf.gz.tbi').writeAsStringSync('t');
      await overrideSettingsDirs(session, genomeDir: genomeDir);

      await genomeService.collectGenomes(session);

      final genomes = await genomeService.getAllGenomes(session);
      expect(genomes.length, 1);
      final g = genomes.single;
      expect(g.name, 'hg38');
      expect(g.category, 'human');
      expect(g.indexed, isTrue);
      expect(g.refPath, endsWith('refGene.txt'));
      expect(g.fastaPath, endsWith('hg38.fa'));
      final snps = await genomeService.getAllSnps(session);
      expect(snps.length, 1);
      expect(snps.single.name, '00-common');
      // The link lives on the SNP now, not in a list on the genome.
      expect(snps.single.genome, g.id);
    }, tags: ['unit']);

    test('throws when the genome directory does not exist', () async {
      await overrideSettingsDirs(session, genomeDir: '/does/not/exist/xyz');
      expect(
        () => genomeService.collectGenomes(session),
        throwsMessage('Genome folder not found'),
      );
    }, tags: ['unit']);
  });
}
