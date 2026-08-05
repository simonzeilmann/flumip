import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// Is this VCF actually all here?
///
/// ⚠️ **The case these exist for.** A bgzip file missing only its final 28-byte
/// EOF block is not detectably broken by the obvious checks: `tabix` indexes it,
/// **exits 0**, writes a valid `.tbi`, answers queries for the records it does
/// have, and mentions the truncation only as a *warning on stderr*. Checking the
/// exit code and whether an index appeared — which is all this service used to do
/// — passes it every time. The SNP set is then marked ready and the first sign of
/// trouble is mipgen failing on it minutes later.
final fake = FakeProcessRunner();

/// A minimal valid BGZF file: a header, no records, and the EOF block.
List<int> completeBgzf() => [
      // One empty BGZF member, which is exactly the EOF marker's shape.
      ...SnpService.bgzfEofMarker,
    ];

void main() {
  group('hasBgzfEofMarker', () {
    test('accepts the real marker', () {
      expect(SnpService.hasBgzfEofMarker(SnpService.bgzfEofMarker), isTrue);
    });

    test('rejects a tail of the wrong length', () {
      expect(SnpService.hasBgzfEofMarker([]), isFalse);
      expect(
        SnpService.hasBgzfEofMarker(SnpService.bgzfEofMarker.sublist(1)),
        isFalse,
      );
    });

    test('rejects a tail that differs by one byte', () {
      final off = [...SnpService.bgzfEofMarker]..[20] = 0x99;
      expect(SnpService.hasBgzfEofMarker(off), isFalse);
    });

    test('rejects ordinary compressed data', () {
      expect(
        SnpService.hasBgzfEofMarker(List.filled(28, 0x78)),
        isFalse,
      );
    });
  });

  withServerpod('SnpService.vcfProblem', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final service = SnpService();

    File write(String name, List<int> bytes) {
      final dir = createTempDir('flumip_vcf');
      return File('${dir.path}/$name')..writeAsBytesSync(bytes);
    }

    test('a complete bgzip file is accepted', () async {
      expect(await service.vcfProblem(write('x.vcf.gz', completeBgzf())),
          isNull);
    }, tags: ['unit']);

    test('a file missing only its EOF marker is refused', () async {
      // The whole point: nothing else catches this.
      final truncated = [
        ...completeBgzf(),
        ...List.filled(200, 0x78),
      ];
      final problem =
          await service.vcfProblem(write('x.vcf.gz', truncated));
      expect(problem, isNotNull);
      expect(problem, contains('incomplete'));
      expect(problem, contains('did not finish'));
    }, tags: ['unit']);

    test('a plain gzip file is refused, with the bgzip command', () async {
      final plainGzip = [...completeBgzf()]..[3] = 0x00; // FEXTRA cleared
      final problem = await service.vcfProblem(write('x.vcf.gz', plainGzip));
      expect(problem, contains('bgzip'));
    }, tags: ['unit']);

    test('a file too short to hold a marker is refused', () async {
      expect(await service.vcfProblem(write('x.vcf.gz', [0x1f, 0x8b])),
          isNotNull);
    }, tags: ['unit']);

    test('a missing file is refused rather than throwing', () async {
      final dir = createTempDir('flumip_vcf');
      expect(await service.vcfProblem(File('${dir.path}/absent.vcf.gz')),
          isNotNull);
    }, tags: ['unit']);
  });

  withServerpod('completeness is checked on every path', (
    sessionBuilder,
    endpoints,
  ) {
    setup(processRunner: fake);
    setUp(fake.reset);
    final session = sessionBuilder.build();
    final service = SnpService();

    /// An SNP whose directory holds a VCF of the given bytes, and optionally an
    /// index beside it.
    Future<Snp> uploaded(List<int> vcfBytes, {bool withTbi = false}) async {
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
      File('${dir.path}/panel.vcf.gz').writeAsBytesSync(vcfBytes);
      if (withTbi) {
        File('${dir.path}/panel.vcf.gz.tbi').writeAsStringSync('index');
      }
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);
      return snp;
    }

    final truncated = [...completeBgzf(), ...List.filled(200, 0x78)];

    test('an uploaded truncated VCF is refused even when an index came with it',
        () async {
      // ⚠️ The exact hole. With an index present tabix never runs, so this was
      // the one path where absolutely nothing looked at the bytes — two files
      // being present was the entire test.
      final snp = await uploaded(truncated, withTbi: true);

      await service.settleUpload(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('incomplete'));
    }, tags: ['unit']);

    test('an uploaded truncated VCF is refused before tabix is asked', () async {
      final snp = await uploaded(truncated);

      await service.settleUpload(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('incomplete'));
      expect(
        fake.runCalls.where((c) => c.executable == 'tabix'),
        isEmpty,
        reason: 'tabix would have indexed it happily and exited 0',
      );
    }, tags: ['unit']);

    test('a complete uploaded VCF with its index is accepted', () async {
      final snp = await uploaded(completeBgzf(), withTbi: true);
      await service.settleUpload(session, snp);
      expect((await Snp.db.findById(session, snp.id!))!.status,
          SnpImportStatus.ready);
    }, tags: ['unit']);

    test('buildTabixIndex refuses a truncated VCF', () async {
      final snp = await uploaded(truncated);
      snp.vcfPath = '${snp.folder}/panel.vcf.gz';
      await Snp.db.updateRow(session, snp);

      await service.buildTabixIndex(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('incomplete'));
      expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
    }, tags: ['unit']);
  });
}
