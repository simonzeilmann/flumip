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

void main() {
  group('path containment', () {
    test('normalizeAbsolutePath takes out . and .. and stray slashes', () {
      expect(
        SnpService.normalizeAbsolutePath('/data//snp/./x/'),
        '/data/snp/x',
      );
      expect(SnpService.normalizeAbsolutePath('/data/snp/x/../..'), '/data');
      expect(SnpService.normalizeAbsolutePath('/../../etc'), '/etc');
      expect(SnpService.normalizeAbsolutePath('data/snp'), isNull);
    }, tags: ['unit']);

    test('isStrictlyInside respects directory boundaries', () {
      expect(SnpService.isStrictlyInside('/data/snp/a', '/data/snp'), isTrue);
      expect(
        SnpService.isStrictlyInside('/data/snp-evil/a', '/data/snp'),
        isFalse,
      );
      expect(
        SnpService.isStrictlyInside('/data/snp-evil', '/data/snp'),
        isFalse,
      );
      expect(
        SnpService.isStrictlyInside('/data/snp', '/data/snp'),
        isFalse,
        reason: 'the root itself is every SNP set at once',
      );
      expect(SnpService.isStrictlyInside('/x', '/'), isTrue);
    }, tags: ['unit']);
  });

  withServerpod('SnpService.deleteSnp containment', (
    sessionBuilder,
    endpoints,
  ) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();
    final service = SnpService();

    /// Roots under a fresh temp dir, with something outside them to protect.
    Future<({String root, File keep})> roots() async {
      final base = createTempDir('flumip_contain');
      final root = '${base.path}/custom';
      Directory(root).createSync();
      final outside = Directory('${base.path}/custom-evil')..createSync();
      final keep = File('${outside.path}/keepme')..writeAsStringSync('x');
      await overrideSettingsDirs(
        session,
        customSnpDir: root,
        genomeDir: '${base.path}/genomes',
      );
      return (root: root, keep: keep);
    }

    for (final (what, folderOf) in [
      ('the root itself', (String root) => root),
      ('the root with a trailing slash', (String root) => '$root/'),
      ('a sibling sharing its spelling', (String root) => '$root-evil'),
      ('a way out through ..', (String root) => '$root/x/../../custom-evil'),
    ]) {
      test('refuses $what', () async {
        final r = await roots();
        final snp = await seedSnp(
          session,
          custom: true,
          folder: folderOf(r.root),
        );

        await expectLater(
          service.deleteSnp(session, snp),
          throwsA(isA<ArgumentException>()),
        );
        expect(r.keep.existsSync(), isTrue);
        expect(Directory(r.root).existsSync(), isTrue);
        expect(await Snp.db.findById(session, snp.id!), isNotNull);
      }, tags: ['unit']);
    }

    test('refuses a path through a symlinked directory leading out', () async {
      final r = await roots();
      Link('${r.root}/escape').createSync(r.keep.parent.path);
      final snp = await seedSnp(
        session,
        custom: true,
        folder: '${r.root}/escape',
      );
      // `escape` itself would be fine — deleting a link leaves its target —
      // but anything *below* it is outside the tree.
      final below = await seedSnp(
        session,
        name: 'below',
        custom: true,
        folder: '${r.root}/escape/x',
      );
      Directory('${r.keep.parent.path}/x').createSync();

      await expectLater(
        service.deleteSnp(session, below),
        throwsA(isA<ArgumentException>()),
      );
      expect(Directory('${r.keep.parent.path}/x').existsSync(), isTrue);

      await service.deleteSnp(session, snp);
      expect(r.keep.existsSync(), isTrue, reason: 'only the link went');
    }, tags: ['unit']);

    test('still deletes a set inside the tree', () async {
      final r = await roots();
      final dir = Directory('${r.root}/users/7')..createSync(recursive: true);
      final snp = await seedSnp(session, custom: true, folder: dir.path);

      await service.deleteSnp(session, snp);

      expect(dir.existsSync(), isFalse);
      expect(await Snp.db.findById(session, snp.id!), isNull);
    }, tags: ['unit']);
  });

  withServerpod('SnpService.resolveUploadTarget file cap', (
    sessionBuilder,
    endpoints,
  ) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();
    final service = SnpService();

    Future<Snp> pending() async {
      final root = createTempDir('flumip_upload_cap');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final snp = await seedSnp(
        session,
        name: 'incoming',
        custom: true,
        status: SnpImportStatus.pending,
        vcfPath: '',
        tbiPath: '',
        folder: '',
      );
      final dir = await service.createUserDirectory(session, snp.id!);
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);
      return snp;
    }

    test('a second VCF under another name is refused', () async {
      // Every `*.vcf.gz` name passed, and only the *same* name twice was
      // refused — so one set took files without end, each up to the limit.
      final snp = await pending();
      File('${snp.folder}/a.vcf.gz').writeAsStringSync('x');

      expect(
        await service.resolveUploadTarget(session, snp, 'b.vcf.gz'),
        isNull,
      );
      expect(
        await service.resolveUploadTarget(session, snp, 'a.vcf.gz.tbi'),
        isNotNull,
        reason: 'the index is the other file a set may have',
      );
      service.releaseUploadTarget(snp, 'a.vcf.gz.tbi');
    }, tags: ['unit']);

    test('a second index is refused too', () async {
      final snp = await pending();
      File('${snp.folder}/a.vcf.gz.tbi').writeAsStringSync('x');

      expect(
        await service.resolveUploadTarget(session, snp, 'b.vcf.gz.tbi'),
        isNull,
      );
    }, tags: ['unit']);

    test('two transfers of the same kind cannot run side by side', () async {
      // Neither has finished, so the directory is still empty for both.
      final snp = await pending();

      final first = await service.resolveUploadTarget(session, snp, 'a.vcf.gz');
      expect(first, isNotNull);
      expect(
        await service.resolveUploadTarget(session, snp, 'b.vcf.gz'),
        isNull,
      );

      // Released, as the route does in its `finally`, the slot is free again.
      service.releaseUploadTarget(snp, 'a.vcf.gz');
      final again = await service.resolveUploadTarget(session, snp, 'b.vcf.gz');
      expect(again, isNotNull);
      service.releaseUploadTarget(snp, 'b.vcf.gz');
    }, tags: ['unit']);
  });
}
