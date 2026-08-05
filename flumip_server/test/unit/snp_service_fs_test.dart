import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

final fake = FakeProcessRunner();

/// A valid BGZF header, so that a fixture VCF survives the sniff in
/// `buildTabixIndex` rather than being rejected as plain gzip.
final bgzfHeader = [
  0x1f, 0x8b, 0x08, 0x04, //
  0, 0, 0, 0, //
  0, 0xff, //
  6, 0, //
  0x42, 0x43, //
  2, 0, //
  0, 0,
];

/// Writes a directory that looks like a finished SNP set.
void writeSnpDir(String dir, {String stem = 'panel', bool withTbi = true}) {
  Directory(dir).createSync(recursive: true);
  File('$dir/$stem.vcf.gz')
      .writeAsBytesSync([...bgzfHeader, ...List.filled(48, 0x78)]);
  if (withTbi) File('$dir/$stem.vcf.gz.tbi').writeAsStringSync('i' * 8);
}

void main() {
  withServerpod('SnpService.collectCustomSnps', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final service = SnpService();

    /// Points customSnpDir at a fresh temp directory and returns its path.
    Future<String> useTempCustomDir() async {
      final root = createTempDir('flumip_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      return root.path;
    }

    group('discovering admin drop-ins', () {
      test('creates a row for common/<genome>/<name>/', () async {
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        writeSnpDir('$root/common/hg38/mypanel');

        await service.collectCustomSnps(session);

        final snps = await Snp.db.find(session, where: (t) => t.id > 0);
        expect(snps, hasLength(1));
        expect(snps.single.name, 'mypanel');
        expect(snps.single.custom, isTrue);
        expect(snps.single.private, isFalse, reason: 'drop-ins are shared');
        expect(snps.single.owner, isNull);
        expect(snps.single.status, SnpImportStatus.ready);
        expect(snps.single.vcfPath, '$root/common/hg38/mypanel/panel.vcf.gz');
        expect(snps.single.size, greaterThan(0));
      }, tags: ['unit']);

      test('links the SNP to the genome both ways', () async {
        final root = await useTempCustomDir();
        final genome = await seedGenome(session, name: 'hg38');
        writeSnpDir('$root/common/hg38/mypanel');

        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.genome, genome.id);
        final reloaded = await Genome.db.findById(session, genome.id!);
        expect(reloaded!.snp, contains(snp.id));
      }, tags: ['unit']);

      test('is idempotent across repeated runs', () async {
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        writeSnpDir('$root/common/hg38/mypanel');

        await service.collectCustomSnps(session);
        await service.collectCustomSnps(session);
        await service.collectCustomSnps(session);

        expect(await Snp.db.find(session, where: (t) => t.id > 0), hasLength(1));
      }, tags: ['unit']);

      test('skips a directory whose genome name matches nothing', () async {
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        writeSnpDir('$root/common/mm39/mousepanel');

        await service.collectCustomSnps(session);

        expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
      }, tags: ['unit']);

      test('ignores a directory holding only a partial upload', () async {
        // The old substring check over a stringified listing counted
        // `panel.vcf.gz.part` as a VCF, because it contains `.vcf.gz`.
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/halfdone';
        Directory(dir).createSync(recursive: true);
        File('$dir/panel.vcf.gz.part').writeAsStringSync('x');
        File('$dir/panel.vcf.gz.tbi').writeAsStringSync('i');

        await service.collectCustomSnps(session);

        expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
      }, tags: ['unit']);

      test('ignores a VCF with no index beside it', () async {
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        writeSnpDir('$root/common/hg38/noindex', withTbi: false);

        await service.collectCustomSnps(session);

        expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
      }, tags: ['unit']);

      test('does nothing at all when the tree is absent', () async {
        await overrideSettingsDirs(
          session,
          customSnpDir: '/nonexistent/flumip/custom_snp',
        );
        await service.collectCustomSnps(session);
        expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
      }, tags: ['unit']);
    });

    group('reconciling rows against disk', () {
      test('marks an SNP failed when its files are gone', () async {
        final root = await useTempCustomDir();
        final genome = await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/mypanel';
        writeSnpDir(dir);
        await service.collectCustomSnps(session);

        Directory(dir).deleteSync(recursive: true);
        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.failed);
        expect(snp.statusMessage, contains('no longer on disk'));
        expect(snp.vcfPath, isEmpty);
        // ⚠️ The row survives. Deleting it would break Project.snp, throw away
        // the description and the owner, and leave the user nothing to look at.
        expect(snp.genome, genome.id);
      }, tags: ['unit']);

      test('heals when the files come back', () async {
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/mypanel';
        writeSnpDir(dir);
        await service.collectCustomSnps(session);

        Directory(dir).deleteSync(recursive: true);
        await service.collectCustomSnps(session);
        writeSnpDir(dir);
        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.ready);
        expect(snp.vcfPath, '$dir/panel.vcf.gz');
      }, tags: ['unit']);

      test('refreshes a path and size after the files are swapped', () async {
        // The scanner only ever inserted, so a re-downloaded or renamed VCF left
        // vcfPath and size stale forever.
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/mypanel';
        writeSnpDir(dir, stem: 'v1');
        await service.collectCustomSnps(session);
        final before =
            (await Snp.db.find(session, where: (t) => t.id > 0)).single;

        Directory(dir).deleteSync(recursive: true);
        Directory(dir).createSync(recursive: true);
        File('$dir/v2.vcf.gz').writeAsStringSync('y' * 500);
        File('$dir/v2.vcf.gz.tbi').writeAsStringSync('i' * 8);
        await service.collectCustomSnps(session);

        final after =
            (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(after.id, before.id, reason: 'the same row, refreshed');
        expect(after.vcfPath, '$dir/v2.vcf.gz');
        expect(after.size, greaterThan(before.size));
      }, tags: ['unit']);

      test('rebuilds the index when only the .tbi is missing', () async {
        // Self-heal: an index deleted by hand can simply be built again, so the
        // reconcile hands the VCF to tabix rather than giving up on it.
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/mypanel';
        writeSnpDir(dir);
        await service.collectCustomSnps(session);

        File('$dir/panel.vcf.gz.tbi').deleteSync();
        fake.stubRun('tabix', exitCode: 0);
        await service.collectCustomSnps(session);

        final call = fake.runCalls.firstWhere((c) => c.executable == 'tabix');
        expect(call.arguments, ['-p', 'vcf', '$dir/panel.vcf.gz']);
        expect(call.runInShell, isFalse);
      }, tags: ['unit']);

      test('a plain gzip VCF is refused in words, without asking tabix',
          () async {
        // The commonest mistake, and tabix's own message for it is not something
        // a biologist should have to decode.
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/plaingzip';
        Directory(dir).createSync(recursive: true);
        // FEXTRA cleared: gzip, but not BGZF.
        File('$dir/panel.vcf.gz')
            .writeAsBytesSync([...bgzfHeader]..[3] = 0x00);
        File('$dir/panel.vcf.gz.tbi').writeAsStringSync('i');
        await service.collectCustomSnps(session);

        File('$dir/panel.vcf.gz.tbi').deleteSync();
        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.failed);
        expect(snp.statusMessage, contains('bgzip'));
        expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
      }, tags: ['unit']);

      test('recovers from failed once the index is put back', () async {
        // ⚠️ The regression this file exists for. `failed` was originally a state
        // the reconcile skipped over, so a row that lost its index could never
        // come back — not even after the file returned. A terminal status must
        // never mean "stop looking".
        final root = await useTempCustomDir();
        await seedGenome(session, name: 'hg38');
        final dir = '$root/common/hg38/mypanel';
        writeSnpDir(dir);
        await service.collectCustomSnps(session);

        // The index goes missing and the rebuild produces nothing, because the
        // fake runner writes no files — so the row lands in `failed`.
        File('$dir/panel.vcf.gz.tbi').deleteSync();
        fake.stubRun('tabix', exitCode: 0);
        await service.collectCustomSnps(session);
        expect(
          (await Snp.db.find(session, where: (t) => t.id > 0)).single.status,
          SnpImportStatus.failed,
        );

        File('$dir/panel.vcf.gz.tbi').writeAsStringSync('i' * 8);
        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.ready);
        expect(snp.tbiPath, '$dir/panel.vcf.gz.tbi');
      }, tags: ['unit']);

      test('leaves a running tabix job alone, but fails it once stale',
          () async {
        final root = await useTempCustomDir();
        final dir = '$root/user/1';
        Directory(dir).createSync(recursive: true);
        File('$dir/panel.vcf.gz').writeAsStringSync('x' * 64);
        final live = await seedSnp(session,
            custom: true,
            folder: dir,
            vcfPath: '$dir/panel.vcf.gz',
            tbiPath: '',
            status: SnpImportStatus.indexing,
            statusUpdated: DateTime.now().toUtc());

        await service.collectCustomSnps(session);
        expect((await Snp.db.findById(session, live.id!))!.status,
            SnpImportStatus.indexing);

        live.statusUpdated =
            DateTime.now().toUtc().subtract(SnpService.stuckImportAfter * 2);
        await Snp.db.updateRow(session, live);
        await service.collectCustomSnps(session);

        expect((await Snp.db.findById(session, live.id!))!.status,
            SnpImportStatus.failed);
      }, tags: ['unit']);

      test('leaves a row alone when its whole filesystem is missing', () async {
        // ⚠️ An unmounted NFS share must not flip every global SNP to failed,
        // and with it every project that uses one. The parent directory not
        // existing is the signal that this is a mount problem, not a deletion.
        await useTempCustomDir();
        await seedSnp(
          session,
          name: 'dbsnp',
          folder: '/definitely/not/mounted/snp/dbsnp',
          vcfPath: '/definitely/not/mounted/snp/dbsnp/x.vcf.gz',
        );

        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.ready);
        expect(snp.vcfPath, isNotEmpty);
      }, tags: ['unit']);

      test('fails an import whose heartbeat has gone stale', () async {
        await useTempCustomDir();
        await seedSnp(
          session,
          name: 'half-downloaded',
          custom: true,
          status: SnpImportStatus.downloading,
          statusUpdated: DateTime.now().toUtc().subtract(
                SnpService.stuckImportAfter * 2,
              ),
        );

        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.failed);
        expect(snp.statusMessage, contains('Interrupted'));
      }, tags: ['unit']);

      test('leaves a live import alone', () async {
        await useTempCustomDir();
        await seedSnp(
          session,
          name: 'downloading',
          custom: true,
          status: SnpImportStatus.downloading,
          statusUpdated: DateTime.now().toUtc(),
        );

        await service.collectCustomSnps(session);

        final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
        expect(snp.status, SnpImportStatus.downloading);
      }, tags: ['unit']);

      test('leaves a pending row alone', () async {
        await useTempCustomDir();
        await seedSnp(
          session,
          name: 'announced',
          custom: true,
          status: SnpImportStatus.pending,
        );

        await service.collectCustomSnps(session);

        expect(
          (await Snp.db.find(session, where: (t) => t.id > 0)).single.status,
          SnpImportStatus.pending,
        );
      }, tags: ['unit']);
    });

    group('sweeping', () {
      test('never invents a row for an orphaned user directory', () async {
        // What a create that crashed halfway leaves behind. A reconcile pass has
        // no business deleting user data it cannot account for, and no business
        // guessing a row for it either.
        final root = await useTempCustomDir();
        writeSnpDir('$root/user/999');

        await service.collectCustomSnps(session);

        expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
        expect(Directory('$root/user/999').existsSync(), isTrue);
      }, tags: ['unit']);

      test('deletes an abandoned partial upload', () async {
        final root = await useTempCustomDir();
        final snp = await seedSnp(session, custom: true);
        final incoming = Directory('$root/user/${snp.id}/.incoming')
          ..createSync(recursive: true);
        final stale = File('${incoming.path}/panel.vcf.gz.part')
          ..writeAsStringSync('x');
        stale.setLastModifiedSync(
          DateTime.now().subtract(SnpService.incomingSweepAfter * 2),
        );

        await service.collectCustomSnps(session);

        expect(stale.existsSync(), isFalse);
      }, tags: ['unit']);

      test('keeps a partial upload that is still recent', () async {
        final root = await useTempCustomDir();
        final snp = await seedSnp(session, custom: true);
        final incoming = Directory('$root/user/${snp.id}/.incoming')
          ..createSync(recursive: true);
        final fresh = File('${incoming.path}/panel.vcf.gz.part')
          ..writeAsStringSync('x');

        await service.collectCustomSnps(session);

        expect(fresh.existsSync(), isTrue);
      }, tags: ['unit']);
    });

    group('backfilling the genome link', () {
      test('links a pre-existing SNP through the old Genome.snp list', () async {
        // ⚠️ The upgrade path. Every SNP on an existing install has a null
        // `genome`, and getAllSnpForGenome now queries on that column — so
        // without this the first start after upgrading empties every picker.
        await useTempCustomDir();
        final snp = await seedSnp(session, name: 'dbsnp');
        final genome =
            await seedGenome(session, name: 'hg38', snp: [snp.id!]);

        await service.backfillGenomeLinks(session);

        final reloaded = await Snp.db.findById(session, snp.id!);
        expect(reloaded!.genome, genome.id);
      }, tags: ['unit']);

      test('leaves an SNP no genome claims alone', () async {
        await useTempCustomDir();
        final snp = await seedSnp(session, name: 'orphan');
        await seedGenome(session, name: 'hg38');

        await service.backfillGenomeLinks(session);

        expect((await Snp.db.findById(session, snp.id!))!.genome, isNull);
      }, tags: ['unit']);
    });
  });

  withServerpod('SnpService.deleteSnp', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    var session = sessionBuilder.build();
    final service = SnpService();

    test('removes the files first, then the row', () async {
      final root = createTempDir('flumip_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');
      final dir = '${root.path}/common/hg38/mypanel';
      writeSnpDir(dir);
      await service.collectCustomSnps(session);
      final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;

      await service.deleteSnp(session, snp);

      expect(Directory(dir).existsSync(), isFalse);
      expect(await Snp.db.findById(session, snp.id!), isNull);
      final reloaded = await Genome.db.findById(session, genome.id!);
      expect(reloaded!.snp ?? [], isNot(contains(snp.id)));
    }, tags: ['unit']);

    test('a re-scan does not bring a deleted SNP back', () async {
      // The whole answer to resurrection: the scanner only creates a row for a
      // directory that exists and holds both files, and the directory is gone.
      final root = createTempDir('flumip_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      await seedGenome(session, name: 'hg38');
      writeSnpDir('${root.path}/common/hg38/mypanel');
      await service.collectCustomSnps(session);
      final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;

      await service.deleteSnp(session, snp);
      await service.collectCustomSnps(session);

      expect(await Snp.db.find(session, where: (t) => t.id > 0), isEmpty);
    }, tags: ['unit']);

    test('deleting an SNP releases the projects using it', () async {
      final root = createTempDir('flumip_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      await seedGenome(session, name: 'hg38');
      writeSnpDir('${root.path}/common/hg38/mypanel');
      await service.collectCustomSnps(session);
      final snp = (await Snp.db.find(session, where: (t) => t.id > 0)).single;
      final options = await seedOptions(session);
      final project =
          await seedProject(session, options: options.id!, snp: snp.id);

      await service.deleteSnp(session, snp);

      final reloaded = await Project.db.findById(session, project.id!);
      expect(reloaded!.snp, isNull, reason: 'the foreign key nulls it');
    }, tags: ['unit']);

    test('snpUsage names the projects pointing at an SNP', () async {
      final snp = await seedSnp(session, custom: true);
      final options = await seedOptions(session);
      await seedProject(session,
          name: 'Cardio panel', options: options.id!, snp: snp.id);
      await seedProject(session, name: 'Unrelated', options: options.id!);

      final usage = await service.snpUsage(session, snp.id!);

      expect(usage.map((u) => u.projectName), ['Cardio panel']);
    }, tags: ['unit']);

    test('deletes a row that never got as far as having files', () async {
      // A create that crashed before writing anything. Refusing this would leave
      // a half-made SNP nobody, not even an administrator, could clean up.
      final root = createTempDir('flumip_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final snp = await seedSnp(session, custom: true, folder: '');

      await service.deleteSnp(session, snp);

      expect(await Snp.db.findById(session, snp.id!), isNull);
    }, tags: ['unit']);

    test('refuses to delete a folder outside the allowed roots', () async {
      // Unreachable by design — `folder` is written by this code and never by a
      // user — which is exactly why it is worth pinning. A corrupted row would
      // otherwise be a recursive delete of whatever it names.
      final root = createTempDir('flumip_snp');
      final outside = createTempDir('flumip_outside');
      File('${outside.path}/keepme').writeAsStringSync('x');
      await overrideSettingsDirs(
        session,
        customSnpDir: root.path,
        genomeDir: '${root.path}/genomes',
      );
      final snp = await seedSnp(session, custom: true, folder: outside.path);

      await expectLater(
        service.deleteSnp(session, snp),
        throwsA(isA<ArgumentException>()),
      );
      expect(File('${outside.path}/keepme').existsSync(), isTrue);
      expect(await Snp.db.findById(session, snp.id!), isNotNull);
    }, tags: ['unit']);
  });
}
