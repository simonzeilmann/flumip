import 'package:flutter/material.dart';

import '../project/expiry.dart';
import 'auth_controller.dart';

/// The terms paragraph when an administrator has not written their own.
///
/// MIPGEN's licence permits use only for non-commercial academic and research
/// activities, so a public instance cannot offer anything wider than that.
const defaultPublicTerms =
    'FLUMIP is provided for non-commercial, academic research use only. By '
    'continuing you confirm that you will use it only for that purpose.';

/// What a public instance says about its cookie.
///
/// Every word of it has to stay true: the server sets exactly one cookie,
/// `flumip_auth`, HttpOnly, and the app loads nothing from a third party.
const publicCookieNotice =
    'This site stores one cookie, which is strictly necessary: it keeps your '
    'projects linked to this browser. It is not used for tracking, analytics '
    'or marketing, and no third-party services are involved.';

/// The entry notice a public instance shows in place of the app until it is
/// accepted.
///
/// There is no way past it but [AuthController.accept], and nothing behind it
/// would work anyway: the server issues the cookie every API call depends on
/// only when the notice is accepted.
///
/// ⚠️ **Declining keeps the notice up** rather than navigating away. There is
/// nowhere sensible to send someone, and the notice saying why they cannot go on
/// is more use to them than a blank page.
class PublicNoticeScreen extends StatefulWidget {
  const PublicNoticeScreen({
    super.key,
    required this.auth,
    required this.onSignIn,
    required this.openUrl,
  });

  final AuthController auth;

  /// Starts an administrator's sign-in. Offered only when the server can do one.
  final VoidCallback onSignIn;

  /// Opens the Impressum or privacy policy in a new tab.
  final void Function(String url) openUrl;

  @override
  State<PublicNoticeScreen> createState() => _PublicNoticeScreenState();
}

class _PublicNoticeScreenState extends State<PublicNoticeScreen> {
  bool _declined = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = widget.auth;
    final config = auth.config;
    final terms = config.publicNoticeText.trim().isEmpty
        ? defaultPublicTerms
        : config.publicNoticeText.trim();
    final retention = config.projectRetention;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Text(
                        'Before you start',
                        style: theme.textTheme.headlineSmall,
                      ),
                      _Section(
                        icon: Icons.cookie_outlined,
                        title: 'Cookies',
                        text: publicCookieNotice,
                      ),
                      _Section(
                        icon: Icons.school_outlined,
                        title: 'Terms of use',
                        text: terms,
                      ),
                      if (retention != null)
                        _Section(
                          icon: Icons.auto_delete_outlined,
                          title: 'Your projects',
                          text:
                              'Projects are kept for '
                              '${describeRetention(retention)} and deleted '
                              'automatically when their last day ends. You '
                              'can keep a project longer from its '
                              'page, and open it in another browser with its '
                              'share link.',
                        ),
                      if (config.imprintUrl.isNotEmpty ||
                          config.privacyUrl.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (config.imprintUrl.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    widget.openUrl(config.imprintUrl),
                                child: const Text('Imprint'),
                              ),
                            if (config.privacyUrl.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    widget.openUrl(config.privacyUrl),
                                child: const Text('Privacy policy'),
                              ),
                          ],
                        ),
                      if (auth.errorMessage != null)
                        Text(
                          auth.errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      if (_declined)
                        Text(
                          'FLUMIP cannot be used without accepting the terms '
                          'of use.',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton(
                            onPressed: auth.accepting
                                ? null
                                : () {
                                    setState(() => _declined = false);
                                    auth.accept();
                                  },
                            child: const Text('Accept and continue'),
                          ),
                          OutlinedButton(
                            onPressed: auth.accepting
                                ? null
                                : () => setState(() => _declined = true),
                            child: const Text('Decline'),
                          ),
                        ],
                      ),
                      if (config.enabled)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: widget.onSignIn,
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Administrator sign-in'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(text),
            ],
          ),
        ),
      ],
    );
  }
}
