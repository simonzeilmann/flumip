import 'dart:typed_data';

import 'package:flumip_server/src/services/snp_service.dart';
import 'package:test/test.dart';

/// Pure tests for the three static helpers on [SnpService]. No database, no
/// filesystem, no server — these are string and byte predicates.
///
/// [SnpService.snpUploadFileKind] is the one that matters most: it is the gate an
/// uploaded filename passes through, and unlike the download guard it cannot fall
/// back on checking where a file resolved to, because the file does not exist yet.
void main() {
  group('snpUploadFileKind: accepted names', () {
    test('a plain bgzip VCF', () {
      expect(SnpService.snpUploadFileKind('panel.vcf.gz'), SnpFileKind.vcf);
    });

    test('its tabix index', () {
      expect(SnpService.snpUploadFileKind('panel.vcf.gz.tbi'), SnpFileKind.tbi);
    });

    test('dots, dashes and underscores inside the stem', () {
      expect(
        SnpService.snpUploadFileKind('00-common_all.v1.5.vcf.gz'),
        SnpFileKind.vcf,
      );
    });

    test('the longer suffix wins over the shorter one', () {
      // `.vcf.gz.tbi` does not end with `.vcf.gz`, but getting this backwards
      // would file every index as a VCF and leave the real one unindexed.
      expect(
        SnpService.snpUploadFileKind('x.vcf.gz.tbi'),
        isNot(SnpFileKind.vcf),
      );
    });
  });

  group('snpUploadFileKind: traversal', () {
    // The four rejections FileService.resolveProjectFile makes, applied before
    // anything is created rather than after.
    for (final name in [
      '',
      '.',
      '..',
      '../../etc/passwd',
      '/etc/passwd',
      'sub/panel.vcf.gz',
      r'sub\panel.vcf.gz',
      '..panel.vcf.gz',
      'a..b.vcf.gz',
    ]) {
      test('refuses "$name"', () {
        expect(SnpService.snpUploadFileKind(name), isNull);
      });
    }
  });

  group('snpUploadFileKind: names that are not SNP files', () {
    for (final name in [
      'panel.vcf', // not compressed
      'panel.gz', // compressed, but not a VCF
      'panel.tbi', // an index with no VCF name in front of it
      'panel.vcf.gz.part', // a half-finished upload
      'panel.vcf.gz.txt',
      'README.md',
      'panel.VCF.GZ', // case matters; tabix and mipgen both expect lowercase
    ]) {
      test('refuses "$name"', () {
        expect(SnpService.snpUploadFileKind(name), isNull);
      });
    }
  });

  group('snpUploadFileKind: hostile names', () {
    test('refuses a NUL byte', () {
      expect(SnpService.snpUploadFileKind('panel\u0000.vcf.gz'), isNull);
    });

    test('refuses a newline', () {
      expect(SnpService.snpUploadFileKind('panel\n.vcf.gz'), isNull);
    });

    test('refuses spaces', () {
      expect(SnpService.snpUploadFileKind('my panel.vcf.gz'), isNull);
    });

    test('refuses non-ASCII', () {
      expect(SnpService.snpUploadFileKind('pänel.vcf.gz'), isNull);
    });

    test('refuses a leading dot or dash', () {
      // A leading dash can be read as an option by anything that later takes
      // this path on a command line; a leading dot hides the file.
      expect(SnpService.snpUploadFileKind('.panel.vcf.gz'), isNull);
      expect(SnpService.snpUploadFileKind('-panel.vcf.gz'), isNull);
    });

    test('refuses an absurdly long name', () {
      expect(SnpService.snpUploadFileKind('${'a' * 200}.vcf.gz'), isNull);
    });

    test('refuses an empty stem', () {
      expect(SnpService.snpUploadFileKind('.vcf.gz'), isNull);
    });
  });

  group('looksLikeBgzf', () {
    /// A real BGZF header: gzip magic, FEXTRA set, and a `BC` subfield.
    Uint8List bgzf() => Uint8List.fromList([
      0x1f, 0x8b, 0x08, 0x04, // magic, deflate, FEXTRA
      0, 0, 0, 0, // mtime
      0, 0xff, // xfl, os
      6, 0, // xlen
      0x42, 0x43, // "BC"
      2, 0, // subfield length
    ]);

    test('accepts a BGZF header', () {
      expect(SnpService.looksLikeBgzf(bgzf()), isTrue);
    });

    test('rejects a plain gzip header', () {
      // The commonest mistake by far: `gzip file.vcf` instead of `bgzip`. tabix
      // fails on it with a message nobody should have to decode, so this is
      // sniffed first and answered in words.
      final plain = bgzf()..[3] = 0x00; // FEXTRA cleared
      expect(SnpService.looksLikeBgzf(plain), isFalse);
    });

    test('rejects gzip with an extra field that is not BC', () {
      final other = bgzf()
        ..[12] = 0x5a
        ..[13] = 0x5a;
      expect(SnpService.looksLikeBgzf(other), isFalse);
    });

    test('rejects an uncompressed VCF', () {
      expect(
        SnpService.looksLikeBgzf('##fileformat=VCFv4.2\n'.codeUnits),
        isFalse,
      );
    });

    test('rejects a file too short to have a header', () {
      expect(SnpService.looksLikeBgzf([0x1f, 0x8b]), isFalse);
      expect(SnpService.looksLikeBgzf([]), isFalse);
    });
  });
}
