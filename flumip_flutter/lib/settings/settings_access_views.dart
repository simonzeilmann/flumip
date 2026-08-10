import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// Shown when the access question itself failed.
///
/// ⚠️ Deliberately **not** a password box. Falling back to one would turn every
/// transient failure into "type a password", indistinguishable from a real
/// prompt — the reason an earlier bug here was so hard to read.
///
/// ⚠️ It renders only a button: the explanation comes from the shared error
/// banner above it. Moving that banner inside the admin form would leave this
/// branch as an unexplained button on an empty screen.
class SettingsRetryView extends StatelessWidget {
  const SettingsRetryView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Try again'),
    ),
  );
}

/// The password box, for an install that is not enforcing sign-in.
///
/// ⚠️ The controller is owned by the settings tab and passed in, never created
/// here. It doubles as the credential for every subsequent settings call, and it
/// has to keep its text after this widget leaves the tree — which looks like a
/// bug when you read this file alone, hence this note.
class SettingsPasswordGate extends StatelessWidget {
  const SettingsPasswordGate({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(
              'Settings password',
              style: context.text.titleMedium,
              textAlign: TextAlign.center,
            ),
            TextField(
              controller: controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => onSubmit(),
            ),
            FilledButton(
              onPressed: onSubmit,
              child: const Text('Load settings'),
            ),
          ],
        ),
      ),
    );
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
class NoSettingsView extends StatelessWidget {
  const NoSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 40,
              color: context.colours.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No settings available', style: context.text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Everything on this page configures the server itself, so it is '
              'restricted to administrators. Nothing here is specific to your '
              'account yet.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colours.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
