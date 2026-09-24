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
import '../support/mipgen_output.dart';
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
        throwsMessage('This project has no genome yet.'),
      );
    }, tags: ['unit']);

    test(
      'createBedFile throws when the genome has no reference path',
      () async {
        final p = await prepare(refPath: null, genes: ['BRCA1']);
        expect(
          () => mipgenService.createBedFile(session, p.id),
          throwsMessage('has no gene annotation file'),
        );
      },
      tags: ['unit'],
    );

    test('createBedFile throws when the project has no genes', () async {
      final p = await prepare();
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('This project has no genes yet.'),
      );
    }, tags: ['unit']);

    // ⚠️ Two tests, because these used to be one message for two causes — and
    // the shared wording sent whoever read it off checking gene symbols when
    // the real problem was a path in Settings.
    test('createBedFile blames the script when the script fails', () async {
      final p = await prepare(genes: ['BRCA1']);
      fake.stubRun('exon-script', exitCode: 1, stdout: '');
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('The gene lookup did not run'),
      );
    }, tags: ['unit']);

    test('createBedFile blames the genes when nothing matched', () async {
      final p = await prepare(genes: ['BRCA1']);
      fake.stubRun('exon-script', exitCode: 0, stdout: '');
      expect(
        () => mipgenService.createBedFile(session, p.id),
        throwsMessage('None of these genes were found'),
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

    test('generateMips refuses a project with no genome, in words', () async {
      // It used to dereference project.genome! and reach the user as a 500,
      // while createBedFile checked the very same thing properly.
      final base = createTempDir('genmips');
      await overrideSettingsDirs(session, projectDir: base.path);
      final options = await seedOptions(session);
      final project = await seedProject(
        session,
        options: options.id!,
        folderName: 'proj',
      );
      Directory('${base.path}/proj').createSync(recursive: true);
      expect(
        () =>
            NoScheduleMipgenService().generateMips(session, project.id!, false),
        throwsMessage('This project has no genome yet.'),
      );
    }, tags: ['unit']);

    test('generateMips survives options with no arm lengths', () async {
      // armLengths is nullable and was dereferenced with `!`, so a null took the
      // whole run down. The seed helper even carries a note about seeding an
      // empty string to dodge it.
      final base = createTempDir('genmips');
      await overrideSettingsDirs(
        session,
        projectDir: base.path,
        mipgenExecutable: 'mipgen-exe',
      );
      final options = await ProjectOptions.db.insertRow(
        session,
        ProjectOptions(),
      );
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

      await expectLater(
        NoScheduleMipgenService().generateMips(session, project.id!, false),
        completes,
      );
      final started = fake.startCalls.firstWhere(
        (c) => c.executable == 'mipgen-exe',
      );
      expect(started.arguments, isNot(contains('-arm_lengths')));
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
        throwsMessage('has no sequence file'),
      );
    }, tags: ['unit']);

    test('generateMips passes the chosen SNP as -snp_file', () async {
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
      final snp = await seedSnp(
        session,
        name: 'dbsnp',
        genome: genome.id,
        vcfPath: '/data/snp/dbsnp.vcf.gz',
        tbiPath: '/data/snp/dbsnp.vcf.gz.tbi',
      );
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        genome: genome.id,
        snp: snp.id,
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
      expect(
        started.arguments,
        containsAllInOrder(['-snp_file', '/data/snp/dbsnp.vcf.gz']),
      );
    }, tags: ['unit']);

    test(
      'generateMips directs mipgen\'s output into the project directory',
      () async {
        // ⚠️ Without this, mipgen's own explanation of a failure goes into a pipe
        // nobody reads, and every failure reaches the user as the bare string
        // "MIP generation failed".
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

        await NoScheduleMipgenService().generateMips(
          session,
          project.id!,
          false,
        );

        final started = fake.startCalls.firstWhere(
          (c) => c.executable == 'mipgen-exe',
        );
        expect(started.outputPath, '${base.path}/proj/$mipgenLogName');
      },
      tags: ['unit'],
    );

    test('generateMips refuses to run when the chosen SNP is not ready', () async {
      // ⚠️ A behaviour change, and the point of it. The old code simply left
      // `-snp_file` off the command line when the paths were empty, so the run
      // went ahead and produced a perfectly plausible set of MIPs designed
      // without the masking the user asked for — with nothing in the result to
      // say so. Now that an SNP can fail to import or be deleted out from under
      // a project, that is reachable in normal use.
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
      final snp = await seedSnp(
        session,
        name: 'broken panel',
        genome: genome.id,
        custom: true,
        status: SnpImportStatus.failed,
        vcfPath: '',
        tbiPath: '',
      );
      final project = await seedProject(
        session,
        name: 'demo',
        options: options.id!,
        folderName: 'proj',
        genome: genome.id,
        snp: snp.id,
      );
      Directory('${base.path}/proj').createSync(recursive: true);

      await expectLater(
        NoScheduleMipgenService().generateMips(session, project.id!, false),
        throwsA(
          isA<ArgumentException>().having(
            (e) => e.message,
            'message',
            contains('broken panel'),
          ),
        ),
      );
      expect(
        fake.startCalls.where((c) => c.executable == 'mipgen-exe'),
        isEmpty,
      );
    }, tags: ['unit']);
  });

  withServerpod('MipgenService.mipgenIsFinished', (sessionBuilder, endpoints) {
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final mipgenService = sl<MipgenService>();

    /// Seeds an active project and, when asked, the output of a run.
    ///
    /// ⚠️ `withProgress: true` writes a *complete* run: a progress file that
    /// reaches mipgen's own completion marker and a design whose rows all carry
    /// their twenty fields. It used to write the single line `done`, which is
    /// what a run cut short leaves behind — so every test here that meant
    /// "finished successfully" was in fact asserting success on the exact
    /// output [MipgenService.designProblem] now refuses.
    Future<({int id, String dir})> prepare({
      required bool withProgress,
      String? progress,
      String? pickedMips,
    }) async {
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
        File(
          '$dir/run.progress.txt',
        ).writeAsStringSync(progress ?? completeProgress);
        File(
          '$dir/demo.$pickedMipsSuffix',
        ).writeAsStringSync(pickedMips ?? completeDesign);
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
      // With no log to read, it says so and points at the file to look for,
      // rather than repeating a bare "failed".
      expect(project.error, contains('MIP generation failed'));
      expect(project.error, contains(mipgenLogName));
      expect(project.active, isFalse);
      expect(project.pid, 0);
    }, tags: ['unit']);

    test('a failure reports what mipgen actually said', () async {
      // ⚠️ The whole point. "MIP generation failed" used to be the entire
      // diagnosis for every kind of failure, so a run that died explaining
      // exactly what was wrong was indistinguishable from one that vanished.
      final p = await prepare(withProgress: false);
      File('${p.dir}/$mipgenLogName').writeAsStringSync(
        '-trf off\n'
        '[mipgen] feature #1\n'
        '[mipgen] feature #2\n'
        'could not open snp file: no index found\n',
      );

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      final project = await ProjectService().getProject(session, p.id);
      expect(project.error, contains('no index found'));
      // Its own progress chatter is dropped, or the "reason" would just be the
      // last feature number it reached.
      expect(project.error, isNot(contains('feature #')));
    }, tags: ['unit']);

    test(
      'a very long complaint is truncated rather than stored whole',
      () async {
        final p = await prepare(withProgress: false);
        File('${p.dir}/$mipgenLogName').writeAsStringSync('x' * 5000);

        await mipgenService.mipgenIsFinished(
          session,
          await ProjectService().getProject(session, p.id),
        );

        final project = await ProjectService().getProject(session, p.id);
        expect(project.error.length, lessThan(500));
      },
      tags: ['unit'],
    );

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

    test('a failed UCSC track is a warning, not a failed project', () async {
      // ⚠️ This asserted the opposite until now: `project.error` contained
      // "MIP generation failed". But `withProgress: true` means the MIPs were
      // designed and are on disk — the only thing that went wrong is the track
      // file generated *after* them. Reporting that as a failed run sends people
      // looking for results they already have.
      final p = await prepare(withProgress: true);
      fake.runError = Exception('python blew up');

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      final project = await ProjectService().getProject(session, p.id);
      expect(project.active, isFalse);
      expect(project.pid, 0);
      expect(project.error, isEmpty);
      expect(project.warning, contains('UCSC track'));
      expect(project.warning, contains('python blew up'));
      // Still a completed run.
      expect(project.completedIn, isNotNull);
    }, tags: ['unit']);

    test('a run that produced nothing is still a failure', () async {
      // The distinction only holds if the genuine failure still reports as one.
      final p = await prepare(withProgress: false);

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      final project = await ProjectService().getProject(session, p.id);
      expect(project.active, isFalse);
      expect(project.pid, 0);
      expect(project.error, contains('MIP generation failed'));
      expect(project.warning, isEmpty);
    }, tags: ['unit']);

    test('a design cut short is a failed project, not a complete one', () async {
      // ⚠️ The bug this check exists for. Everything here says success by the
      // old test — mipgen is gone, a progress file is there and reaches its own
      // completion marker — and the design is still missing a field off its
      // last row, because the run was killed while writing it.
      final p = await prepare(withProgress: true, pickedMips: truncatedDesign);
      fake.stubRun('python', exitCode: 0);

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      final project = await ProjectService().getProject(session, p.id);
      expect(project.active, isFalse);
      expect(project.pid, 0);
      expect(project.error, contains('should not be used'));
      // Says which row, so the file can be opened at the same place.
      expect(project.error, contains('row 3'));
      // ⚠️ And it says what to do about it. The tile and the email show this
      // string and nothing else, so a diagnosis with no next step strands the
      // reader.
      expect(project.error, contains('Generate the MIPs again'));
      expect(project.error, contains(mipgenLogName));
      // ⚠️ And it is a *failure*, not a warning about the track. Reporting this
      // as "the MIPs were designed, but the UCSC track could not be built" is
      // exactly how an incomplete design went unnoticed.
      expect(project.warning, isEmpty);
    }, tags: ['unit']);

    test('an incomplete design is not handed to the track generator', () async {
      // No point, and worse than no point: the generator reads the same
      // truncated file, so it fails too and its complaint is what people see
      // instead of the real one.
      final p = await prepare(withProgress: true, pickedMips: truncatedDesign);
      fake.stubRun('python', exitCode: 0);

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      expect(fake.lastFor('python'), isNull);
    }, tags: ['unit']);

    test('a run that stopped before picking is a failed project', () async {
      // The other ending: the file mipgen wrote is intact as far as it goes,
      // and only its progress file shows it never reached the end.
      final p = await prepare(
        withProgress: true,
        progress: interruptedProgress,
      );

      await mipgenService.mipgenIsFinished(
        session,
        await ProjectService().getProject(session, p.id),
      );

      final project = await ProjectService().getProject(session, p.id);
      expect(project.active, isFalse);
      expect(project.error, contains('interrupted before it finished'));
      expect(project.error, contains('Generate the MIPs again'));
      expect(fake.lastFor('python'), isNull);
    }, tags: ['unit']);
  });
}
