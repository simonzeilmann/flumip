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
    required this._loadAccess,
    required this._loadSettings,
    required this._saveSettings,
    required this._setSmtpPassword,
    required this._setOidcClientSecret,
    required this._setSettingsPassword,
    required this._smtpPasswordConfigured,
    required this._settingsPasswordIsDefault,
    required this._loadAuthStatus,
    required this._sendTestMail,
    required this._signOut,
    this._auth,
  }) {
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
  final Future<void> Function(String password, String newPassword)
  _setSettingsPassword;
  final Future<bool> Function(String password) _smtpPasswordConfigured;
  final Future<bool> Function(String password) _settingsPasswordIsDefault;
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
  bool _passwordIsDefault = false;
  String? _errorMessage;
  bool _disposed = false;

  final _messages = StreamController<String>.broadcast();

  Settings? get settings => _settings;
  AuthAdminStatusDto? get authStatus => _authStatus;
  bool get smtpPasswordConfigured => _smtpConfigured;

  /// Whether the settings password is still the shipped `changeme`.
  ///
  /// The tab warns when it is. Nothing used to warn, because the password was
  /// visible in its own box and an administrator could see for themselves; now
  /// that only a hash is stored, this is what replaces that.
  bool get settingsPasswordIsDefault => _passwordIsDefault;
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
      await _refreshSettingsPasswordStatus();
    } catch (e) {
      // ⚠️ `describeError`, never `'$e'`. A typed Serverpod exception stringifies
      // as `ArgumentException(message: …)` — the class name, the wrapper and the
      // sentence the server wrote, all shown to whoever typed the password. This
      // tab was the last place still doing that; the rest of the app has gone
      // through `describeError` since the project banners were written.
      _errorMessage = describeError(e);
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

      // ⚠️ Before the settings save, not after, and for two reasons.
      //
      // The credential this whole method authenticates with is
      // `form.password.text`, so the moment the server accepts a new one this
      // has to move over — the settings save immediately below is the first
      // thing that would otherwise present a password that no longer works.
      //
      // And the save has an early return: turning sign-in off ends every
      // session, including this one, and gives up on everything after it.
      // Changing the password at the end would mean an administrator who did
      // both in one save silently got only one.
      if (form.newPassword.text.isNotEmpty) {
        await _setSettingsPassword(form.password.text, form.newPassword.text);
        form.password.text = form.newPassword.text;
        form.newPassword.clear();
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
      _notify();

      await _refreshAuthStatus();
      await _refreshSmtpPasswordStatus();
      await _refreshSettingsPasswordStatus();
      _say('Settings updated successfully');
    } catch (e) {
      _errorMessage = describeError(e);
      _notify();
    }
  }

  Future<void> sendTestMail() async {
    final to = form.testMail.text.trim();
    if (to.isEmpty) {
      _errorMessage = 'Enter an address to send the test email to.';
      _notify();
      return;
    }
    try {
      await _sendTestMail(form.password.text, to);
      _errorMessage = null;
      _notify();
      _say('Test email sent to $to');
    } catch (e) {
      _errorMessage = describeError(e);
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

  Future<void> _refreshSettingsPasswordStatus() async {
    try {
      _passwordIsDefault = await _settingsPasswordIsDefault(form.password.text);
    } catch (_) {
      // Failing quiet, the same way as the SMTP status: a warning nobody can act
      // on because the call behind it failed is worse than no warning.
      _passwordIsDefault = false;
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
