import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/settings/settings_form.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first coverage of the settings round trip.
///
/// Loading the server's answer into 28 controllers and parsing them back out
/// used to be two methods 60 lines apart inside a `State` that imports
/// `main.dart` — so nothing could check that they agreed, and the only way to
/// find a mismatch was to save a setting and notice it had not changed.
Settings settingsFixture({
  int? id = 1,
  String baseDir = '/opt/flumip/data',
  int smtpPort = 587,
  bool mailActive = true,
  bool startTLS = true,
  bool loginRequired = true,
  bool demoMode = true,
  int demoModeRetentionHours = 72,
  String oidcIssuer = 'https://id.example',
}) => Settings(
  id: id,
  baseDir: baseDir,
  projectDir: '/opt/flumip/data/projects',
  genomeDir: '/opt/flumip/data/genomes',
  customSnpDir: '/opt/flumip/data/custom_snp',
  snpSourceAllowedHosts: 'ftp.ncbi.nlm.nih.gov',
  toolsDir: '/opt/flumip/tools',
  mipgenExecutable: '/opt/flumip/MIPGEN/mipgen',
  exonExtractScript: '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh',
  bigGenePredToGenePredExecutable: '/opt/flumip/tools/bigGenePredToGenePred',
  mailActive: mailActive,
  smtpServer: 'smtp.example',
  smtpPort: smtpPort,
  smtpUser: 'flumip',
  smtpFrom: 'flumip@example',
  startTLS: startTLS,
  loginRequired: loginRequired,
  demoMode: demoMode,
  demoModeRetentionHours: demoModeRetentionHours,
  oidcIssuer: oidcIssuer,
  oidcClientId: 'flumip-web',
  oidcScopes: 'openid email profile',
  oidcButtonLabel: 'Sign in with Example',
  oidcAllowedEmailDomains: 'example.com',
  oidcAdminEmails: 'admin@example.com',
  authPublicUrl: 'https://flumip.example',
);

void main() {
  late SettingsForm form;

  setUp(() => form = SettingsForm());
  tearDown(() => form.dispose());

  group('the round trip', () {
    test('⚠️ everything loaded comes back out unchanged', () {
      // The guard that matters. A field added to Settings and wired into `load`
      // but not `toSettings` silently reverts on every save, and there is no
      // error anywhere — the setting simply will not stick.
      final original = settingsFixture();
      form.load(original);

      expect(form.toSettings(id: original.id).toJson(), original.toJson());
    });

    test('the id is carried through rather than invented', () {
      form.load(settingsFixture(id: 7));
      expect(form.toSettings(id: 7).id, 7);
    });
  });

  group('the fields that are not simply copied', () {
    test('a port that is not a number falls back to 25', () {
      form.load(settingsFixture());
      form.smtpPort.text = '';
      expect(form.toSettings(id: 1).smtpPort, 25);
    });

    test('an empty retention falls back to a week', () {
      form.load(settingsFixture());
      form.demoRetentionHours.text = '';
      expect(form.toSettings(id: 1).demoModeRetentionHours, 168);
    });

    test('⚠️ the OIDC fields are trimmed, and the paths are not', () {
      // A trailing space on an issuer URL breaks discovery with an error naming
      // the wrong cause. A trailing space on a filesystem path is at least
      // visible in the field beside it, and trimming it would silently rewrite
      // what an admin typed.
      form.load(settingsFixture());
      form.oidcIssuer.text = '  https://id.example  ';
      form.baseDir.text = '/opt/flumip/data ';

      final saved = form.toSettings(id: 1);
      expect(saved.oidcIssuer, 'https://id.example');
      expect(saved.baseDir, '/opt/flumip/data ');
    });
  });

  group('the write-only secrets', () {
    test('⚠️ neither is ever populated by a load', () {
      // The server does not send them back, so anything left here would offer to
      // re-send a value this browser cannot know.
      form.smtpPassword.text = 'typed earlier';
      form.oidcClientSecret.text = 'typed earlier';

      form.load(settingsFixture());

      expect(form.smtpPassword.text, isEmpty);
      expect(form.oidcClientSecret.text, isEmpty);
    });

    test('neither travels in the Settings object', () {
      // Both are serverOnly on the model and go through their own endpoints;
      // there is nothing on Settings for them to ride in.
      form.load(settingsFixture());
      form.smtpPassword.text = 'secret';
      form.oidcClientSecret.text = 'secret';

      expect(
        form.toSettings(id: 1).toJson().toString(),
        isNot(contains('secret')),
      );
    });
  });

  group('the settings password', () {
    test('⚠️ the credential is not touched by a load', () {
      // It is typed into the password gate and is what every call on the tab
      // authenticates with. A load that reset it would sign the admin out of
      // their own settings the moment the settings arrived.
      form.password.text = 'typed at the gate';
      form.load(settingsFixture());

      expect(form.password.text, 'typed at the gate');
    });

    test('⚠️ the new-password field is write-only', () {
      // Like the two secrets, and unlike how this field used to work: the server
      // stores only a hash, so there is nothing to load and an empty box has to
      // mean "keep the current password". A load must clear anything half-typed
      // rather than leave it to be sent on the next save.
      form.newPassword.text = 'half typed';
      form.load(settingsFixture());

      expect(form.newPassword.text, isEmpty);
    });
  });

  test('the switches load and save as they were', () {
    form.load(
      settingsFixture(
        mailActive: false,
        startTLS: true,
        loginRequired: false,
        demoMode: true,
      ),
    );

    expect(form.mailActive, isFalse);
    expect(form.startTLS, isTrue);
    expect(form.loginRequired, isFalse);
    expect(form.demoMode, isTrue);

    form.loginRequired = true;
    expect(form.toSettings(id: 1).loginRequired, isTrue);
  });
}
