import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/snp_downloader.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/fake_snp_downloader.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// [SnpService] with the future-call scheduling stubbed out, so the import can be
/// driven directly without the future-call machinery the test harness does not
/// run. Same trick as `NoScheduleGenomeService`.
class NoScheduleSnpService extends SnpService {
  final scheduled = <int>[];

  @override
  Future<void> scheduleSnpImport(Session session, Snp snp) async {
    scheduled.add(snp.id!);
  }
}

final fake = FakeProcessRunner();
final downloader = FakeSnpDownloader();

/// The BGZF header `buildTabixIndex` sniffs for before running tabix.
final bgzfHeader = [
  0x1f, 0x8b, 0x08, 0x04, //
  0, 0, 0, 0, //
  0, 0xff, //
  6, 0, //
  0x42, 0x43, //
  2, 0, //
  0, 0,
];

void main() {
  withServerpod('SnpService.runImport', (sessionBuilder, endpoints) {
    setup(processRunner: fake, snpDownloader: downloader);
    setUp(() {
      fake.reset();
      downloader.reset();
    });
    final session = sessionBuilder.build();

    /// A pending URL import, with its directory made and customSnpDir pointed at
    /// a temp tree.
    Future<Snp> pendingImport({
      String vcfUrl = 'https://example.org/panel.vcf.gz',
      String? tbiUrl,
    }) async {
      final root = createTempDir('flumip_import');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final genome = await seedGenome(session, name: 'hg38');
      final snp = await seedSnp(
        session,
        name: 'imported',
        genome: genome.id,
        custom: true,
        status: SnpImportStatus.pending,
        vcfPath: '',
        tbiPath: '',
        folder: '',
      );
      final dir = Directory('${root.path}/user/${snp.id}')
        ..createSync(recursive: true);
      snp
        ..folder = dir.path
        ..sourceVcfUrl = vcfUrl
        ..sourceTbiUrl = tbiUrl;
      await Snp.db.updateRow(session, snp);
      return snp;
    }

    Future<Snp> reload(Snp snp) async =>
        (await Snp.db.findById(session, snp.id!))!;

    group('the happy path', () {
      test('a VCF and its index need no tabix run', () async {
        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        final done = await reload(snp);
        expect(done.status, SnpImportStatus.ready);
        expect(done.vcfPath, endsWith('/panel.vcf.gz'));
        expect(done.tbiPath, endsWith('/panel.vcf.gz.tbi'));
        expect(done.size, greaterThan(0));
        expect(
          fake.runCalls.where((c) => c.executable == 'tabix'),
          isEmpty,
          reason: 'an index was supplied, so there is nothing to build',
        );
      }, tags: ['unit']);

      test('a VCF with no index URL is handed to tabix with a fixed argv',
          () async {
        final snp = await pendingImport();
        fake.stubRun('tabix', exitCode: 0);

        await NoScheduleSnpService().runImport(session, snp.id!);

        final call = fake.runCalls.firstWhere((c) => c.executable == 'tabix');
        expect(call.arguments.first, '-p');
        expect(call.arguments[1], 'vcf');
        expect(call.arguments[2], endsWith('/panel.vcf.gz'));
        expect(
          call.runInShell,
          isFalse,
          reason: 'no shell is interposed for this one, unlike bwa and mipgen',
        );
      }, tags: ['unit']);

      test('tabix claiming success without writing an index is a failure',
          () async {
        // The fake runner writes no files, which is exactly the case worth
        // pinning: a zero exit code is not evidence the index exists, and
        // trusting it would mark an unusable SNP set ready.
        final snp = await pendingImport();
        fake.stubRun('tabix', exitCode: 0);

        await NoScheduleSnpService().runImport(session, snp.id!);

        final done = await reload(snp);
        expect(done.status, SnpImportStatus.failed);
        expect(done.statusMessage, contains('wrote no index'));
      }, tags: ['unit']);

      test('the partial file is renamed into place, not left in .incoming',
          () async {
        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        expect(File('${snp.folder}/panel.vcf.gz').existsSync(), isTrue);
        expect(
          Directory('${snp.folder}/${SnpService.incomingDirName}').existsSync(),
          isFalse,
          reason: 'the staging directory is cleaned up in a finally',
        );
      }, tags: ['unit']);
    });

    group('progress', () {
      test('byte counts are persisted as they arrive', () async {
        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );
        downloader.stub(
          'https://example.org/panel.vcf.gz',
          bytes: 1000,
          progress: [(250, 1000), (750, 1000)],
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        // The last write wins, and the final call reports completion.
        final done = await reload(snp);
        expect(done.bytesDownloaded, greaterThan(0));
      }, tags: ['unit']);

      test('a server that sent no length leaves totalBytes at zero', () async {
        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );
        downloader.stub(
          'https://example.org/panel.vcf.gz',
          bytes: 500,
          progress: [(100, null)],
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        // Zero is what the app reads as "unknown", and it draws an
        // indeterminate bar rather than one stuck at nothing.
        expect((await reload(snp)).status, SnpImportStatus.ready);
      }, tags: ['unit']);
    });

    group('failure', () {
      test('a refused download fails the row with the downloader\'s words',
          () async {
        final snp = await pendingImport();
        downloader.stub(
          'https://example.org/panel.vcf.gz',
          error: SnpDownloadException('That address answered 404 (not found).'),
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        final done = await reload(snp);
        expect(done.status, SnpImportStatus.failed);
        expect(done.statusMessage, contains('404'));
      }, tags: ['unit']);

      test('an unexpected error does not leak its detail into the status',
          () async {
        // ⚠️ A remote error page can contain anything at all, and this string is
        // rendered in the app. Only SnpDownloadException carries text meant for
        // a person.
        final snp = await pendingImport();
        downloader.stub(
          'https://example.org/panel.vcf.gz',
          error: StateError('SocketException: connection reset by 10.0.0.5'),
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        final done = await reload(snp);
        expect(done.status, SnpImportStatus.failed);
        expect(done.statusMessage, 'The import failed unexpectedly.');
        expect(done.statusMessage, isNot(contains('10.0.0.5')));
      }, tags: ['unit']);

      test('a failed download leaves nothing in .incoming', () async {
        final snp = await pendingImport();
        downloader.stub(
          'https://example.org/panel.vcf.gz',
          error: SnpDownloadException('nope'),
        );

        await NoScheduleSnpService().runImport(session, snp.id!);

        expect(
          Directory('${snp.folder}/${SnpService.incomingDirName}').existsSync(),
          isFalse,
        );
      }, tags: ['unit']);

      test('a row with no source address fails rather than hanging', () async {
        final snp = await pendingImport();
        snp.sourceVcfUrl = null;
        await Snp.db.updateRow(session, snp);

        await NoScheduleSnpService().runImport(session, snp.id!);

        expect((await reload(snp)).status, SnpImportStatus.failed);
      }, tags: ['unit']);
    });

    group('guards', () {
      test('a row that is not pending is left alone', () async {
        // Protects against a double-schedule, and against a retry racing the
        // original import.
        final snp = await pendingImport();
        snp.status = SnpImportStatus.ready;
        await Snp.db.updateRow(session, snp);

        await NoScheduleSnpService().runImport(session, snp.id!);

        expect(downloader.invocations, isEmpty);
        expect((await reload(snp)).status, SnpImportStatus.ready);
      }, tags: ['unit']);

      test('a row deleted while queued is not resurrected', () async {
        final snp = await pendingImport();
        await Snp.db.deleteRow(session, snp);

        await NoScheduleSnpService().runImport(session, snp.id!);

        expect(await Snp.db.findById(session, snp.id!), isNull);
        expect(downloader.invocations, isEmpty);
      }, tags: ['unit']);

      test('the allowlist is passed through to the downloader', () async {
        final root = createTempDir('flumip_import');
        await overrideSettingsDirs(session, customSnpDir: root.path);
        final settings = await Settings.db.findFirstRow(session);
        settings!.snpSourceAllowedHosts = 'ftp.ncbi.nlm.nih.gov, example.org';
        await Settings.db.updateRow(session, settings);

        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );
        await NoScheduleSnpService().runImport(session, snp.id!);

        expect(
          downloader.invocations.first.allowedHosts,
          ['ftp.ncbi.nlm.nih.gov', 'example.org'],
        );
      }, tags: ['unit']);

      test('the byte cap is passed through to the downloader', () async {
        final snp = await pendingImport(
          tbiUrl: 'https://example.org/panel.vcf.gz.tbi',
        );
        await NoScheduleSnpService().runImport(session, snp.id!);
        expect(
          downloader.invocations.first.maxBytes,
          SnpService.maxImportBytes,
        );
      }, tags: ['unit']);
    });

    group('fileNameFromUrl', () {
      test('takes the name from a plain URL', () {
        expect(
          SnpService.fileNameFromUrl('https://x.org/a/b/00-common_all.vcf.gz'),
          '00-common_all.vcf.gz',
        );
      });

      test('refuses a name a remote server should not be able to dictate', () {
        // ⚠️ The URL's last segment goes through snpUploadFileKind, so a remote
        // redirect cannot choose where the bytes land or what they are called.
        for (final url in [
          'https://x.org/../../etc/passwd',
          'https://x.org/evil.sh',
          'https://x.org/a.vcf',
          'https://x.org/',
          'https://x.org/.vcf.gz',
          'https://x.org/a.vcf.gz.tbi',
        ]) {
          expect(SnpService.fileNameFromUrl(url), isNull, reason: url);
        }
      });
    });

    group('parseAllowedHosts', () {
      test('splits, trims and drops blanks', () {
        expect(
          SnpService.parseAllowedHosts(' a.org , b.org ,, '),
          ['a.org', 'b.org'],
        );
        expect(SnpService.parseAllowedHosts(''), isEmpty);
        expect(SnpService.parseAllowedHosts('   '), isEmpty);
      });
    });
  });

  withServerpod('SnpService.buildTabixIndex', (sessionBuilder, endpoints) {
    setup(processRunner: fake, snpDownloader: downloader);
    setUp(() {
      fake.reset();
      downloader.reset();
    });
    final session = sessionBuilder.build();

    /// An SNP with a real BGZF-headed VCF on disk and no index.
    Future<Snp> unindexed({List<int>? header}) async {
      final root = createTempDir('flumip_tabix');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      final dir = Directory('${root.path}/user/1')..createSync(recursive: true);
      final vcf = File('${dir.path}/panel.vcf.gz')
        ..writeAsBytesSync(header ?? bgzfHeader);
      return seedSnp(
        session,
        name: 'to index',
        custom: true,
        folder: dir.path,
        vcfPath: vcf.path,
        tbiPath: '',
        status: SnpImportStatus.pending,
      );
    }

    test('a plain gzip file is refused before tabix is even asked', () async {
      // ⚠️ The commonest mistake by far, and tabix's own message for it is not
      // something a biologist should have to decode. Answering in words — with
      // the bgzip command to fix it — is the whole point of sniffing first.
      final plainGzip = [...bgzfHeader]..[3] = 0x00; // FEXTRA cleared
      final snp = await unindexed(header: plainGzip);

      await SnpService().buildTabixIndex(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('bgzip'));
      expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
    }, tags: ['unit']);

    test('a non-zero exit surfaces tabix\'s own first line', () async {
      // An unsorted VCF is the second commonest failure, and tabix says so
      // itself — its words are more use than anything paraphrased.
      final snp = await unindexed();
      fake.stubRun('tabix',
          exitCode: 1,
          stderr: '[E::hts_idx_push] Unsorted positions on chr1\nmore noise');

      await SnpService().buildTabixIndex(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.failed);
      expect(done.statusMessage, contains('Unsorted positions'));
      expect(done.statusMessage, isNot(contains('more noise')));
    }, tags: ['unit']);

    test('a missing VCF fails rather than running tabix on nothing', () async {
      final snp = await unindexed();
      File(snp.vcfPath).deleteSync();

      await SnpService().buildTabixIndex(session, snp);

      expect((await Snp.db.findById(session, snp.id!))!.status,
          SnpImportStatus.failed);
      expect(fake.runCalls.where((c) => c.executable == 'tabix'), isEmpty);
    }, tags: ['unit']);

    test('success sets tbiPath, size and ready', () async {
      final snp = await unindexed();
      // Stand in for tabix by writing the index it would have written.
      fake.stubRun('tabix', exitCode: 0);
      File('${snp.vcfPath}.tbi').writeAsStringSync('index');

      await SnpService().buildTabixIndex(session, snp);

      final done = (await Snp.db.findById(session, snp.id!))!;
      expect(done.status, SnpImportStatus.ready);
      expect(done.tbiPath, '${snp.vcfPath}.tbi');
      expect(done.statusMessage, isEmpty);
      expect(done.size, greaterThan(0));
    }, tags: ['unit']);

    test('it never throws, whatever the runner does', () async {
      // It runs inside a future call, where an escaping exception is a log line
      // nobody reads instead of a status somebody can see.
      final snp = await unindexed();
      fake.runError = StateError('tabix is not installed');

      await expectLater(
        SnpService().buildTabixIndex(session, snp),
        completes,
      );
      expect((await Snp.db.findById(session, snp.id!))!.status,
          SnpImportStatus.failed);
    }, tags: ['unit']);
  });
}
