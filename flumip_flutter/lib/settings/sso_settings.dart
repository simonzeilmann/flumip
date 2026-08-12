import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../ui/responsive_row.dart';
import '../ui/theme.dart';

/// The single sign-on fields, shown only when sign-in is required.
///
/// ⚠️ **Must not be constructed as `const`.** [status] arrives asynchronously
/// from `getAuthAdminStatus`, and a const-elided widget would never rebuild — so
/// the read-only markers and the "Set by … in the environment" helpers would
/// never appear, on a screen where they are the only sign that editing a field
/// will silently do nothing. `prefer_const_constructors` will not fire here
/// because the controllers are not const, but the reason is worth stating.
///
/// ⚠️ **The controllers stay owned by the settings tab.** In particular
/// [clientSecretController] is write-only: the save path reads `.text`, sends
/// it, then clears it. If this widget created it, every parent rebuild would
/// make a fresh one, `.text` would read empty, and "typing replaces it, empty
/// keeps it" would quietly become "never replaces it" — invisible until someone
/// tried to change a secret in production.
class SsoSettings extends StatelessWidget {
  const SsoSettings({
    super.key,
    required this.issuerController,
    required this.clientIdController,
    required this.clientSecretController,
    required this.publicUrlController,
    required this.allowedDomainsController,
    required this.adminEmailsController,
    required this.scopesController,
    required this.buttonLabelController,
    required this.status,
    required this.onTestConnection,
  });

  final TextEditingController issuerController;
  final TextEditingController clientIdController;
  final TextEditingController clientSecretController;
  final TextEditingController publicUrlController;
  final TextEditingController allowedDomainsController;
  final TextEditingController adminEmailsController;
  final TextEditingController scopesController;
  final TextEditingController buttonLabelController;

  /// Null until the first probe answers.
  final AuthAdminStatusDto? status;

  /// A callback rather than a client call, which is what keeps this file free of
  /// `main.dart` — and therefore testable.
  final VoidCallback onTestConnection;

  /// Whether an environment variable has taken over [envName].
  ///
  /// Such a field is shown read-only: saving it would silently have no effect,
  /// because the environment wins in `AuthConfig.resolve`.
  bool _overriddenByEnv(String envName) =>
      status?.envOverrides.contains(envName) ?? false;

  @override
  Widget build(BuildContext context) {
    final secretConfigured = status?.secretConfigured ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (status != null && status!.redirectUri.isNotEmpty)
          _redirectUriCard(context, status!),
        _oidcField(
          controller: issuerController,
          label: 'OIDC issuer',
          envName: 'FLUMIP_OIDC_ISSUER',
          hintText: 'https://login.example.org/realms/staff',
          helperText:
              'Without a trailing slash. '
              '/.well-known/openid-configuration is appended to it.',
        ),
        ResponsiveRow(
          minChildWidth: 280,
          children: [
            _oidcField(
              controller: clientIdController,
              label: 'Client ID',
              envName: 'FLUMIP_OIDC_CLIENT_ID',
            ),
            _clientSecretField(secretConfigured),
          ],
        ),
        _oidcField(
          controller: publicUrlController,
          label: 'Public URL of this server',
          envName: 'FLUMIP_PUBLIC_URL',
          hintText: 'https://flumip.example.org',
          helperText:
              'Needed when a reverse proxy terminates TLS, because the '
              'server otherwise uses its own scheme, host and port.',
        ),
        _oidcField(
          controller: allowedDomainsController,
          label: 'Allowed email domains',
          envName: 'FLUMIP_OIDC_ALLOWED_DOMAINS',
          hintText: 'example.org, dept.example.org',
          helperText:
              'Comma-separated. Leave empty to allow everyone your '
              'provider authenticates.',
        ),
        _oidcField(
          controller: adminEmailsController,
          label: 'Administrator email addresses',
          envName: 'FLUMIP_OIDC_ADMIN_EMAILS',
          hintText: 'you@example.org',
          helperText:
              'Comma-separated. These accounts can open this settings '
              'tab without the password.',
        ),
        ResponsiveRow(
          minChildWidth: 280,
          children: [
            TextField(
              controller: scopesController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Scopes',
                helperText:
                    'Space-separated. "openid" is required; "email" is '
                    'needed to identify users.',
                helperMaxLines: 2,
              ),
            ),
            TextField(
              controller: buttonLabelController,
              decoration: const InputDecoration(
                labelText: 'Sign-in button label',
              ),
            ),
          ],
        ),
        _testConnection(context),
        if (status != null && status!.enabled && !status!.enforcing)
          _notEnforcingYet(context),
      ],
    );
  }

  /// The most important thing on this screen.
  ///
  /// A mismatch between the URI this server computes and the one registered with
  /// the provider is by far the most common way an OIDC setup fails, and the
  /// error appears at the provider — where the admin cannot see our value.
  Widget _redirectUriCard(BuildContext context, AuthAdminStatusDto status) {
    return Card(
      color: context.colours.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              'Redirect URI to register with your identity provider',
              style: context.text.labelLarge,
            ),
            SelectableText(status.redirectUri, style: context.mono),
            Text(
              'It must match exactly. If your server sits behind a reverse '
              'proxy, set the public URL below so this is the address the '
              'browser actually uses.',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

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
        helperText: overridden
            ? 'Set by $envName in the environment'
            : helperText,
        helperMaxLines: 3,
        suffixIcon: overridden
            ? const Tooltip(
                message:
                    'An environment variable overrides this setting, so '
                    'editing it here has no effect.',
                child: Icon(Icons.lock_outline, size: 18),
              )
            : null,
      ),
    );
  }

  /// Write-only: the server never sends it back, so the field starts empty and
  /// an empty field on save means "leave it alone".
  Widget _clientSecretField(bool secretConfigured) {
    final overridden = _overriddenByEnv('FLUMIP_OIDC_CLIENT_SECRET');
    return TextField(
      controller: clientSecretController,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      readOnly: overridden,
      decoration: InputDecoration(
        labelText: 'Client secret',
        helperMaxLines: 3,
        helperText: overridden
            ? 'Set by FLUMIP_OIDC_CLIENT_SECRET in the environment'
            : secretConfigured
            ? 'A secret is stored. Type here to replace it; leave empty to '
                  'keep it.'
            : 'No secret stored yet.',
        suffixIcon: secretConfigured
            ? const Tooltip(
                message:
                    'A client secret is stored on the server. It is never '
                    'sent back to the browser.',
                child: Icon(Icons.check, size: 18),
              )
            : null,
      ),
    );
  }

  /// Validates the configuration here, with a readable message, rather than at
  /// someone's first sign-in attempt. Same idea as the test email.
  Widget _testConnection(BuildContext context) {
    final status = this.status;
    return Row(
      children: [
        OutlinedButton(
          onPressed: onTestConnection,
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
              style: context.text.bodySmall?.copyWith(
                color: status.discoveryOk
                    ? context.status.success
                    : context.colours.error,
              ),
            ),
          ),
      ],
    );
  }

  /// Enforcement is deliberately conditional on a working configuration:
  /// requiring a sign-in with no way to sign in would lock everyone out
  /// permanently, so the server stays reachable until this is sorted.
  Widget _notEnforcingYet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.status.warningContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Sign-in is switched on but is not being enforced yet, because the '
        'configuration is incomplete or the provider could not be reached. The '
        'server stays reachable without signing in until it works, so that a '
        'half-finished setup cannot lock you out.',
        style: TextStyle(color: context.status.onWarningContainer),
      ),
    );
  }
}
