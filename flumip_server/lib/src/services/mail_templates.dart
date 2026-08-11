/// The text of the notification emails.
///
/// Pure functions over a plain value object: no [Session], no database, no SMTP.
/// That is deliberate — wording and formatting are the parts most likely to be
/// changed, and this way they can be tested exhaustively in milliseconds
/// (`test/unit/mail_templates_test.dart`) rather than through a delivery path.
/// `AuthConfig.resolve` is the same idea.
///
/// Every message is built twice, as HTML and as plain text, and both are sent.
/// Not every client renders HTML, and some people prefer not to — a mail with
/// only an HTML part shows up empty for them.
library;

/// Everything a finished-generation email says, gathered before rendering.
///
/// Assembled by [MailService], which does the database lookups; nothing here
/// knows how to fetch anything.
class ProjectMailDetails {
  const ProjectMailDetails({
    required this.projectName,
    required this.failed,
    this.error = '',
    this.completedIn,
    this.sizeBytes = 0,
    this.genomeName,
    this.snpName,
    this.geneCount = 0,
    this.siteUrl,
  });

  final String projectName;
  final bool failed;

  /// Only meaningful when [failed]. May still be empty, if generation failed
  /// without recording a reason.
  final String error;

  final Duration? completedIn;
  final int sizeBytes;

  /// Null when the project never had one set, or the row has since gone.
  final String? genomeName;
  final String? snpName;
  final int geneCount;

  /// Public origin of this install, for a link back. Null when
  /// `Settings.authPublicUrl` is unset — which is the default, so the link
  /// simply does not appear rather than pointing somewhere wrong.
  final String? siteUrl;
}

/// `1.23 GB`, `4.5 MB`, `912 bytes`.
///
/// The UI shows GB; the emails used to print raw bytes for the same number, so
/// the same run was described two different ways. Scales instead of assuming a
/// unit, because a failed run is often kilobytes and "0.00 GB" says nothing.
String formatBytes(int bytes) {
  if (bytes < 1000) return '$bytes bytes';
  const units = ['kB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final decimals = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(decimals)} ${units[unit]}';
}

/// `1 h 04 min 09 s`, `4 min 09 s`, `9 s`.
///
/// `Duration.toString()` gives `0:03:00.000000`, microseconds included, which is
/// what these emails used to print.
String formatDuration(Duration? duration) {
  if (duration == null) return 'unknown';
  final seconds = duration.inSeconds;
  if (seconds < 60) return '$seconds s';

  final minutes = duration.inMinutes;
  final restSeconds = (seconds % 60).toString().padLeft(2, '0');
  if (minutes < 60) return '$minutes min $restSeconds s';

  final restMinutes = (minutes % 60).toString().padLeft(2, '0');
  return '${duration.inHours} h $restMinutes min $restSeconds s';
}

String buildSubject(ProjectMailDetails d) => d.failed
    ? 'FLUMIP: MIP generation failed for "${d.projectName}"'
    : 'FLUMIP: MIP generation finished for "${d.projectName}"';

/// The rows shown in both renderings, so the two cannot drift apart.
///
/// A field is omitted rather than shown empty: "Genome: —" is noise on a project
/// that never had one.
List<(String, String)> _facts(ProjectMailDetails d) {
  return [
    ('Project', d.projectName),
    if (d.genomeName != null) ('Genome', d.genomeName!),
    if (d.snpName != null) ('SNP set', d.snpName!),
    if (d.geneCount > 0)
      ('Genes', '${d.geneCount} ${d.geneCount == 1 ? 'gene' : 'genes'}'),
    (d.failed ? 'Ran for' : 'Duration', formatDuration(d.completedIn)),
    // Output size on a failure is usually partial or zero, and saying "Output"
    // would imply something usable came out of it.
    if (!d.failed) ('Output size', formatBytes(d.sizeBytes)),
  ];
}

String buildTextBody(ProjectMailDetails d) {
  final lines = <String>[
    if (d.failed)
      'MIP generation for "${d.projectName}" failed.'
    else
      'MIP generation for "${d.projectName}" finished successfully.',
    '',
  ];

  final facts = _facts(d);
  final width = facts.map((f) => f.$1.length).reduce((a, b) => a > b ? a : b);
  for (final (label, value) in facts) {
    lines.add('  ${label.padRight(width)}  $value');
  }

  if (d.failed) {
    lines
      ..add('')
      ..add('Error')
      ..add('  ${d.error.isEmpty ? 'No error message was recorded.' : d.error}')
      ..add('')
      ..add(
        'The project is still there, with its settings intact — open it in '
        'FLUMIP to check the configuration and start again.',
      );
  }

  if (d.siteUrl != null) {
    lines
      ..add('')
      ..add('Open FLUMIP: ${d.siteUrl}');
  }

  lines
    ..add('')
    ..add('—')
    ..add(projectFooter);

  return lines.join('\n');
}

String buildHtmlBody(ProjectMailDetails d) {
  final accent = d.failed ? colourFailure : colourSuccess;

  final errorBlock = d.failed
      ? '''
      <div style="margin:20px 0 0;padding:12px 16px;background:#fce8e6;'''
            '''border-left:4px solid $accent;border-radius:4px;">
        <div style="color:$accent;font-size:13px;font-weight:600;'''
            '''text-transform:uppercase;letter-spacing:.4px;">Error</div>
        <div style="margin-top:6px;color:#202124;font-size:14px;'''
            '''font-family:ui-monospace,SFMono-Regular,Menlo,monospace;'''
            '''word-break:break-word;">${_escape(d.error.isEmpty ? 'No error message was recorded.' : d.error)}</div>
      </div>
      <p style="margin:16px 0 0;color:#5f6368;font-size:14px;line-height:1.5;">
        The project is still there, with its settings intact — open it in FLUMIP
        to check the configuration and start again.
      </p>'''
      : '';

  return _document(
    accent: accent,
    banner: d.failed ? 'Generation failed' : 'Generation finished',
    content:
        '''
              <p style="margin:0 0 20px;color:#202124;font-size:15px;line-height:1.5;">
                MIP generation for <strong>${_escape(d.projectName)}</strong>
                ${d.failed ? 'did not complete.' : 'finished successfully.'}
              </p>
              ${_rowsHtml(_facts(d))}
              $errorBlock
              ${_buttonHtml(d.siteUrl, accent)}''',
    footer: projectFooter,
  );
}

// ---------------------------------------------------------------------------
// The administrator's test email.
//
// Shares the chrome above on purpose: clicking "Send test email" should show
// exactly what a real notification will look like, so a styling problem is found
// then rather than by whoever receives the first genuine one. It also reports
// the SMTP settings it went out with, which is the thing an administrator is
// actually trying to confirm.
// ---------------------------------------------------------------------------

/// What the test email says about how it was delivered.
class TestMailDetails {
  const TestMailDetails({
    required this.smtpServer,
    required this.smtpPort,
    required this.from,
    required this.startTLS,
    this.siteUrl,
  });

  final String smtpServer;
  final int smtpPort;
  final String from;
  final bool startTLS;
  final String? siteUrl;
}

List<(String, String)> _testFacts(TestMailDetails d) => [
  ('SMTP server', '${d.smtpServer}:${d.smtpPort}'),
  ('From', d.from),
  ('STARTTLS', d.startTLS ? 'on' : 'off'),
];

String buildTestSubject() => 'FLUMIP test email';

String buildTestTextBody(TestMailDetails d) {
  final lines = <String>[
    'This is a test email from FLUMIP. If you received it, the SMTP '
        'configuration works.',
    '',
  ];

  final facts = _testFacts(d);
  final width = facts.map((f) => f.$1.length).reduce((a, b) => a > b ? a : b);
  for (final (label, value) in facts) {
    lines.add('  ${label.padRight(width)}  $value');
  }

  lines
    ..add('')
    ..add('Project notifications are sent with this same layout.');

  if (d.siteUrl != null) {
    lines
      ..add('')
      ..add('Open FLUMIP: ${d.siteUrl}');
  }

  lines
    ..add('')
    ..add('—')
    ..add(testFooter);

  return lines.join('\n');
}

String buildTestHtmlBody(TestMailDetails d) => _document(
  accent: colourNeutral,
  banner: 'Test email',
  content:
      '''
              <p style="margin:0 0 20px;color:#202124;font-size:15px;line-height:1.5;">
                This is a test email from FLUMIP. If you received it, the SMTP
                configuration works.
              </p>
              ${_rowsHtml(_testFacts(d))}
              <p style="margin:20px 0 0;color:#5f6368;font-size:14px;line-height:1.5;">
                Project notifications are sent with this same layout.
              </p>
              ${_buttonHtml(d.siteUrl, colourNeutral)}''',
  footer: testFooter,
);

// ---------------------------------------------------------------------------
// Shared rendering.
// ---------------------------------------------------------------------------

/// Header colours. Green and red carry the outcome; blue is for a message that
/// reports neither.
const colourSuccess = '#1e6b3a';
const colourFailure = '#b3261e';
const colourNeutral = '#1a4f8a';

const projectFooter =
    'This is an automated message from FLUMIP. You are '
    'receiving it because you own this project and asked to be notified when '
    'it finishes.';

const testFooter =
    'This message was sent because an administrator used '
    '"Send test email" in the FLUMIP settings.';

/// A label/value table, escaped.
String _rowsHtml(List<(String, String)> facts) {
  final rows = facts
      .map(
        (f) =>
            '''
        <tr>
          <td style="padding:6px 16px 6px 0;color:#5f6368;font-size:14px;'''
            '''white-space:nowrap;vertical-align:top;">${_escape(f.$1)}</td>
          <td style="padding:6px 0;color:#202124;font-size:14px;'''
            '''font-weight:500;">${_escape(f.$2)}</td>
        </tr>''',
      )
      .join('\n');
  return '<table role="presentation" cellpadding="0" cellspacing="0">\n'
      '$rows\n              </table>';
}

String _buttonHtml(String? siteUrl, String accent) => siteUrl == null
    ? ''
    : '''
      <p style="margin:24px 0 0;">
        <a href="${_escape(siteUrl)}" style="display:inline-block;'''
          '''padding:10px 20px;background:$accent;color:#ffffff;'''
          '''text-decoration:none;border-radius:4px;font-size:14px;'''
          '''font-weight:500;">Open FLUMIP</a>
      </p>''';

/// The outer shell every message shares.
///
/// Inline styles and a table layout on purpose: email clients strip `<style>`
/// blocks and support neither flexbox nor grid. Nothing external is loaded — no
/// images, no fonts, no tracking pixel — so it renders the same offline and
/// cannot leak whether the mail was opened.
String _document({
  required String accent,
  required String banner,
  required String content,
  required String footer,
}) =>
    '''
<!doctype html>
<html>
<body style="margin:0;padding:0;background:#f1f3f4;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f1f3f4;padding:24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#ffffff;border-radius:8px;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
          <tr>
            <td style="background:$accent;padding:16px 24px;color:#ffffff;font-size:16px;font-weight:600;">
              ${_escape(banner)}
            </td>
          </tr>
          <tr>
            <td style="padding:24px;">
$content
            </td>
          </tr>
          <tr>
            <td style="padding:16px 24px;background:#f8f9fa;color:#5f6368;font-size:12px;line-height:1.5;">
              ${_escape(footer)}
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>''';

/// Minimal HTML escaping.
///
/// Every interpolated value is user-supplied — a project name, or an error
/// message that may quote a shell command. Without this, a project called
/// `<b>x` would break the layout, and the escaping matters more for the error,
/// which can contain anything a tool printed.
String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
