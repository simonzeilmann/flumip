import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _errorMessage;
  Settings? settings;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _baseDirController = TextEditingController();
  final TextEditingController _projectDirController = TextEditingController();
  final TextEditingController _genomeDirController = TextEditingController();
  final TextEditingController _customSnpDirController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _baseDirController.dispose();
    _projectDirController.dispose();
    _genomeDirController.dispose();
    _customSnpDirController.dispose();
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
      setState(() {
        _errorMessage = null;
        this.settings = settings;
        _baseDirController.text = settings.baseDir;
        _projectDirController.text = settings.projectDir;
        _genomeDirController.text = settings.genomeDir;
        _customSnpDirController.text = settings.customSnpDir;
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
        _smtpPasswordController.text = settings.smtpPassword;
        _smtpFromController.text = settings.smtpFrom;
        _mailActiveNotifier.value = settings.mailActive;
        _startTLSNotifier.value = settings.startTLS;
        _loginRequiredNotifier.value = settings.loginRequired;
        _newPasswordController.text = settings.settingsPassword;
        _demoModeNotifier.value = settings.demoMode;
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
    }
    on ArgumentException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
    catch (e) {
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
        smtpPassword: _smtpPasswordController.text,
        smtpFrom: _smtpFromController.text,
        startTLS: _startTLSNotifier.value,
        loginRequired: _loginRequiredNotifier.value,
        settingsPassword: _newPasswordController.text,
        demoMode: _demoModeNotifier.value,
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
      if (_oidcClientSecretController.text.isNotEmpty) {
        await client.settings.setOidcClientSecret(
          _passwordController.text,
          _oidcClientSecretController.text,
        );
        _oidcClientSecretController.clear();
      }
      await client.settings
          .updateSettings(_passwordController.text, settings);
      setState(() {
        _errorMessage = null;
        // The password may have just been changed; keep the one we authenticate
        // with in sync so subsequent saves / test mails still work.
        _passwordController.text = settings.settingsPassword;
      });
      await _loadAuthStatus();
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

  /// Whether an environment variable has taken over [envName].
  ///
  /// Such a field is shown read-only: saving it would silently have no effect,
  /// because the environment wins in [AuthConfig.resolve].
  bool _overriddenByEnv(String envName) =>
      _authStatus?.envOverrides.contains(envName) ?? false;

  /// A text field that turns read-only when the environment supplies the value.
  Widget _oidcField({
    required TextEditingController controller,
    required String label,
    required String envName,
    String? hintText,
    String? helperText,
  }) {
    final overridden = _overriddenByEnv(envName);
    return TextField(
      controller: controller,
      readOnly: overridden,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: overridden ? 'Set by $envName in the environment' : helperText,
        helperMaxLines: 3,
        suffixIcon: overridden
            ? Tooltip(
                message: 'An environment variable overrides this setting, so '
                    'editing it here has no effect.',
                child: const Icon(Icons.lock_outline, size: 18),
              )
            : null,
      ),
    );
  }

  /// The single sign-on fields, shown only when sign-in is required.
  List<Widget> _ssoFields(BuildContext context) {
    final status = _authStatus;
    final secretConfigured = status?.secretConfigured ?? false;
    return [
      const Divider(),
      // The most important thing on this screen. A mismatch between the URI this
      // server computes and the one registered with the provider is by far the
      // most common way an OIDC setup fails, and the error appears at the
      // provider — where the admin cannot see our value. So show it.
      if (status != null && status.redirectUri.isNotEmpty)
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  'Redirect URI to register with your identity provider',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                SelectableText(
                  status.redirectUri,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                Text(
                  'It must match exactly. If your server sits behind a reverse '
                  'proxy, set the public URL below so this is the address the '
                  'browser actually uses.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      _oidcField(
        controller: _oidcIssuerController,
        label: 'OIDC issuer',
        envName: 'FLUMIP_OIDC_ISSUER',
        hintText: 'https://login.example.org/realms/staff',
        helperText: 'Without a trailing slash. '
            '/.well-known/openid-configuration is appended to it.',
      ),
      _oidcField(
        controller: _oidcClientIdController,
        label: 'Client ID',
        envName: 'FLUMIP_OIDC_CLIENT_ID',
      ),
      // Write-only: the server never sends it back, so the field starts empty
      // and an empty field on save means "leave it alone".
      TextField(
        controller: _oidcClientSecretController,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        readOnly: _overriddenByEnv('FLUMIP_OIDC_CLIENT_SECRET'),
        decoration: InputDecoration(
          labelText: 'Client secret',
          helperMaxLines: 3,
          helperText: _overriddenByEnv('FLUMIP_OIDC_CLIENT_SECRET')
              ? 'Set by FLUMIP_OIDC_CLIENT_SECRET in the environment'
              : secretConfigured
                  ? 'A secret is stored. Type here to replace it; leave empty to '
                      'keep it.'
                  : 'No secret stored yet.',
          suffixIcon: secretConfigured
              ? const Tooltip(
                  message: 'A client secret is stored on the server. It is '
                      'never sent back to the browser.',
                  child: Icon(Icons.check, size: 18),
                )
              : null,
        ),
      ),
      _oidcField(
        controller: _authPublicUrlController,
        label: 'Public URL of this server',
        envName: 'FLUMIP_PUBLIC_URL',
        hintText: 'https://flumip.example.org',
        helperText: 'Needed when a reverse proxy terminates TLS, because the '
            'server otherwise uses its own scheme, host and port.',
      ),
      _oidcField(
        controller: _oidcAllowedDomainsController,
        label: 'Allowed email domains',
        envName: 'FLUMIP_OIDC_ALLOWED_DOMAINS',
        hintText: 'example.org, dept.example.org',
        helperText: 'Comma-separated. Leave empty to allow everyone your '
            'provider authenticates.',
      ),
      _oidcField(
        controller: _oidcAdminEmailsController,
        label: 'Administrator email addresses',
        envName: 'FLUMIP_OIDC_ADMIN_EMAILS',
        hintText: 'you@example.org',
        helperText: 'Comma-separated. These accounts can open this settings tab '
            'without the password.',
      ),
      TextField(
        controller: _oidcScopesController,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Scopes',
          helperText: 'Space-separated. "openid" is required; "email" is needed '
              'to identify users.',
          helperMaxLines: 2,
        ),
      ),
      TextField(
        controller: _oidcButtonLabelController,
        decoration: const InputDecoration(labelText: 'Sign-in button label'),
      ),
      // Validates the configuration here, with a readable message, rather than
      // at someone's first sign-in attempt. Same idea as the test email above.
      Row(
        children: [
          ElevatedButton(
            onPressed: _loadAuthStatus,
            child: const Text('Test connection'),
          ),
          const SizedBox(width: 10),
          if (status != null)
            Expanded(
              child: Text(
                status.discoveryOk
                    ? 'Reached the provider. Authorization endpoint: '
                        '${status.authorizationEndpoint}'
                    : status.discoveryError ?? 'Not configured yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: status.discoveryOk
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
              ),
            ),
        ],
      ),
      // Enforcement is deliberately conditional on a working configuration:
      // requiring a sign-in with no way to sign in would lock everyone out
      // permanently, so the server stays reachable until this is sorted.
      if (status != null && status.enabled && !status.enforcing)
        Container(
          color: Colors.orange[100],
          padding: const EdgeInsets.all(8),
          child: const Text(
            'Sign-in is switched on but is not being enforced yet, because the '
            'configuration is incomplete or the provider could not be reached. '
            'The server stays reachable without signing in until it works, so '
            'that a half-finished setup cannot lock you out.',
          ),
        ),
      const Divider(),
    ];
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 30,
        children: [
          if (_errorMessage != null)
            Container(
              color: Colors.red[300],
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(_errorMessage!),
                ],
              ),
            ),
          SizedBox(height: 20),
          if (settings == null) ...[
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: 'Password'),
                    onSubmitted: (_) => _loadSettings(),
                  ),
                ),
                ElevatedButton(
                    onPressed: _loadSettings, child: Text('Load settings')),
              ],
            ),
          ] else ...[
            SizedBox(
              width: 400,
              child: Column(
                spacing: 3,
                children: [
                  TextField(
                    controller: _baseDirController,
                    decoration: InputDecoration(labelText: 'Base directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _projectDirController,
                    decoration: InputDecoration(labelText: 'Project directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _genomeDirController,
                    decoration: InputDecoration(labelText: 'Genome directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _customSnpDirController,
                    decoration:
                        InputDecoration(labelText: 'Custom SNP directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _toolsDirController,
                    decoration: InputDecoration(labelText: 'Tools directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _mipgenExecutableController,
                    decoration: InputDecoration(labelText: 'MIPGEN executable'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _exonExtractScriptController,
                    decoration:
                        InputDecoration(labelText: 'Exon extract script'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _ucscTrackGeneratorController,
                    decoration:
                        InputDecoration(labelText: 'UCSC track generator'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _bigGenePredToGenePredExecutable,
                    decoration: InputDecoration(
                        labelText: 'BigGenePred to GenePred executable'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _binCreationScript,
                    decoration:
                        InputDecoration(labelText: 'Bin creation script'),
                    keyboardType: TextInputType.text,
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _mailActiveNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged: (value) {
                              setState(() {
                                _mailActiveNotifier.value = value!;
                              });
                            },
                          );
                        },
                      ),
                      Text('Mail active'),
                    ],
                  ),
                  if (_mailActiveNotifier.value) ...[
                    TextField(
                      controller: _smtpServerController,
                      decoration: InputDecoration(labelText: 'SMTP server'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpPortController,
                      decoration: InputDecoration(labelText: 'SMTP port'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _smtpUserController,
                      decoration: InputDecoration(labelText: 'SMTP user'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpPasswordController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(labelText: 'SMTP password'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpFromController,
                      decoration: InputDecoration(labelText: 'SMTP from'),
                      keyboardType: TextInputType.text,
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _startTLSNotifier,
                          builder: (context, value, child) {
                            return Checkbox(
                              value: value,
                              onChanged: (value) {
                                _startTLSNotifier.value = value!;
                              },
                            );
                          },
                        ),
                        Text('Start TLS'),
                      ],
                    ),
                    // Validates the SMTP configuration above without having to
                    // run a job. Uses the currently saved settings, so save
                    // first after changing them.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testMailController,
                            decoration: InputDecoration(
                              labelText: 'Send test email to',
                              hintText: 'you@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: sendTestMail,
                          child: Text('Send test email'),
                        ),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _loginRequiredNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            // setState, unlike the SMTP checkbox above, because
                            // this one reveals the fields below it.
                            onChanged: (value) {
                              setState(() {
                                _loginRequiredNotifier.value = value!;
                              });
                            },
                          );
                        },
                      ),
                      const Expanded(
                        child: Text('Require sign-in (single sign-on)'),
                      ),
                    ],
                  ),
                  if (_loginRequiredNotifier.value) ..._ssoFields(context),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: 'New password'),
                    keyboardType: TextInputType.text,
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _demoModeNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged: (value) {
                              setState(() {
                                _demoModeNotifier.value = value!;
                              });
                            },
                          );
                        },
                      ),
                      Text('Demo mode'),
                    ],
                  ),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: updateSettings,
                child: Text('Update settings'),
              ),
            ),
            SizedBox(height: 50),
          ],
        ],
      ),
    );
  }
}
