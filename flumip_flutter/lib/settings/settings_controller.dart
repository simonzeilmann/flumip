import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import '../error_text.dart';
import 'settings_form.dart';

/// Which of the five things the settings tab can be showing.
///
/// ⚠️ **The order these are decided in is the whole point**, and getting it
/// wrong produced the two bugs this replaced: an administrator shown a password
/// box for a password they did not need, and an ordinary user shown one that
/// worked. Derived once, here, where a test can check every branch.
enum SettingsView {
  /// The access question has not been answered yet.
  loading,

  /// The access question itself failed. Offers a retry, never a password box.
  retry,

  /// Sign-in is not being enforced, so the settings password still opens this.
  passwordGate,

  /// A signed-in non-administrator. There is nothing here for them.
  noSettings,

  /// The real thing.
  adminForm,
}

/// Server configuration: who may see it, what it currently is, and what happens
/// when it is saved.
///
/// Every piece of I/O is a constructor parameter, so this runs on the Dart VM
/// with no server. It owns the [SettingsForm] as well, because the read half and
/// the write half only mean anything together — see the warnings there.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required Future<UserSettingsDto> Function() loadAccess,
    required Future<Settings> Function(String password) loadSettings,
    required Future<void> Function(String password, Settings settings)
    saveSettings,
    required Future<void> Function(String password, String smtpPassword)
    setSmtpPassword,
    required Future<void> Function(String password, String secret)
    setOidcClientSecret,
    required Future<bool> Function(String password) smtpPasswordConfigured,
    required Future<AuthAdminStatusDto> Function(String password)
    loadAuthStatus,
    required Future<void> Function(String password, String to) sendTestMail,
    required void Function() signOut,
    Listenable? auth,
  }) : _loadAccess = loadAccess,
       _loadSettings = loadSettings,
       _saveSettings = saveSettings,
       _setSmtpPassword = setSmtpPassword,
       _setOidcClientSecret = setOidcClientSecret,
       _smtpPasswordConfigured = smtpPasswordConfigured,
       _loadAuthStatus = loadAuthStatus,
       _sendTestMail = sendTestMail,
       _signOut = signOut,
       _auth = auth {
    // ⚠️ Asked again whenever sign-in state changes, not just once.
    //
    // TabBarView builds all three tabs when the app starts, so the first answer
    // describes an anonymous caller — `isAdmin: false`, and on an install that is
    // not enforcing, `passwordAccepted: true`. Caching that was the bug: an
    // administrator was shown a password box, and so was everyone else, because
    // the question had been asked before there was anybody to ask about.
    _auth?.addListener(_onAuthChanged);
  }

  final Future<UserSettingsDto> Function() _loadAccess;
  final Future<Settings> Function(String password) _loadSettings;
  final Future<void> Function(String password, Settings settings) _saveSettings;
  final Future<void> Function(String password, String smtpPassword)
  _setSmtpPassword;
  final Future<void> Function(String password, String secret)
  _setOidcClientSecret;
  final Future<bool> Function(String password) _smtpPasswordConfigured;
  final Future<AuthAdminStatusDto> Function(String password) _loadAuthStatus;
  final Future<void> Function(String password, String to) _sendTestMail;
  final void Function() _signOut;
  final Listenable? _auth;

  /// ⚠️ Created once and never rebuilt — every warning on [SettingsForm] depends
  /// on that, and all three of them fail *silently*.
  final form = SettingsForm();

  UserSettingsDto? _access;
  bool _accessFailed = false;
  Settings? _settings;
  AuthAdminStatusDto? _authStatus;
  bool _smtpConfigured = false;
  String? _errorMessage;
  bool _disposed = false;

  final _messages = StreamController<String>.broadcast();

  Settings? get settings => _settings;
  AuthAdminStatusDto? get authStatus => _authStatus;
  bool get smtpPasswordConfigured => _smtpConfigured;
  String? get errorMessage => _errorMessage;

  /// One-off reports — the tab turns these into snack bars.
  Stream<String> get messages => _messages.stream;

  /// What the tab should be showing.
  ///
  /// ⚠️ The order of these tests is load-bearing; see [SettingsView].
  SettingsView get view {
    if (_settings != null) return SettingsView.adminForm;
    if (_accessFailed) return SettingsView.retry;
    if (_access == null) return SettingsView.loading;
    // Only reachable when sign-in is not being enforced. Once it is, the server
    // stops accepting the password, so offering the box would be offering
    // something that cannot work.
    if (_access!.passwordAccepted) return SettingsView.passwordGate;
    return SettingsView.noSettings;
  }

  Future<void> load() => loadAccess();

  Future<void> loadAccess() async {
    try {
      final access = await _loadAccess();
      _access = access;
      _accessFailed = false;
      _notify();
      // An administrator needs no password, so there is nothing to ask for: load
      // straight away rather than making them click through a box that would
      // have accepted an empty string.
      if (access.isAdmin) await loadSettings();
    } catch (e) {
      // ⚠️ Deliberately NOT falling back to the password form. Doing that turns
      // every transient failure into "type a password" — indistinguishable from
      // a real prompt, and the reason the earlier bug was so hard to read.
      _accessFailed = true;
      _errorMessage = 'Could not determine your access: ${describeError(e)}';
      _notify();
    }
  }

  Future<void> loadSettings() async {
    try {
      final loaded = await _loadSettings(form.password.text);
      _errorMessage = null;
      _settings = loaded;
      form.load(loaded);
      _notify();
      await _refreshAuthStatus();
      await _refreshSmtpPasswordStatus();
    } on ArgumentException catch (e) {
      _errorMessage = e.message;
      _notify();
    } catch (e) {
      _errorMessage = '$e';
      _notify();
    }
  }

  Future<void> save() async {
    try {
      final updated = form.toSettings(id: _settings!.id);

      // Authenticated with the password the settings were loaded with; a new
      // password in `settingsPassword` only takes effect after this succeeds.
      //
      // ⚠️ Both secrets are sent *before* the settings, so that switching SSO on
      // in the same save finds the secret already in place rather than refusing
      // as incomplete. Neither can travel in the Settings object: both are
      // serverOnly with no client-side counterpart. Typing something replaces
      // what is stored; leaving the box empty keeps it, which is why an
      // unrelated save cannot blank either by accident.
      if (form.smtpPassword.text.isNotEmpty) {
        await _setSmtpPassword(form.password.text, form.smtpPassword.text);
        form.smtpPassword.clear();
        _smtpConfigured = true;
      }

      if (form.oidcClientSecret.text.isNotEmpty) {
        await _setOidcClientSecret(
          form.password.text,
          form.oidcClientSecret.text,
        );
        form.oidcClientSecret.clear();
      }

      // Captured before the save, because that is what makes this a transition
      // rather than just a value.
      final wasRequiringLogin = _settings!.loginRequired;

      await _saveSettings(form.password.text, updated);

      if (wasRequiringLogin && !updated.loginRequired) {
        // ⚠️ The server has just ended every session, this one included — there
        // is nothing left to be signed in to. Navigating to /auth/logout clears
        // the HttpOnly cookie (only the server can) and reloads the app, which
        // then bootstraps into the no-authentication state it has now got.
        //
        // Returning here on purpose: everything below assumes a session that no
        // longer exists, and the status re-reads would simply fail.
        _signOut();
        return;
      }

      _errorMessage = null;
      _settings = updated;
      // The password may have just been changed; keep the one we authenticate
      // with in sync so subsequent saves and test mails still work.
      form.password.text = updated.settingsPassword;
      _notify();

      await _refreshAuthStatus();
      await _refreshSmtpPasswordStatus();
      _say('Settings updated successfully');
    } catch (e) {
      _errorMessage = '$e';
      _notify();
    }
  }

  Future<void> sendTestMail() async {
    final to = form.testMail.text.trim();
    if (to.isEmpty) {
      _errorMessage = 'Enter a recipient address for the test email';
      _notify();
      return;
    }
    try {
      await _sendTestMail(form.password.text, to);
      _errorMessage = null;
      _notify();
      _say('Test email sent to $to');
    } catch (e) {
      _errorMessage = '$e';
      _notify();
    }
  }

  /// Re-reads the SSO status, including a live discovery probe.
  ///
  /// Failure is not fatal — the rest of the tab still works — so this only
  /// clears the panel rather than showing an error banner.
  Future<void> refreshAuthStatus() => _refreshAuthStatus();

  Future<void> _refreshAuthStatus() async {
    try {
      _authStatus = await _loadAuthStatus(form.password.text);
    } catch (_) {
      _authStatus = null;
    }
    _notify();
  }

  Future<void> _refreshSmtpPasswordStatus() async {
    try {
      _smtpConfigured = await _smtpPasswordConfigured(form.password.text);
    } catch (_) {
      // Not knowing is not the same as knowing there is none, but the only cost
      // of guessing low here is slightly more cautious wording.
      _smtpConfigured = false;
    }
    _notify();
  }

  /// Whatever was decided for the previous identity no longer applies.
  ///
  /// ⚠️ Drops the loaded settings too: signing out must not leave an
  /// administrator's configuration on screen.
  void _onAuthChanged() {
    _access = null;
    _settings = null;
    _errorMessage = null;
    _notify();
    loadAccess();
  }

  void dismissError() {
    _errorMessage = null;
    _notify();
  }

  void _say(String message) {
    if (_disposed) return;
    _messages.add(message);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth?.removeListener(_onAuthChanged);
    _messages.close();
    form.dispose();
    super.dispose();
  }
}
