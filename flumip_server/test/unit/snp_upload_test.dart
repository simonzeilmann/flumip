import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/bgzf.dart';
import '../support/temp_dir.dart';

final fake = FakeProcessRunner();

void main() {
  withServerpod('SnpService.resolveUploadTarget', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();
    final service = SnpService();

    /// A pending upload row with its directory made.
    Future<Snp> pending({
      SnpImportStatus status = SnpImportStatus.pending,
    }) async {
      final root = createTempDir('flumip_upload');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final snp = await seedSnp(
        session,
        name: 'incoming',
        custom: true,
        status: status,
        vcfPath: '',
        tbiPath: '',
        folder: '',
      );
      final dir = await service.createUserDirectory(session, snp.id!);
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);
      return snp;
    }

    group('accepted names', () {
      test('a .vcf.gz stages under .incoming and targets the directory',
          () async {
        final snp = await pending();

        final paths =
            await service.resolveUploadTarget(session, snp, 'panel.vcf.gz');

        expect(paths, isNotNull);
        expect(
          paths!.partial.path,
          '${snp.folder}/${SnpService.incomingDirName}/panel.vcf.gz.part',
        );
        expect(paths.target.path, '${snp.folder}/panel.vcf.gz');
        // ⚠️ .incoming is a *directory*, so nothing that lists an SNP folder for
        // files can mistake a half-written .part for a finished VCF.
        expect(
          Directory('${snp.folder}/${SnpService.incomingDirName}').existsSync(),
          isTrue,
        );
      }, tags: ['unit']);

      test('an index is accepted too', () async {
        final snp = await pending();
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz.tbi'),
          isNotNull,
        );
      }, tags: ['unit']);

      test('a failed row accepts a fresh attempt', () async {
        final snp = await pending(status: SnpImportStatus.failed);
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNotNull,
        );
      }, tags: ['unit']);
    });

    group('refused names', () {
      // The gate has to run before anything is created, because containment
      // checks need a file that already exists.
      for (final name in [
        '',
        '.',
        '..',
        '../../etc/passwd',
        '/etc/passwd',
        'sub/panel.vcf.gz',
        r'sub\panel.vcf.gz',
        'panel.vcf',
        'panel.vcf.gz.part',
        'evil.sh',
        '.panel.vcf.gz',
        'my panel.vcf.gz',
      ]) {
        test('refuses "$name"', () async {
          final snp = await pending();
          expect(
            await service.resolveUploadTarget(session, snp, name),
            isNull,
          );
        }, tags: ['unit']);
      }
    });

    group('refused rows', () {
      test('a ready SNP takes no more bytes', () async {
        // ⚠️ Otherwise a second PUT swaps the contents under something already
        // indexed, and possibly already shared with everybody.
        final snp = await pending(status: SnpImportStatus.ready);
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNull,
        );
      }, tags: ['unit']);

      test('a downloading SNP takes no uploads', () async {
        final snp = await pending(status: SnpImportStatus.downloading);
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNull,
        );
      }, tags: ['unit']);

      test('a row with no folder is refused', () async {
        final snp = await pending();
        snp.folder = '';
        await Snp.db.updateRow(session, snp);
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNull,
        );
      }, tags: ['unit']);

      test('a folder outside the custom SNP tree is refused', () async {
        final outside = createTempDir('flumip_outside');
        final snp = await pending();
        snp.folder = outside.path;
        await Snp.db.updateRow(session, snp);
        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNull,
        );
      }, tags: ['unit']);
    });

    group('no overwriting', () {
      test('a name already on disk is refused', () async {
        final snp = await pending();
        File('${snp.folder}/panel.vcf.gz').writeAsStringSync('already here');

        expect(
          await service.resolveUploadTarget(session, snp, 'panel.vcf.gz'),
          isNull,
        );
        expect(
          File('${snp.folder}/panel.vcf.gz').readAsStringSync(),
          'already here',
          reason: 'the existing file must be untouched',
        );
      }, tags: ['unit']);
    });
  });

  withServerpod('SnpService.settleUpload', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();
    final service = SnpService();

    Future<Snp> uploaded({
      bool withVcf = true,
      bool withTbi = false,
      int extraVcfs = 0,
      List<int>? vcfBytes,
    }) async {
      final root = createTempDir('flumip_settle');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final snp = await seedSnp(
        session,
        custom: true,
        status: SnpImportStatus.pending,
        vcfPath: '',
        tbiPath: '',
        folder: '',
      );
      final dir = await service.createUserDirectory(session, snp.id!);
      if (withVcf) {
        File('${dir.path}/panel.vcf.gz')
            .writeAsBytesSync(vcfBytes ?? completeBgzf());
      }
      if (withTbi) {
        File('${dir.path}/panel.vcf.gz.tbi').writeAsStringSync('index');
      }
      for (var i = 0; i < extraVcfs; i++) {
        File('${dir.path}/extra$i.vcf.gz').writeAsBytesSync(completeBgzf());
      }
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);
      return snp;
    }

    Future<Snp> reload(Snp snp) async =>
        (await Snp.db.findById(session, snp.id!))!;

    test('both files present goes straight to ready', () async {
      final snp = await uploaded(withTbi: true);

      await service.settleUpload(session, snp);

      final done = await reload(snp);
      expect(done.status, SnpImportStatus.ready);
      expect(done.vcfPath, '${snp.folder}/panel.vcf.gz');
      expect(done.tbiPath, '${snp.folder}/panel.vcf.gz.tbi');
      expect(done.size, greaterThan(0));
      expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
    }, tags: ['unit']);

    test('a VCF alone is handed to tabix', () async {
      final snp = await uploaded();
      fake.stubRun('tabix', exitCode: 0);

      await service.settleUpload(session, snp);

      final call = fake.runCalls.firstWhere((c) => c.executable == 'tabix');
      expect(call.arguments, ['-p', 'vcf', '${snp.folder}/panel.vcf.gz']);
      expect(call.runInShell, isFalse);
    }, tags: ['unit']);

    test('nothing arriving fails with something actionable', () async {
      // ⚠️ The client says when it has finished, not what it managed to send.
      // A browser that dropped its PUT must not leave a row claiming to be done.
      final snp = await uploaded(withVcf: false);

      await service.settleUpload(session, snp);

      final done = await reload(snp);
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('No .vcf.gz file arrived'));
    }, tags: ['unit']);

    test('an index alone, with no VCF, fails', () async {
      final snp = await uploaded(withVcf: false, withTbi: true);
      await service.settleUpload(session, snp);
      expect((await reload(snp)).status, SnpImportStatus.failed);
    }, tags: ['unit']);

    test('two VCFs fail rather than guessing which was meant', () async {
      final snp = await uploaded(withTbi: true, extraVcfs: 1);
      await service.settleUpload(session, snp);
      final done = await reload(snp);
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('More than one'));
    }, tags: ['unit']);

    test('a plain gzip VCF is caught by the sniff, not by tabix', () async {
      final snp = await uploaded(vcfBytes: plainGzip());

      await service.settleUpload(session, snp);

      final done = await reload(snp);
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('bgzip'));
      expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
    }, tags: ['unit']);

    test('a missing directory fails rather than throwing', () async {
      final snp = await uploaded();
      Directory(snp.folder).deleteSync(recursive: true);
      await service.settleUpload(session, snp);
      expect((await reload(snp)).status, SnpImportStatus.failed);
    }, tags: ['unit']);
  });

  withServerpod('SnpEndpoint upload flow', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();

    test('createUpload makes a pending row with its own directory', () async {
      final root = createTempDir('flumip_create');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');

      final snp = await endpoints.snp.createUpload(
        sessionBuilder,
        CustomSnpRequestDto(
          name: 'my panel',
          genomeId: genome.id!,
          private: true,
        ),
      );

      expect(snp.status, SnpImportStatus.pending);
      expect(snp.custom, isTrue);
      expect(snp.genome, genome.id);
      // The path is derived from the row id, so nothing a user typed can reach it.
      expect(snp.folder, '${root.path}/user/${snp.id}');
      expect(Directory(snp.folder).existsSync(), isTrue);
    }, tags: ['integration']);

    test('createUpload refuses an empty name and an unknown genome', () async {
      final root = createTempDir('flumip_create');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');

      await expectLater(
        endpoints.snp.createUpload(
          sessionBuilder,
          CustomSnpRequestDto(name: ' ', genomeId: genome.id!, private: true),
        ),
        throwsA(isA<ArgumentException>()),
      );
      await expectLater(
        endpoints.snp.createUpload(
          sessionBuilder,
          CustomSnpRequestDto(name: 'x', genomeId: -1, private: true),
        ),
        throwsA(isA<FlumipFileNotFoundException>()),
      );
    }, tags: ['integration']);

    test('the whole flow: create, place files, finish', () async {
      final root = createTempDir('flumip_flow');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');

      final created = await endpoints.snp.createUpload(
        sessionBuilder,
        CustomSnpRequestDto(
          name: 'my panel',
          genomeId: genome.id!,
          private: true,
        ),
      );
      // Stands in for what the PUT route writes.
      File('${created.folder}/panel.vcf.gz').writeAsBytesSync(completeBgzf());
      File('${created.folder}/panel.vcf.gz.tbi').writeAsStringSync('index');

      final finished =
          await endpoints.snp.finishUpload(sessionBuilder, created.id!);

      expect(finished.status, SnpImportStatus.ready);
      expect(finished.tbiPath, '${created.folder}/panel.vcf.gz.tbi');
    }, tags: ['integration']);

    test('cancelUpload removes a pending row and its directory', () async {
      final root = createTempDir('flumip_cancel');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');
      final created = await endpoints.snp.createUpload(
        sessionBuilder,
        CustomSnpRequestDto(name: 'x', genomeId: genome.id!, private: true),
      );

      await endpoints.snp.cancelUpload(sessionBuilder, created.id!);

      expect(await Snp.db.findById(session, created.id!), isNull);
      expect(Directory(created.folder).existsSync(), isFalse);
    }, tags: ['integration']);

    test('cancelUpload refuses an SNP that is already ready', () async {
      // It must not double as a delete without confirmation.
      final root = createTempDir('flumip_cancel');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final snp = await seedSnp(session, custom: true, folder: root.path);

      await expectLater(
        endpoints.snp.cancelUpload(sessionBuilder, snp.id!),
        throwsA(isA<ArgumentException>()),
      );
      expect(await Snp.db.findById(session, snp.id!), isNotNull);
    }, tags: ['integration']);

    test('finishUpload refuses a global SNP', () async {
      final root = createTempDir('flumip_flow');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final global = await seedSnp(session, name: 'dbsnp');
      await expectLater(
        endpoints.snp.finishUpload(sessionBuilder, global.id!),
        throwsA(isA<ProjectAccessDeniedException>()),
      );
    }, tags: ['integration']);
  });
}
