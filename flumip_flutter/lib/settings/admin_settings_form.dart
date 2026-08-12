import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/form_section.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';
import '../ui/theme.dart';
import 'settings_form.dart';
import 'sso_settings.dart';

/// The five sections an administrator edits: storage, tools, mail, sign-in,
/// security.
///
/// Takes the [SettingsForm] it writes into and calls [onChanged] whenever a
/// switch moves, because a switch changes which fields are shown — mail
/// collapses when it is off, and so does the SSO block and the demo retention.
///
/// No `client` and no state of its own, so it can be pumped in a test. The tab
/// keeps everything that talks to the server.
class AdminSettingsForm extends StatelessWidget {
  const AdminSettingsForm({
    super.key,
    required this.form,
    required this.authStatus,
    required this.smtpPasswordConfigured,
    required this.onChanged,
    required this.onTestConnection,
    required this.onSendTestMail,
  });

  final SettingsForm form;

  /// What the server reports about the SSO setup that is not itself a setting:
  /// the computed redirect URI, whether a secret is stored, which fields an
  /// environment variable has taken over, and the discovery probe result.
  final AuthAdminStatusDto? authStatus;

  /// Whether the server holds an SMTP password.
  ///
  /// The password itself is never sent, so without this an empty box would be
  /// indistinguishable from no password at all — and an admin would retype one
  /// every time they touched an unrelated setting.
  final bool smtpPasswordConfigured;

  final VoidCallback onChanged;
  final VoidCallback onTestConnection;
  final VoidCallback onSendTestMail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ContentWidth(
        maxWidth: ContentWidth.form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: [
            _storage(),
            _tools(),
            _mail(),
            _signIn(),
            _security(context),
          ],
        ),
      ),
    );
  }

  FormSection _storage() => FormSection(
    title: 'Storage',
    description: 'Where the server keeps projects, genomes and SNP sets.',
    children: [
      ResponsiveRow(
        minChildWidth: 280,
        children: [
          _path(form.baseDir, 'Base directory'),
          _path(form.projectDir, 'Project directory'),
        ],
      ),
      ResponsiveRow(
        minChildWidth: 280,
        children: [
          _path(form.genomeDir, 'Genome directory'),
          _path(form.customSnpDir, 'Custom SNP directory'),
        ],
      ),
      // Full width, and on its own: the helper runs to four lines, and pairing
      // it would set the height of whatever sat beside it.
      TextField(
        controller: form.snpSourceAllowedHosts,
        decoration: const InputDecoration(
          labelText: 'Allowed SNP download hosts',
          helperText:
              'Comma-separated, e.g. ftp.ncbi.nlm.nih.gov, '
              'hgdownload.soe.ucsc.edu. Subdomains match. Leave empty to '
              'allow any public address.\n'
              'Filling this in is what closes the DNS-rebinding gap the '
              'address checks cannot.',
          helperMaxLines: 4,
        ),
      ),
    ],
  );

  FormSection _tools() => FormSection(
    title: 'External tools',
    description: 'Absolute paths to MIPGEN and the scripts around it.',
    children: [
      ResponsiveRow(
        minChildWidth: 280,
        children: [
          _path(form.toolsDir, 'Tools directory'),
          _path(form.mipgenExecutable, 'MIPGEN executable'),
        ],
      ),
      ResponsiveRow(
        minChildWidth: 280,
        children: [
          _path(form.exonExtractScript, 'Exon extract script'),
          _path(form.ucscTrackGenerator, 'UCSC track generator'),
        ],
      ),
      ResponsiveRow(
        minChildWidth: 280,
        children: [
          _path(
            form.bigGenePredToGenePred,
            'BigGenePred to GenePred executable',
          ),
          _path(form.binCreationScript, 'Bin creation script'),
        ],
      ),
    ],
  );

  FormSection _mail() => FormSection(
    title: 'Mail',
    description: 'Used for job notifications. Optional.',
    children: [
      SwitchListTile(
        value: form.mailActive,
        title: const Text('Send email'),
        subtitle: const Text(
          'Off means no notifications are sent, whatever a project asks for.',
        ),
        contentPadding: EdgeInsets.zero,
        onChanged: (value) {
          form.mailActive = value;
          onChanged();
        },
      ),
      if (form.mailActive) ...[
        ResponsiveRow(
          minChildWidth: 200,
          // A hostname wants the room; a five-digit port does not. Equal columns
          // would leave the port field 430px wide for four characters, which is
          // what it had before.
          flex: const [3, 1],
          children: [
            TextField(
              controller: form.smtpServer,
              decoration: const InputDecoration(labelText: 'SMTP server'),
            ),
            TextField(
              controller: form.smtpPort,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 260,
          children: [
            TextField(
              controller: form.smtpUser,
              decoration: const InputDecoration(labelText: 'SMTP user'),
            ),
            TextField(
              controller: form.smtpFrom,
              decoration: const InputDecoration(labelText: 'From address'),
            ),
          ],
        ),
        // ⚠️ Write-only. The save path reads `.text`, sends it, then clears it —
        // so an empty field means "keep what is stored".
        TextField(
          controller: form.smtpPassword,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'SMTP password',
            helperMaxLines: 3,
            helperText: smtpPasswordConfigured
                ? 'A password is stored. Type here to replace it; leave '
                      'empty to keep it.'
                : 'No password stored. Leave empty for a relay that needs '
                      'no authentication.',
            suffixIcon: smtpPasswordConfigured
                ? const Tooltip(
                    message:
                        'A password is stored on the server. It is '
                        'never sent back to the browser.',
                    child: Icon(Icons.check, size: 18),
                  )
                : null,
          ),
        ),
        SwitchListTile(
          value: form.startTLS,
          title: const Text('Start TLS'),
          contentPadding: EdgeInsets.zero,
          // ⚠️ The rebuild here is what the Checkbox this replaces omitted. That
          // was harmless only because it sat inside a ValueListenableBuilder and
          // nothing below it was conditional on the value. A SwitchListTile is
          // not, so without this the switch would not move.
          onChanged: (value) {
            form.startTLS = value;
            onChanged();
          },
        ),
        // Validates the SMTP configuration above without having to run a job.
        // Uses the currently saved settings, so save first after changing them.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: form.testMail,
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
                onPressed: onSendTestMail,
                child: const Text('Send test email'),
              ),
            ),
          ],
        ),
      ],
    ],
  );

  FormSection _signIn() => FormSection(
    title: 'Sign-in',
    description:
        'Single sign-on through an OpenID Connect provider. '
        'Off means anyone who can reach the server can use it.',
    children: [
      SwitchListTile(
        value: form.loginRequired,
        title: const Text('Require sign-in'),
        contentPadding: EdgeInsets.zero,
        onChanged: (value) {
          form.loginRequired = value;
          onChanged();
        },
      ),
      if (form.loginRequired)
        // ⚠️ Not const: authStatus arrives asynchronously, and a const-elided
        // widget would never show the env-override markers.
        SsoSettings(
          issuerController: form.oidcIssuer,
          clientIdController: form.oidcClientId,
          clientSecretController: form.oidcClientSecret,
          publicUrlController: form.authPublicUrl,
          allowedDomainsController: form.oidcAllowedDomains,
          adminEmailsController: form.oidcAdminEmails,
          scopesController: form.oidcScopes,
          buttonLabelController: form.oidcButtonLabel,
          status: authStatus,
          onTestConnection: onTestConnection,
        ),
    ],
  );

  /// The settings password and demo mode.
  ///
  /// These two had no heading at all before — the password field sat between the
  /// sign-in block and a "Demo mode" checkbox, with nothing saying what either
  /// was for.
  FormSection _security(BuildContext context) => FormSection(
    title: 'Security',
    children: [
      TextField(
        controller: form.newPassword,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        // ⚠️ Not a write-only field, unlike the two secrets above: the current
        // value is loaded into it and sent back verbatim on save. So the helper
        // must not say "leave empty to keep it" — emptying it sets an empty
        // password.
        decoration: const InputDecoration(
          labelText: 'Settings password',
          helperText:
              'Opens this tab on an install without sign-in. '
              'Editing it here changes it when you save.',
        ),
      ),
      SwitchListTile(
        value: form.demoMode,
        title: const Text('Demo mode'),
        subtitle: const Text('Projects are deleted automatically.'),
        contentPadding: EdgeInsets.zero,
        onChanged: (value) {
          form.demoMode = value;
          onChanged();
        },
      ),
      if (form.demoMode)
        ResponsiveRow(
          minChildWidth: 220,
          flex: const [1, 2],
          children: [
            TextField(
              controller: form.demoRetentionHours,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Keep projects for (hours)',
                helperText: '168 is a week.',
              ),
            ),
            // ⚠️ Says plainly which way the setting bites. Raising it reprieves
            // projects already queued for deletion; lowering it cannot pull an
            // existing deadline forward, because nothing wakes up earlier than
            // the time it was given.
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
