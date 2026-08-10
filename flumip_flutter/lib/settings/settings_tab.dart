import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../error_text.dart';
import '../main.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import 'admin_settings_form.dart';
import 'settings_access_views.dart';
import 'settings_form.dart';

/// Server configuration, for whoever is allowed to see it.
///
/// This file is the parts that talk to the server: what the caller may see, what
/// the settings currently are, and what happens when they are saved. The fields
/// themselves are in `settings_form.dart` (the values) and
/// `admin_settings_form.dart` (the five sections).
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  /// ⚠️ Created once, never rebuilt — see the warning on [SettingsForm]. Three
  /// of its controllers carry state that a per-build instance would silently
  /// lose.
  final _form = SettingsForm();

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

  /// What the server reports about the SSO setup that is not itself a setting.
  AuthAdminStatusDto? _authStatus;

  /// Whether the server holds an SMTP password. The password itself is never
  /// sent, so without this an empty box would be indistinguishable from none.
  bool _smtpPasswordConfigured = false;

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

  @override
  void dispose() {
    authController.removeListener(_onAuthChanged);
    _form.dispose();
    super.dispose();
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
      // An administrator needs no password, so there is nothing to ask for: load
      // straight away rather than making them click through a box that would
      // have accepted an empty string.
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

  Future<void> _loadSettings() async {
    try {
      final loaded = await client.settings.getSettings(_form.password.text);
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        settings = loaded;
        _form.load(loaded);
      });
      await _loadAuthStatus();
      await _loadSmtpPasswordStatus();
    } on ArgumentException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    }
  }

  Future<void> updateSettings() async {
    try {
      final updated = _form.toSettings(id: settings!.id);

      // Authenticated with the password the settings were loaded with; a new
      // password in `settingsPassword` only takes effect after this succeeds.
      //
      // ⚠️ Both secrets are sent *before* updateSettings, so that switching SSO
      // on in the same save finds the secret already in place rather than
      // refusing as incomplete. Neither can travel in the Settings object: both
      // are serverOnly fields with no client-side counterpart. Typing something
      // replaces what is stored; leaving the box empty keeps it, which is why an
      // unrelated save cannot blank either by accident.
      if (_form.smtpPassword.text.isNotEmpty) {
        await client.settings.setSmtpPassword(
          _form.password.text,
          _form.smtpPassword.text,
        );
        _form.smtpPassword.clear();
        _smtpPasswordConfigured = true;
      }

      if (_form.oidcClientSecret.text.isNotEmpty) {
        await client.settings.setOidcClientSecret(
          _form.password.text,
          _form.oidcClientSecret.text,
        );
        _form.oidcClientSecret.clear();
      }

      // Captured before the save, because that is what makes this a transition
      // rather than just a value.
      final wasRequiringLogin = settings!.loginRequired;

      await client.settings.updateSettings(_form.password.text, updated);

      if (wasRequiringLogin && !updated.loginRequired) {
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
        settings = updated;
        // The password may have just been changed; keep the one we authenticate
        // with in sync so subsequent saves and test mails still work.
        _form.password.text = updated.settingsPassword;
      });
      await _loadAuthStatus();
      await _loadSmtpPasswordStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    }
  }

  Future<void> _loadSmtpPasswordStatus() async {
    try {
      final configured = await client.settings.smtpPasswordConfigured(
        _form.password.text,
      );
      if (!mounted) return;
      setState(() => _smtpPasswordConfigured = configured);
    } catch (_) {
      // Not knowing is not the same as knowing there is none, but the only cost
      // of guessing low here is slightly more cautious wording.
      if (!mounted) return;
      setState(() => _smtpPasswordConfigured = false);
    }
  }

  /// Re-reads the SSO status, including a live discovery probe.
  ///
  /// Failure is not fatal — the rest of the settings tab still works — so this
  /// only clears the panel rather than showing an error banner.
  Future<void> _loadAuthStatus() async {
    try {
      final status = await client.settings.getAuthAdminStatus(
        _form.password.text,
      );
      if (!mounted) return;
      setState(() => _authStatus = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _authStatus = null);
    }
  }

  Future<void> sendTestMail() async {
    final to = _form.testMail.text.trim();
    if (to.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a recipient address for the test email';
      });
      return;
    }
    try {
      await client.settings.sendTestMail(_form.password.text, to);
      if (!mounted) return;
      setState(() => _errorMessage = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test email sent to $to')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    }
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
          controller: _form.password,
          onSubmit: _loadSettings,
        ),
      );
    }
    if (settings == null) return _shell(const NoSettingsView());

    return _shell(
      AdminSettingsForm(
        form: _form,
        authStatus: _authStatus,
        smtpPasswordConfigured: _smtpPasswordConfigured,
        onChanged: () => setState(() {}),
        onTestConnection: _loadAuthStatus,
        onSendTestMail: sendTestMail,
      ),
      saveBar: true,
    );
  }

  /// The error banner sits above whichever branch is showing.
  ///
  /// ⚠️ **Above, not inside the form.** The `_accessFailed` branch renders only a
  /// button; the sentence explaining why comes from here. Move this into the
  /// admin form and that branch becomes an unexplained button on a blank screen.
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
                constraints: const BoxConstraints(maxWidth: ContentWidth.form),
                child: ErrorBanner(
                  _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ),
            ),
          ),
        Expanded(child: body),
        if (saveBar)
          FormSaveBar(onSave: updateSettings, maxWidth: ContentWidth.form),
      ],
    );
  }
}
