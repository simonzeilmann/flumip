import 'package:flumip_flutter/snp/snp_validation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure string checks, and where most of the actual defects in a form like this
/// live. Note these are conveniences, not a security boundary — the server
/// re-validates every address and resolves it before fetching anything.
void main() {
  group('validateVcfUrl', () {
    test('accepts a real dbSNP address', () {
      expect(
        validateVcfUrl(
          'https://ftp.ncbi.nlm.nih.gov/snp/organisms/'
          'human_9606/VCF/00-common_all.vcf.gz',
        ),
        isNull,
      );
    });

    test('accepts http', () {
      expect(validateVcfUrl('http://hgdownload.soe.ucsc.edu/x.vcf.gz'), isNull);
    });

    test('accepts a query string after the path', () {
      // Common on generated download links; it must not defeat the suffix check.
      expect(validateVcfUrl('https://x.org/a.vcf.gz?token=abc'), isNull);
    });

    test('requires an address', () {
      expect(validateVcfUrl(''), isNotNull);
      expect(validateVcfUrl('   '), isNotNull);
    });

    test('rejects a missing scheme', () {
      expect(validateVcfUrl('ftp.ncbi.nlm.nih.gov/x.vcf.gz'), isNotNull);
    });

    test('rejects ftp, and says why', () {
      final message = validateVcfUrl('ftp://ftp.ncbi.nlm.nih.gov/x.vcf.gz');
      expect(message, isNotNull);
      expect(message, contains('https'));
    });

    test('rejects file:', () {
      expect(validateVcfUrl('file:///etc/passwd'), isNotNull);
    });

    test('rejects credentials in the address', () {
      expect(validateVcfUrl('https://u:p@x.org/a.vcf.gz'), isNotNull);
    });

    test('rejects a wrong extension', () {
      expect(validateVcfUrl('https://x.org/a.zip'), isNotNull);
      expect(validateVcfUrl('https://x.org/a.vcf.gz.tbi'), isNotNull);
      expect(validateVcfUrl('https://x.org/'), isNotNull);
    });

    test('matching the extension ignores case', () {
      expect(validateVcfUrl('https://x.org/A.VCF.GZ'), isNull);
    });
  });

  group('validateTbiUrl', () {
    test('is optional', () {
      expect(validateTbiUrl(''), isNull);
      expect(validateTbiUrl('   '), isNull);
    });

    test('accepts a matching index address', () {
      expect(validateTbiUrl('https://x.org/a.vcf.gz.tbi'), isNull);
    });

    test('rejects a plain .vcf.gz in the index field', () {
      // Pasting the same address twice is the mistake this catches.
      expect(validateTbiUrl('https://x.org/a.vcf.gz'), isNotNull);
    });

    test('rejects a bad scheme', () {
      expect(validateTbiUrl('ftp://x.org/a.vcf.gz.tbi'), isNotNull);
    });
  });

  group('suggestTbiUrl', () {
    test('appends .tbi to a valid VCF address', () {
      expect(
        suggestTbiUrl('https://x.org/a.vcf.gz'),
        'https://x.org/a.vcf.gz.tbi',
      );
    });

    test('trims first', () {
      expect(
        suggestTbiUrl('  https://x.org/a.vcf.gz  '),
        'https://x.org/a.vcf.gz.tbi',
      );
    });

    test('suggests nothing for an address that is not usable', () {
      // No point offering a suggestion built on something already wrong.
      expect(suggestTbiUrl(''), isNull);
      expect(suggestTbiUrl('not a url'), isNull);
      expect(suggestTbiUrl('https://x.org/a.zip'), isNull);
      expect(suggestTbiUrl('ftp://x.org/a.vcf.gz'), isNull);
    });
  });

  group('validateVcfName', () {
    test('accepts a bgzip VCF', () {
      expect(validateVcfName('00-common_all.vcf.gz'), isNull);
    });

    test('an uncompressed .vcf gets the bgzip command, not a shrug', () {
      // The commonest mistake, and the one place a message can save somebody
      // twenty minutes.
      final message = validateVcfName('panel.vcf');
      expect(message, isNotNull);
      expect(message, contains('bgzip'));
    });

    test('rejects anything else', () {
      expect(validateVcfName(''), isNotNull);
      expect(validateVcfName('panel.gz'), isNotNull);
      expect(validateVcfName('panel.vcf.gz.tbi'), isNotNull);
    });
  });

  group('validateTbiName', () {
    test('is optional and accepts an index', () {
      expect(validateTbiName(''), isNull);
      expect(validateTbiName('panel.vcf.gz.tbi'), isNull);
    });

    test('rejects a non-index', () {
      expect(validateTbiName('panel.vcf.gz'), isNotNull);
      expect(validateTbiName('panel.tbi'), isNotNull);
    });
  });
}
