import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';
import '../support/fake_snp_downloader.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';
import 'test_tools/serverpod_test_tools.dart';

final fake = FakeProcessRunner();
final downloader = FakeSnpDownloader();

/// `importFromUrls` and `retryImport` through the endpoint.
///
/// The point of most of these is that **a bad address is refused on the call**,
/// synchronously, rather than being accepted and turning up later as a `failed`
/// row somebody has to go and find. That is also what stops the endpoint being a
/// request proxy into the deployment's own network.
void main() {
  withServerpod('SnpEndpoint import', (sessionBuilder, endpoints) {
    setup(processRunner: fake, snpDownloader: downloader);
    setUp(() {
      fake.reset();
      downloader.reset();
    });
    final session = sessionBuilder.build();

    Future<Genome> withTempTree() async {
      final root = createTempDir('flumip_endpoint_snp');
      await overrideSettingsDirs(session, customSnpDir: root.path);
      return seedGenome(session, name: 'hg38');
    }

    CustomSnpRequestDto request({
      String name = 'my panel',
      required int genomeId,
      bool private = true,
      List<String>? urls,
    }) => CustomSnpRequestDto(
      name: name,
      genomeId: genomeId,
      private: private,
      urls: urls,
    );

    group('importFromUrls', () {
      test('creates a pending row with a folder and a queued status', () async {
        final genome = await withTempTree();

        final snp = await endpoints.snp.importFromUrls(
          sessionBuilder,
          request(
            genomeId: genome.id!,
            urls: ['https://ftp.ncbi.nlm.nih.gov/snp/x.vcf.gz'],
          ),
        );

        expect(snp.status, SnpImportStatus.pending);
        expect(snp.custom, isTrue);
        expect(snp.private, isTrue, reason: 'private by default');
        expect(snp.genome, genome.id);
        expect(snp.sourceVcfUrl, 'https://ftp.ncbi.nlm.nih.gov/snp/x.vcf.gz');
        // The folder is derived from the row id, so it can only be set after
        // the insert.
        expect(snp.folder, endsWith('/user/${snp.id}'));
      }, tags: ['integration']);

      test('accepts a matching index address', () async {
        final genome = await withTempTree();

        final snp = await endpoints.snp.importFromUrls(
          sessionBuilder,
          request(
            genomeId: genome.id!,
            urls: [
              'https://example.org/x.vcf.gz',
              'https://example.org/x.vcf.gz.tbi',
            ],
          ),
        );

        expect(snp.sourceTbiUrl, 'https://example.org/x.vcf.gz.tbi');
      }, tags: ['integration']);

      test('honours the sharing flag', () async {
        final genome = await withTempTree();
        final snp = await endpoints.snp.importFromUrls(
          sessionBuilder,
          request(
            genomeId: genome.id!,
            private: false,
            urls: ['https://example.org/x.vcf.gz'],
          ),
        );
        expect(snp.private, isFalse);
      }, tags: ['integration']);

      test('refuses a file: address', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(genomeId: genome.id!, urls: ['file:///etc/passwd']),
          ),
          throwsA(isA<ArgumentException>()),
        );
        expect(
          await Snp.db.find(session, where: (t) => t.id > 0),
          isEmpty,
          reason: 'nothing should have been inserted',
        );
      }, tags: ['integration']);

      test('refuses an address on a non-standard port', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: ['https://example.org:5432/x.vcf.gz'],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses an address that resolves to the loopback', () async {
        // The one somebody actually tries: point it at the server itself.
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(genomeId: genome.id!, urls: ['http://127.0.0.1/x.vcf.gz']),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses the cloud metadata address', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: ['http://169.254.169.254/latest/meta-data/x.vcf.gz'],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses a first address that is not a .vcf.gz', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(genomeId: genome.id!, urls: ['https://example.org/x.zip']),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses a second address that is not a .vcf.gz.tbi', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: [
                'https://example.org/x.vcf.gz',
                'https://example.org/notes.txt',
              ],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses more than two addresses', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: [
                'https://example.org/a.vcf.gz',
                'https://example.org/a.vcf.gz.tbi',
                'https://example.org/b.vcf.gz',
              ],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses no address at all', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(genomeId: genome.id!, urls: const []),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses an empty name', () async {
        final genome = await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              name: '   ',
              genomeId: genome.id!,
              urls: ['https://example.org/x.vcf.gz'],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('refuses an unknown genome', () async {
        await withTempTree();
        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(genomeId: -1, urls: ['https://example.org/x.vcf.gz']),
          ),
          throwsA(isA<FlumipFileNotFoundException>()),
        );
      }, tags: ['integration']);

      test('honours the allowlist', () async {
        final genome = await withTempTree();
        final settings = await Settings.db.findFirstRow(session);
        settings!.snpSourceAllowedHosts = 'ftp.ncbi.nlm.nih.gov';
        await Settings.db.updateRow(session, settings);

        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: ['https://example.org/x.vcf.gz'],
            ),
          ),
          throwsA(isA<ArgumentException>()),
        );

        await expectLater(
          endpoints.snp.importFromUrls(
            sessionBuilder,
            request(
              genomeId: genome.id!,
              urls: ['https://ftp.ncbi.nlm.nih.gov/x.vcf.gz'],
            ),
          ),
          completes,
        );
      }, tags: ['integration']);
    });

    group('retryImport', () {
      test(
        'puts a failed import back in the queue and clears its progress',
        () async {
          final genome = await withTempTree();
          final snp = await seedSnp(
            session,
            name: 'broken',
            genome: genome.id,
            custom: true,
            status: SnpImportStatus.failed,
            statusMessage: 'This address answered 404 (not found).',
          );
          snp
            ..sourceVcfUrl = 'https://example.org/x.vcf.gz'
            ..bytesDownloaded = 500
            ..totalBytes = 1000;
          await Snp.db.updateRow(session, snp);

          final retried = await endpoints.snp.retryImport(
            sessionBuilder,
            snp.id!,
          );

          expect(retried.status, SnpImportStatus.pending);
          expect(retried.bytesDownloaded, 0);
          expect(retried.totalBytes, 0);
        },
        tags: ['integration'],
      );

      test(
        're-checks the address, so a tightened allowlist takes effect',
        () async {
          // ⚠️ The reason retry re-validates rather than trusting the stored URL:
          // an administrator may have narrowed the allowlist since, and a retry
          // must not be a way around it.
          final genome = await withTempTree();
          final snp = await seedSnp(
            session,
            genome: genome.id,
            custom: true,
            status: SnpImportStatus.failed,
          );
          snp.sourceVcfUrl = 'https://example.org/x.vcf.gz';
          await Snp.db.updateRow(session, snp);

          final settings = await Settings.db.findFirstRow(session);
          settings!.snpSourceAllowedHosts = 'ftp.ncbi.nlm.nih.gov';
          await Settings.db.updateRow(session, settings);

          await expectLater(
            endpoints.snp.retryImport(sessionBuilder, snp.id!),
            throwsA(isA<ArgumentException>()),
          );
          expect(
            (await Snp.db.findById(session, snp.id!))!.status,
            SnpImportStatus.failed,
          );
        },
        tags: ['integration'],
      );

      test('refuses to retry an import that is already running', () async {
        final genome = await withTempTree();
        final snp = await seedSnp(
          session,
          genome: genome.id,
          custom: true,
          status: SnpImportStatus.downloading,
          statusUpdated: DateTime.now().toUtc(),
        );
        snp.sourceVcfUrl = 'https://example.org/x.vcf.gz';
        await Snp.db.updateRow(session, snp);

        await expectLater(
          endpoints.snp.retryImport(sessionBuilder, snp.id!),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('an upload with nothing on disk has nothing to retry', () async {
        final genome = await withTempTree();
        final snp = await seedSnp(
          session,
          genome: genome.id,
          custom: true,
          status: SnpImportStatus.failed,
          vcfPath: '',
        );

        await expectLater(
          endpoints.snp.retryImport(sessionBuilder, snp.id!),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('a global SNP cannot be retried', () async {
        await withTempTree();
        final global = await seedSnp(session, name: 'dbsnp');
        await expectLater(
          endpoints.snp.retryImport(sessionBuilder, global.id!),
          throwsA(isA<ProjectAccessDeniedException>()),
        );
      }, tags: ['integration']);
    });
  });
}
