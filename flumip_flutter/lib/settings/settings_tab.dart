import 'dart:async';

import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import 'admin_settings_form.dart';
import 'settings_access_views.dart';
import 'settings_controller.dart';

/// Server configuration, for whoever is allowed to see it.
///
/// Everything that talks to the server — what the caller may see, what the
/// settings are, and what happens when they are saved — is in
/// [SettingsController]. The fields themselves are in `settings_form.dart` (the
/// values) and `admin_settings_form.dart` (the five sections); this file picks
/// between five views and hangs the error banner above whichever is showing.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.controller});

  /// The controller to use, or null to take the app-wide one.
  ///
  /// ⚠️ App-wide by default, like the projects tab and unlike the two that poll:
  /// this one holds the settings password somebody typed into the gate, and
  /// rebuilding it on a tab switch would ask for it again.
  final SettingsController? controller;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final SettingsController _controller =
      widget.controller ?? settingsController;
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _messages = _controller.messages.listen(_say);
    _controller.load();
  }

  @override
  void dispose() {
    _messages?.cancel();
    _controller.removeListener(_onChanged);
    // ⚠️ Never disposed here — it outlives the tab, and disposing it would take
    // the form's controllers with it, including the password.
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return switch (_controller.view) {
      SettingsView.retry => _shell(
        SettingsRetryView(onRetry: _controller.loadAccess),
      ),
      SettingsView.loading => _shell(
        const Center(child: CircularProgressIndicator()),
      ),
      SettingsView.passwordGate => _shell(
        SettingsPasswordGate(
          controller: _controller.form.password,
          onSubmit: _controller.loadSettings,
        ),
      ),
      SettingsView.noSettings => _shell(const NoSettingsView()),
      SettingsView.adminForm => _shell(
        AdminSettingsForm(
          form: _controller.form,
          authStatus: _controller.authStatus,
          smtpPasswordConfigured: _controller.smtpPasswordConfigured,
          settingsPasswordIsDefault: _controller.settingsPasswordIsDefault,
          onChanged: () => setState(() {}),
          onTestConnection: _controller.refreshAuthStatus,
          onSendTestMail: _controller.sendTestMail,
        ),
        saveBar: true,
      ),
    };
  }

  /// The error banner sits above whichever branch is showing.
  ///
  /// ⚠️ **Above, not inside the form.** The retry branch renders only a button;
  /// the sentence explaining why comes from here. Move this into the admin form
  /// and that branch becomes an unexplained button on a blank screen.
  ///
  /// It is also outside the scroll view, which is the other half of the fix: it
  /// used to be the first child of the `SingleChildScrollView`, so a failed save
  /// from the bottom of a long form showed the user nothing at all.
  Widget _shell(Widget body, {bool saveBar = false}) {
    final error = _controller.errorMessage;
    return Column(
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ContentWidth.form),
                child: ErrorBanner(error, onDismiss: _controller.dismissError),
              ),
            ),
          ),
        Expanded(child: body),
        if (saveBar)
          FormSaveBar(onSave: _controller.save, maxWidth: ContentWidth.form),
      ],
    );
  }
}
