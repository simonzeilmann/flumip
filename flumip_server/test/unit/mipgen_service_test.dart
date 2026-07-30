import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/matchers.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// MipgenService with the future-call scheduling stubbed out, so generateMips
/// can be tested without the serverpod future-call machinery.
class NoScheduleMipgenService extends MipgenService {
  @override
  Future<void> scheduleMipgenProgressCheck(
    Session session,
    Project project, {
    Duration delay = const Duration(seconds: 10),
  }) async {}
}

// One shared fake for the whole file. withServerpod group bodies run at
// collection time, so registering a *different* fake per group would leave the
// last one globally registered; instead we register a single fake once and
// reset it before each test.
final fake = FakeProcessRunner();

void main() {
  withServerpod('MipgenService.createBedFile', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final mipgenService = sl<MipgenService>();

    // Seeds a project (with an on-disk dir) linked to a genome, plus a temp
    // projectDir and a stubbable exon-extract script path.
    Future<({int id, String dir, String refPath})> prepare({
      bool withGenome = true,
      String? refPath = '/data/hg38/refGene.txt',
      List<String>? genes,
    }) async {
      final base = createTempDir('bedfile');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        exonExtractScript: 'exon-script',
      );
      int? genomeId;
      if (withGenome) {
        final genome = await seedGenome(
          session,
          name: 'hg38',
          refPath: refPath,
        );
        genomeId = genome.id;
      }
      final project = await seedProject(
        session,
        options: 1,
        folderName: 'proj',
        genome: genomeId,
        genes: genes,
      );
      final dir = '${base.path}/proj';
      Directory(dir).createSync(recursive: true);
      return (id: project.id!, dir: dir, refPath: refPath ?? '');
    }

    test(
      'createBedFile writes a bed file from the exon-script output',
      () async {
        final p = await prepare(genes: ['BRCA1']);
        fake.stubRun(
          'exon-script',
          exitCode: 0,
          stdout: 'chr17\t1\t2\tBRCA1\n' * 100,
        );
        await mipgenService.createBedFile(session, p.id);
        expect(File('${p.dir}/genes.bed').existsSync(), isTrue);
        // The exon script is invoked with [geneFile, refPath].
        final call = fake.lastFor('exon-script')!;
        expect(call.arguments, ['${p.dir}/genes.txt', p.refPath]);
      },
      tags: ['unit'],
    );

    test('createBedFile throws when the project has no genome', () async {
      final p = await prepare(withGenome: false, genes: ['BRCA1']);
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('No genome found in project'),
      );
    }, tags: ['unit']);

    test(
      'createBedFile throws when the genome has no reference path',
      () async {
        final p = await prepare(refPath: null, genes: ['BRCA1']);
        expect(
          () => mipgenService.createBedFile(session, p.id),
          throwsMessage('No reference path found in genome'),
        );
      },
      tags: ['unit'],
    );

    test('createBedFile throws when the project has no genes', () async {
      final p = await prepare();
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('No genes found in project'),
      );
    }, tags: ['unit']);

    test('createBedFile throws when the exon script fails', () async {
      final p = await prepare(genes: ['BRCA1']);
      fake.stubRun('exon-script', exitCode: 1, stdout: '');
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('The supplied genes cannot be found'),
      );
    }, tags: ['unit']);
  });

  withServerpod('MipgenService.generateMips', (sessionBuilder, endpoints) {
    setUp(fake.reset);
    var session = sessionBuilder.build();

    test('generateMips starts mipgen and records the discovered pid', () async {
      final base = createTempDir('genmips');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        mipgenExecutable: 'mipgen-exe',
      );
      final options = await seedOptions(session);
      final genome = await seedGenome(
        session,
        name: 'hg38',
        fastaPath: '/data/hg38.fa',
      );
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        genome: genome.id,
      );
      Directory('${base.path}/proj').createSync(recursive: true);
      fake.stubRun(
        'pgrep',
        exitCode: 0,
        stdout: '777 mipgen -project_name demo\n',
      );

      await NoScheduleMipgenService().generateMips(session, project.id!, false);

      final started = fake.startCalls.firstWhere(
        (c) => c.executable == 'mipgen-exe',
      );
      expect(started.arguments, contains('-project_name'));
      expect(started.arguments, contains('demo'));
      final reloaded = await ProjectService().getProject(session, project.id!);
      expect(reloaded.pid, 777);
      expect(reloaded.active, isTrue);
    }, tags: ['unit']);

    test('generateMips throws when the genome has no fasta path', () async {
      final base = createTempDir('genmips');
      await overrideSettingsDirs(session, projectDir: base.path);
      final options = await seedOptions(session);
      final genome = await seedGenome(session, name: 'hg38'); // no fastaPath
      final project = await seedProject(
        session,
        options: options.id!,
        folderName: 'proj',
        genome: genome.id,
      );
      Directory('${base.path}/proj').createSync(recursive: true);
      expect(
        () =>
            NoScheduleMipgenService().generateMips(session, project.id!, false),
        throwsMessage('No fasta path found in genome'),
      );
    }, tags: ['unit']);
  });

  withServerpod('MipgenService.mipgenIsFinished', (sessionBuilder, endpoints) {
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final mipgenService = sl<MipgenService>();

    Future<({int id, String dir})> prepare({required bool withProgress}) async {
      final base = createTempDir('finish');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        ucscTrackGenerator: 'ucsc-gen',
      );
      final project = await seedProject(
        session,
        name: 'demo',
        options: 1,
        folderName: 'proj',
        pid: 999,
        active: true,
        started: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final dir = '${base.path}/proj';
      Directory(dir).createSync(recursive: true);
      if (withProgress) {
        File('$dir/run.progress.txt').writeAsStringSync('done\n');
      }
      return (id: project.id!, dir: dir);
    }

    test('records failure and finalizes when progress is empty', () async {
      final p = await prepare(withProgress: false);
      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );
      final project = await ProjectService().getProject(session, p.id);
      expect(project.error, 'MIP generation failed');
      expect(project.active, isFalse);
      expect(project.pid, 0);
    }, tags: ['unit']);

    test('finalizes successfully and generates the UCSC track', () async {
      final p = await prepare(withProgress: true);
      fake.stubRun('python', exitCode: 0);
      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );
      final project = await ProjectService().getProject(session, p.id);
      expect(project.error, '');
      expect(project.active, isFalse);
      expect(project.pid, 0);
      expect(project.completedIn, isNotNull);
      // The UCSC track generator was invoked via python.
      expect(fake.lastFor('python'), isNotNull);
    }, tags: ['unit']);

    test(
      'always finalizes even when finalization throws (hardening)',
      () async {
        final p = await prepare(withProgress: true);
        fake.runError = Exception('python blew up');
        await mipgenService.mipgenIsFinished(
          session,
          await ProjectService().getProject(session, p.id),
        );
        final project = await ProjectService().getProject(session, p.id);
        expect(project.active, isFalse);
        expect(project.pid, 0);
        expect(project.error, contains('MIP generation failed'));
      },
      tags: ['unit'],
    );
  });
}
