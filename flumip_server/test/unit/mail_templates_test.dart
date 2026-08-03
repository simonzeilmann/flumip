import 'package:flumip_server/src/services/mail_templates.dart';
import 'package:test/test.dart';

/// No `withServerpod`: these are pure functions, so the whole file runs in
/// milliseconds without a database. `auth_config_test.dart` is the model.
void main() {
  ProjectMailDetails success({
    String name = 'BRCA panel',
    Duration? completedIn = const Duration(minutes: 4, seconds: 9),
    int sizeBytes = 2400000000,
    String? genomeName = 'hg38',
    String? snpName = 'common',
    int geneCount = 3,
    String? siteUrl,
  }) =>
      ProjectMailDetails(
        projectName: name,
        failed: false,
        completedIn: completedIn,
        sizeBytes: sizeBytes,
        genomeName: genomeName,
        snpName: snpName,
        geneCount: geneCount,
        siteUrl: siteUrl,
      );

  ProjectMailDetails failure({String error = 'bwa exited with code 1'}) =>
      ProjectMailDetails(
        projectName: 'BRCA panel',
        failed: true,
        error: error,
        completedIn: const Duration(seconds: 12),
      );

  group('formatBytes', () {
    test('scales rather than assuming a unit', () {
      // The UI says GB; the mail used to print raw bytes for the same number.
      expect(formatBytes(2400000000), '2.40 GB');
      expect(formatBytes(4500000), '4.50 MB');
      expect(formatBytes(912), '912 bytes');
      expect(formatBytes(0), '0 bytes');
    });

    test('drops decimals as the number grows', () {
      expect(formatBytes(123400000000), '123 GB');
      expect(formatBytes(12340000000), '12.3 GB');
    });
  });

  group('formatDuration', () {
    test('is readable rather than Duration.toString()', () {
      // Which would be 0:04:09.000000, microseconds and all.
      expect(formatDuration(const Duration(minutes: 4, seconds: 9)),
          '4 min 09 s');
      expect(formatDuration(const Duration(seconds: 9)), '9 s');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 4, seconds: 9)),
        '1 h 04 min 09 s',
      );
    });

    test('says so when there is no duration', () {
      expect(formatDuration(null), 'unknown');
    });
  });

  group('subject', () {
    test('distinguishes success from failure', () {
      expect(buildSubject(success()), contains('finished'));
      expect(buildSubject(success()), contains('BRCA panel'));
      expect(buildSubject(failure()), contains('failed'));
    });
  });

  group('the text part', () {
    test('carries the run detail', () {
      final body = buildTextBody(success());
      expect(body, contains('finished successfully'));
      expect(body, contains('hg38'));
      expect(body, contains('common'));
      expect(body, contains('3 genes'));
      expect(body, contains('4 min 09 s'));
      expect(body, contains('2.40 GB'));
    });

    test('says why it failed, and that the project survived', () {
      final body = buildTextBody(failure());
      expect(body, contains('failed'));
      expect(body, contains('bwa exited with code 1'));
      expect(body, contains('still there'));
      // Output size is meaningless on a failure and would imply something
      // usable came out.
      expect(body, isNot(contains('Output size')));
    });

    test('copes with a failure that recorded no reason', () {
      expect(buildTextBody(failure(error: '')),
          contains('No error message was recorded'));
    });

    test('singularises one gene', () {
      expect(buildTextBody(success(geneCount: 1)), contains('1 gene'));
      expect(buildTextBody(success(geneCount: 1)), isNot(contains('1 genes')));
    });

    test('omits what the project does not have', () {
      final body = buildTextBody(
        success(genomeName: null, snpName: null, geneCount: 0),
      );
      expect(body, isNot(contains('Genome')));
      expect(body, isNot(contains('SNP set')));
      expect(body, isNot(contains('Genes')));
      expect(body, contains('BRCA panel'));
    });

    test('links back only when a public URL is configured', () {
      expect(buildTextBody(success()), isNot(contains('Open FLUMIP')));
      expect(
        buildTextBody(success(siteUrl: 'https://flumip.uni.example')),
        contains('https://flumip.uni.example'),
      );
    });
  });

  group('the test email', () {
    const details = TestMailDetails(
      smtpServer: 'smtp.uni.example',
      smtpPort: 587,
      from: 'flumip@uni.example',
      startTLS: true,
    );

    test('reports the SMTP settings it went out with', () async {
      // Which is the thing an administrator is trying to confirm.
      for (final part in [
        buildTestTextBody(details),
        buildTestHtmlBody(details),
      ]) {
        expect(part, contains('smtp.uni.example:587'));
        expect(part, contains('flumip@uni.example'));
        expect(part, contains('on'));
      }
    });

    test('says STARTTLS is off when it is', () {
      const insecure = TestMailDetails(
        smtpServer: 'mail.local',
        smtpPort: 25,
        from: 'flumip@local',
        startTLS: false,
      );
      expect(buildTestTextBody(insecure), contains('off'));
    });

    test('shares the chrome with a real notification', () {
      // The point of using the template here: what an admin sees in the test
      // mail is what a user will get, so a layout problem is found now.
      final test = buildTestHtmlBody(details);
      final real = buildHtmlBody(success());
      expect(test, startsWith('<!doctype html>'));
      for (final marker in ['max-width:560px', 'border-radius:8px']) {
        expect(test, contains(marker));
        expect(real, contains(marker));
      }
      // A different accent, because it reports no outcome.
      expect(test, contains(colourNeutral));
      expect(test, isNot(contains(colourSuccess)));
    });

    test('has its own footer, not the project one', () {
      expect(buildTestTextBody(details), contains('Send test email'));
      expect(buildTestTextBody(details), isNot(contains('you own this')));
    });
  });

  group('the HTML part', () {
    test('is a complete document carrying the same facts', () {
      final html = buildHtmlBody(success());
      expect(html, startsWith('<!doctype html>'));
      expect(html, contains('hg38'));
      expect(html, contains('2.40 GB'));
      expect(html, contains('4 min 09 s'));
    });

    test('loads nothing external', () {
      // No images, fonts or stylesheets: the mail renders offline and cannot
      // report whether it was opened.
      final html = buildHtmlBody(success(siteUrl: 'https://flumip.uni.example'));
      expect(html, isNot(contains('<img')));
      expect(html, isNot(contains('<link')));
      expect(html, isNot(contains('src=')));
    });

    test('colours failure differently and shows the error', () {
      expect(buildHtmlBody(failure()), contains('bwa exited with code 1'));
      expect(buildHtmlBody(failure()), contains('#b3261e'));
      expect(buildHtmlBody(success()), contains('#1e6b3a'));
    });

    test('escapes interpolated values', () {
      // A project name or an error message can contain anything a tool printed;
      // unescaped it would break the layout at best.
      final html = buildHtmlBody(
        ProjectMailDetails(
          projectName: '<b>panel</b> & "quoted"',
          failed: true,
          error: '<script>alert(1)</script>',
        ),
      );
      expect(html, contains('&lt;b&gt;panel&lt;/b&gt; &amp; &quot;quoted&quot;'));
      expect(html, contains('&lt;script&gt;'));
      expect(html, isNot(contains('<script>')));
    });
  });
}
