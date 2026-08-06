import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../error_text.dart';
import '../main.dart';
import '../ui/error_banner.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';
import '../ui/theme.dart';
import 'settings_access_views.dart';
import '../ui/form_section.dart';
import 'sso_settings.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _errorMessage;
  Settings? settings;

  /// What this caller may see, from the server. Null until the first answer.
  ///
  /// Asked on open rather than inferred from the session, so the tab draws the
  /// same thing the server would enforce. Getting this wrong is what produced
  /// the two behaviours this replaced: an administrator shown a password box for
  /// a password they did not need, and an ordinary user shown one that worked.
  UserSettingsDto? _access;

  /// Set when the access question itself failed, so the tab can offer a retry
  /// rather than a password box it has no reason to believe would work.
  bool _accessFailed = false;

  @override
  void initState() {
    super.initState();
    // ⚠️ Asked again whenever sign-in state changes, not just once here.
    //
    // TabBarView builds all three tabs when the app starts, so this runs before
    // AuthController has exchanged the cookie at /auth/session for a bearer. The
    // first answer therefore describes an anonymous caller — `isAdmin: false`,
    // and on an install that is not enforcing, `passwordAccepted: true`. Caching
    // that was the bug: an administrator was shown a password box, and so was
    // everyone else, because the question had been asked before there was
    // anybody to ask about.
    authController.addListener(_onAuthChanged);
    _loadAccess();
  }

  void _onAuthChanged() {
    // Whatever was decided for the previous identity no longer applies. Drop the
    // loaded settings too: signing out must not leave an administrator's
    // configuration on screen.
    setState(() {
      _access = null;
      settings = null;
      _errorMessage = null;
    });
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    try {
      final access = await client.settings.userSettings();
      if (!mounted) return;
      setState(() {
        _access = access;
        _accessFailed = false;
      });
      // An administrator needs no password, so there is nothing to ask for:
      // load straight away rather than making them click through a box that
      // would have accepted an empty string.
      if (access.isAdmin) await _loadSettings();
    } catch (e) {
      if (!mounted) return;
      // Deliberately NOT falling back to the password form. Doing that turns
      // every transient failure into "type a password" — indistinguishable from
      // a real prompt, and the reason the earlier bug was so hard to read.
      setState(() {
        _accessFailed = true;
        _errorMessage = 'Could not determine your access: ${describeError(e)}';
      });
    }
  }

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _baseDirController = TextEditingController();
  final TextEditingController _projectDirController = TextEditingController();
  final TextEditingController _genomeDirController = TextEditingController();
  final TextEditingController _customSnpDirController = TextEditingController();
  final TextEditingController _snpSourceAllowedHostsController =
      TextEditingController();
  final TextEditingController _toolsDirController = TextEditingController();
  final TextEditingController _mipgenExecutableController =
      TextEditingController();
  final TextEditingController _exonExtractScriptController =
      TextEditingController();
  final TextEditingController _ucscTrackGeneratorController =
      TextEditingController();
  final TextEditingController _bigGenePredToGenePredExecutable =
      TextEditingController();
  final TextEditingController _binCreationScript = TextEditingController();
  final TextEditingController _smtpServerController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUserController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();
  final TextEditingController _smtpFromController = TextEditingController();
  final TextEditingController _testMailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _oidcIssuerController = TextEditingController();
  final TextEditingController _oidcClientIdController = TextEditingController();
  final TextEditingController _oidcClientSecretController =
      TextEditingController();
  final TextEditingController _oidcScopesController = TextEditingController();
  final TextEditingController _oidcButtonLabelController =
      TextEditingController();
  final TextEditingController _oidcAllowedDomainsController =
      TextEditingController();
  final TextEditingController _oidcAdminEmailsController =
      TextEditingController();
  final TextEditingController _authPublicUrlController =
      TextEditingController();

  /// What the server reports about the SSO setup that is not itself a setting:
  /// the computed redirect URI, whether a secret is stored, which fields an
  /// environment variable has taken over, and the discovery probe result.
  AuthAdminStatusDto? _authStatus;

  final ValueNotifier<bool> _mailActiveNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _startTLSNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _loginRequiredNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _demoModeNotifier = ValueNotifier(false);
  final TextEditingController _demoRetentionController =
      TextEditingController();

  @override
  void dispose() {
    authController.removeListener(_onAuthChanged);
    _passwordController.dispose();
    _baseDirController.dispose();
    _projectDirController.dispose();
    _genomeDirController.dispose();
    _customSnpDirController.dispose();
    _snpSourceAllowedHostsController.dispose();
    _toolsDirController.dispose();
    _mipgenExecutableController.dispose();
    _exonExtractScriptController.dispose();
    _ucscTrackGeneratorController.dispose();
    _bigGenePredToGenePredExecutable.dispose();
    _binCreationScript.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPasswordController.dispose();
    _smtpFromController.dispose();
    _testMailController.dispose();
    _mailActiveNotifier.dispose();
    _startTLSNotifier.dispose();
    _loginRequiredNotifier.dispose();
    _demoModeNotifier.dispose();
    _demoRetentionController.dispose();
    _newPasswordController.dispose();
    _oidcIssuerController.dispose();
    _oidcClientIdController.dispose();
    _oidcClientSecretController.dispose();
    _oidcScopesController.dispose();
    _oidcButtonLabelController.dispose();
    _oidcAllowedDomainsController.dispose();
    _oidcAdminEmailsController.dispose();
    _authPublicUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings =
          await client.settings.getSettings(_passwordController.text);
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        this.settings = settings;
        _baseDirController.text = settings.baseDir;
        _projectDirController.text = settings.projectDir;
        _genomeDirController.text = settings.genomeDir;
        _customSnpDirController.text = settings.customSnpDir;
        _snpSourceAllowedHostsController.text = settings.snpSourceAllowedHosts;
        _toolsDirController.text = settings.toolsDir;
        _mipgenExecutableController.text = settings.mipgenExecutable;
        _exonExtractScriptController.text = settings.exonExtractScript;
        _ucscTrackGeneratorController.text = settings.ucscTrackGenerator;
        _bigGenePredToGenePredExecutable.text =
            settings.bigGenePredToGenePredExecutable;
        _binCreationScript.text = settings.binCreationScript;
        _smtpServerController.text = settings.smtpServer;
        _smtpPortController.text = settings.smtpPort.toString();
        _smtpUserController.text = settings.smtpUser;
        _smtpFromController.text = settings.smtpFrom;
        _mailActiveNotifier.value = settings.mailActive;
        _startTLSNotifier.value = settings.startTLS;
        _loginRequiredNotifier.value = settings.loginRequired;
        _newPasswordController.text = settings.settingsPassword;
        _demoModeNotifier.value = settings.demoMode;
        _demoRetentionController.text =
            settings.demoModeRetentionHours.toString();
        _oidcIssuerController.text = settings.oidcIssuer;
        _oidcClientIdController.text = settings.oidcClientId;
        _oidcScopesController.text = settings.oidcScopes;
        _oidcButtonLabelController.text = settings.oidcButtonLabel;
        _oidcAllowedDomainsController.text = settings.oidcAllowedEmailDomains;
        _oidcAdminEmailsController.text = settings.oidcAdminEmails;
        _authPublicUrlController.text = settings.authPublicUrl;
        // Never populated from the server: the secret is write-only.
        _oidcClientSecretController.clear();
      });
      await _loadAuthStatus();
      await _loadSmtpPasswordStatus();
    }
    on ArgumentException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    }
    catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  Future<void> updateSettings() async {
    try {
      var settings = Settings(
        id: this.settings!.id,
        baseDir: _baseDirController.text,
        projectDir: _projectDirController.text,
        genomeDir: _genomeDirController.text,
        customSnpDir: _customSnpDirController.text,
        snpSourceAllowedHosts: _snpSourceAllowedHostsController.text,
        toolsDir: _toolsDirController.text,
        mipgenExecutable: _mipgenExecutableController.text,
        exonExtractScript: _exonExtractScriptController.text,
        ucscTrackGenerator: _ucscTrackGeneratorController.text,
        bigGenePredToGenePredExecutable: _bigGenePredToGenePredExecutable.text,
        binCreationScript: _binCreationScript.text,
        mailActive: _mailActiveNotifier.value,
        smtpServer: _smtpServerController.text,
        smtpPort: int.tryParse(_smtpPortController.text) ?? 25,
        smtpUser: _smtpUserController.text,
        smtpFrom: _smtpFromController.text,
        startTLS: _startTLSNotifier.value,
        loginRequired: _loginRequiredNotifier.value,
        settingsPassword: _newPasswordController.text,
        demoMode: _demoModeNotifier.value,
        // The server clamps this to 1..8760, so a nonsense entry becomes the
        // nearest sane value rather than being rejected.
        demoModeRetentionHours:
            int.tryParse(_demoRetentionController.text) ?? 168,
        oidcIssuer: _oidcIssuerController.text.trim(),
        oidcClientId: _oidcClientIdController.text.trim(),
        oidcScopes: _oidcScopesController.text.trim(),
        oidcButtonLabel: _oidcButtonLabelController.text.trim(),
        oidcAllowedEmailDomains: _oidcAllowedDomainsController.text.trim(),
        oidcAdminEmails: _oidcAdminEmailsController.text.trim(),
        authPublicUrl: _authPublicUrlController.text.trim(),
      );

      // Authenticated with the password the settings were loaded with; a new
      // password in `settingsPassword` only takes effect after this succeeds.
      // Sent before updateSettings, so that switching SSO on in the same save
      // finds the secret already in place rather than refusing as incomplete.
      // oidcClientSecret cannot travel in the Settings object above: it is a
      // serverOnly field and has no client-side counterpart.
      // Same reasoning as the OIDC secret below: serverOnly, so it has no
      // client-side counterpart to travel in the Settings object. Typing
      // something replaces the stored password; leaving the box empty keeps it,
      // which is why an unrelated save cannot blank it by accident.
      if (_smtpPasswordController.text.isNotEmpty) {
        await client.settings.setSmtpPassword(
          _passwordController.text,
          _smtpPasswordController.text,
        );
        _smtpPasswordController.clear();
        _smtpPasswordConfigured = true;
      }

      if (_oidcClientSecretController.text.isNotEmpty) {
        await client.settings.setOidcClientSecret(
          _passwordController.text,
          _oidcClientSecretController.text,
        );
        _oidcClientSecretController.clear();
      }
      // Captured before the save, because that is what makes this a transition
      // rather than just a value.
      final wasRequiringLogin = this.settings!.loginRequired;

      await client.settings
          .updateSettings(_passwordController.text, settings);

      if (wasRequiringLogin && !settings.loginRequired) {
        // The server has just ended every session, this one included — there is
        // nothing left to be signed in to. Navigating to /auth/logout clears the
        // HttpOnly cookie (only the server can) and reloads the app, which then
        // bootstraps into the no-authentication state it has now actually got.
        //
        // Returning here on purpose: everything below assumes a session that no
        // longer exists, and _loadAuthStatus would simply fail.
        authController.signOut(siteUrl);
        return;
      }

      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        // The password may have just been changed; keep the one we authenticate
        // with in sync so subsequent saves / test mails still work.
        _passwordController.text = settings.settingsPassword;
      });
      await _loadAuthStatus();
      await _loadSmtpPasswordStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  /// Re-reads the SSO status, including a live discovery probe.
  ///
  /// Failure is not fatal — the rest of the settings tab still works — so this
  /// only clears the panel rather than showing an error banner.
  /// Whether the server holds an SMTP password.
  ///
  /// The password itself is never sent, so without this an empty box would be
  /// indistinguishable from no password at all — and an admin would retype one
  /// every time they touched an unrelated setting.
  bool _smtpPasswordConfigured = false;

  Future<void> _loadSmtpPasswordStatus() async {
    try {
      final configured = await client.settings
          .smtpPasswordConfigured(_passwordController.text);
      if (!mounted) return;
      setState(() => _smtpPasswordConfigured = configured);
    } catch (_) {
      // Not knowing is not the same as knowing there is none, but the only cost
      // of guessing low here is slightly more cautious wording.
      if (!mounted) return;
      setState(() => _smtpPasswordConfigured = false);
    }
  }

  Future<void> _loadAuthStatus() async {
    try {
      final status =
          await client.settings.getAuthAdminStatus(_passwordController.text);
      if (!mounted) return;
      setState(() => _authStatus = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _authStatus = null);
    }
  }

  Future<void> sendTestMail() async {
    final to = _testMailController.text.trim();
    if (to.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a recipient address for the test email';
      });
      return;
    }
    try {
      await client.settings.sendTestMail(_passwordController.text, to);
      setState(() {
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test email sent to $to')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  /// What a signed-in non-administrator sees.
  ///
  /// **This is where per-user settings go.** There are none yet — every field on
  /// `Settings` is server configuration — so this says so plainly rather than
  /// showing an empty form or a password box that would be refused.
  ///
  /// To add one: put the field on `UserSettingsDto`, fill it in from the caller's
  /// identity in `SettingsEndpoint.userSettings`, and render it here. The rest of
  /// the plumbing — the endpoint, the call on open, and this branch of the tab —
  /// already exists.
  Widget buildUserSettingsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 40,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No settings available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Everything on this page configures the server itself, so it is '
              'restricted to administrators. Nothing here is specific to your '
              'account yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (settings == null && _accessFailed) {
      return _shell(SettingsRetryView(onRetry: _loadAccess));
    }
    if (settings == null && _access == null) {
      return _shell(const Center(child: CircularProgressIndicator()));
    }
    if (settings == null && _access!.passwordAccepted) {
      // Only reachable when sign-in is not being enforced. Once it is, the
      // server stops accepting the password, so offering the box would be
      // offering something that cannot work.
      return _shell(
        SettingsPasswordGate(
          controller: _passwordController,
          onSubmit: _loadSettings,
        ),
      );
    }
    if (settings == null) return _shell(const NoSettingsView());
    return _shell(_adminForm(context), saveBar: true);
  }

  /// The error banner sits above whichever branch is showing.
  ///
  /// ⚠️ **Above, not inside the form.** The `_accessFailed` branch renders only a
  /// button; the sentence explaining why comes from here. Move this into
  /// `_adminForm` and that branch becomes an unexplained button on a blank
  /// screen.
  ///
  /// It is also outside the scroll view, which is the other half of the fix: it
  /// used to be the first child of the `SingleChildScrollView`, so a failed save
  /// from the bottom of a long form showed the user nothing at all.
  Widget _shell(Widget body, {bool saveBar = false}) {
    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: ContentWidth.form),
                child: ErrorBanner(
                  _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ),
            ),
          ),
        Expanded(child: body),
        if (saveBar)
          FormSaveBar(
            onSave: updateSettings,
            maxWidth: ContentWidth.form,
          ),
      ],
    );
  }

  Widget _adminForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ContentWidth(
        maxWidth: ContentWidth.form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: [
            _storageSection(),
            _toolsSection(),
            _mailSection(),
            _signInSection(context),
            _securitySection(),
          ],
        ),
      ),
    );
  }

  FormSection _storageSection() => FormSection(
        title: 'Storage',
        description: 'Where the server keeps projects, genomes and SNP sets.',
        children: [
          ResponsiveRow(
            minChildWidth: 280,
            children: [
              _path(_baseDirController, 'Base directory'),
              _path(_projectDirController, 'Project directory'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 280,
            children: [
              _path(_genomeDirController, 'Genome directory'),
              _path(_customSnpDirController, 'Custom SNP directory'),
            ],
          ),
          // Full width, and on its own: the helper runs to four lines, and
          // pairing it would set the height of whatever sat beside it.
          TextField(
            controller: _snpSourceAllowedHostsController,
            decoration: const InputDecoration(
              labelText: 'Allowed SNP download hosts',
              helperText: 'Comma-separated, e.g. ftp.ncbi.nlm.nih.gov, '
                  'hgdownload.soe.ucsc.edu. Subdomains match. Leave empty to '
                  'allow any public address.\n'
                  'Filling this in is what closes the DNS-rebinding gap the '
                  'address checks cannot.',
              helperMaxLines: 4,
            ),
          ),
        ],
      );

  FormSection _toolsSection() => FormSection(
        title: 'External tools',
        description: 'Absolute paths to MIPGEN and the scripts around it.',
        children: [
          ResponsiveRow(
            minChildWidth: 280,
            children: [
              _path(_toolsDirController, 'Tools directory'),
              _path(_mipgenExecutableController, 'MIPGEN executable'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 280,
            children: [
              _path(_exonExtractScriptController, 'Exon extract script'),
              _path(_ucscTrackGeneratorController, 'UCSC track generator'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 280,
            children: [
              _path(
                _bigGenePredToGenePredExecutable,
                'BigGenePred to GenePred executable',
              ),
              _path(_binCreationScript, 'Bin creation script'),
            ],
          ),
        ],
      );

  FormSection _mailSection() => FormSection(
        title: 'Mail',
        description: 'Used for job notifications. Optional.',
        children: [
          SwitchListTile(
            value: _mailActiveNotifier.value,
            title: const Text('Send email'),
            subtitle: const Text(
              'Off means no notifications are sent, whatever a project asks for.',
            ),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) =>
                setState(() => _mailActiveNotifier.value = value),
          ),
          if (_mailActiveNotifier.value) ...[
            ResponsiveRow(
              minChildWidth: 200,
              // A hostname wants the room; a five-digit port does not. Equal
              // columns would leave the port field 430px wide for four
              // characters, which is what it had before.
              flex: const [3, 1],
              children: [
                TextField(
                  controller: _smtpServerController,
                  decoration: const InputDecoration(labelText: 'SMTP server'),
                ),
                TextField(
                  controller: _smtpPortController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            ResponsiveRow(
              minChildWidth: 260,
              children: [
                TextField(
                  controller: _smtpUserController,
                  decoration: const InputDecoration(labelText: 'SMTP user'),
                ),
                TextField(
                  controller: _smtpFromController,
                  decoration: const InputDecoration(labelText: 'From address'),
                ),
              ],
            ),
            // ⚠️ Write-only, and the controller is owned by this state. The save
            // path reads `.text`, sends it, then clears it — so an empty field
            // means "keep what is stored".
            TextField(
              controller: _smtpPasswordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'SMTP password',
                helperMaxLines: 3,
                helperText: _smtpPasswordConfigured
                    ? 'A password is stored. Type here to replace it; leave '
                        'empty to keep it.'
                    : 'No password stored. Leave empty for a relay that needs '
                        'no authentication.',
                suffixIcon: _smtpPasswordConfigured
                    ? const Tooltip(
                        message: 'A password is stored on the server. It is '
                            'never sent back to the browser.',
                        child: Icon(Icons.check, size: 18),
                      )
                    : null,
              ),
            ),
            SwitchListTile(
              value: _startTLSNotifier.value,
              title: const Text('Start TLS'),
              contentPadding: EdgeInsets.zero,
              // ⚠️ setState, which the Checkbox this replaces omitted. That was
              // harmless only because it sat inside a ValueListenableBuilder and
              // nothing below it was conditional on the value. A SwitchListTile
              // is not, so without this the switch would not move.
              onChanged: (value) =>
                  setState(() => _startTLSNotifier.value = value),
            ),
            // Validates the SMTP configuration above without having to run a
            // job. Uses the currently saved settings, so save first after
            // changing them.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _testMailController,
                    decoration: const InputDecoration(
                      labelText: 'Send test email to',
                      hintText: 'you@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton(
                    onPressed: sendTestMail,
                    child: const Text('Send test email'),
                  ),
                ),
              ],
            ),
          ],
        ],
      );

  FormSection _signInSection(BuildContext context) => FormSection(
        title: 'Sign-in',
        description: 'Single sign-on through an OpenID Connect provider. '
            'Off means anyone who can reach the server can use it.',
        children: [
          SwitchListTile(
            value: _loginRequiredNotifier.value,
            title: const Text('Require sign-in'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) =>
                setState(() => _loginRequiredNotifier.value = value),
          ),
          if (_loginRequiredNotifier.value)
            // ⚠️ Not const: _authStatus arrives asynchronously, and a
            // const-elided widget would never show the env-override markers.
            SsoSettings(
              issuerController: _oidcIssuerController,
              clientIdController: _oidcClientIdController,
              clientSecretController: _oidcClientSecretController,
              publicUrlController: _authPublicUrlController,
              allowedDomainsController: _oidcAllowedDomainsController,
              adminEmailsController: _oidcAdminEmailsController,
              scopesController: _oidcScopesController,
              buttonLabelController: _oidcButtonLabelController,
              status: _authStatus,
              onTestConnection: _loadAuthStatus,
            ),
        ],
      );

  /// The settings password and demo mode.
  ///
  /// These two had no heading at all before — the password field sat between the
  /// sign-in block and a "Demo mode" checkbox, with nothing saying what either
  /// was for.
  FormSection _securitySection() => FormSection(
        title: 'Security',
        children: [
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            // ⚠️ Not a write-only field, unlike the two secrets above: the
            // current value is loaded into it and sent back verbatim on save.
            // So the helper must not say "leave empty to keep it" — emptying it
            // sets an empty password.
            decoration: const InputDecoration(
              labelText: 'Settings password',
              helperText: 'Opens this tab on an install without sign-in. '
                  'Editing it here changes it when you save.',
            ),
          ),
          SwitchListTile(
            value: _demoModeNotifier.value,
            title: const Text('Demo mode'),
            subtitle: const Text('Projects are deleted automatically.'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) =>
                setState(() => _demoModeNotifier.value = value),
          ),
          if (_demoModeNotifier.value)
            ResponsiveRow(
              minChildWidth: 220,
              flex: const [1, 2],
              children: [
                TextField(
                  controller: _demoRetentionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Keep projects for (hours)',
                    helperText: '168 is a week.',
                  ),
                ),
                // ⚠️ Says plainly which way the setting bites. Raising it
                // reprieves projects already queued for deletion; lowering it
                // cannot pull an existing deadline forward, because nothing
                // wakes up earlier than the time it was given.
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Raising this spares projects already scheduled for '
                    'deletion. Lowering it applies to new projects only.',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colours.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
        ],
      );

  TextField _path(TextEditingController controller, String label) => TextField(
        controller: controller,
        autocorrect: false,
        decoration: InputDecoration(labelText: label),
      );
}
