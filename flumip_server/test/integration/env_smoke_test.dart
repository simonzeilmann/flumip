import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// End-to-end smoke tests that use the REAL external tools and reference data
/// under /opt/flumip. They are tagged `env` and excluded from CI
/// (`dart test --exclude-tags env`); run them locally or on a self-hosted
/// runner where setup-mipgen.sh has installed the tools and hg38 data.

/// GenomeService that skips future-call scheduling so the smoke test can await
/// bwa completion directly.
class NoScheduleGenomeService extends GenomeService {
  @override
  Future<void> scheduleIndexProgressCheck(
    Session session,
    Genome genome,
  ) async {}
}

Future<void> eventually(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('condition not met within $timeout');
}

void main() {
  withServerpod('createBedFile (real hg38)', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final projectService = sl<ProjectService>();
    final mipgenService = sl<MipgenService>();
    final fileService = sl<FileService>();

    test('createBedFile builds a bed file from the real exon script', () async {
      final settings = await SettingsService().getSettings(session);
      final genome = await seedGenome(
        session,
        name: 'hg38',
        refPath: '${settings.genomeDir}/human/hg38/refGene.txt',
        fastaPath: '${settings.genomeDir}/human/hg38/fa/hg38.fa',
      );
      final project = await projectService.createProject(
        session,
        'smoke',
        ProjectOptions(id: 1),
      );
      project.genome = genome.id;
      await projectService.updateProject(session, project);
      await projectService.addGeneToProject(session, project.id!, 'BRCA1');

      await mipgenService.createBedFile(session, project.id!);

      expect(
        await fileService.checkBedFileExists(session, project.id!),
        isTrue,
      );
    }, tags: ['env']);
  });

  withServerpod('bwa index (real)', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();

    test('indexFasta runs bwa and produces index files', () async {
      final base = Directory.systemTemp.createTempSync('flumip_bwa_');
      addTearDown(() {
        if (base.existsSync()) base.deleteSync(recursive: true);
      });
      final faDir = Directory('${base.path}/fa')..createSync(recursive: true);
      final fasta = File('${faDir.path}/tiny.fa')
        ..writeAsStringSync('>chr1\n${'ACGT' * 20}\n');
      final genome = await seedGenome(
        session,
        name: 'tiny',
        path: base.path,
        fastaPath: fasta.path,
      );

      await NoScheduleGenomeService().indexFasta(session, genome.id!);

      // bwa writes .amb/.ann/.bwt/.pac/.sa next to the fasta.
      await eventually(() => File('${fasta.path}.bwt').existsSync());
      expect(File('${fasta.path}.amb').existsSync(), isTrue);
      final reloaded = await GenomeService().getGenome(session, genome.id!);
      expect(reloaded.indexing, isTrue);
    }, tags: ['env']);
  });
}
