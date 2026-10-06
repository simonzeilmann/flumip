import 'dart:convert';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/password_hash.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// What a brand-new install's settings password is, before anybody changes it.
///
/// Stored hashed like any other, so this constant is the only place the word
/// appears — `settingsPasswordIsDefault` is what tells the settings tab to nag
/// about it.
const defaultSettingsPassword = 'changeme';

/// How long a project survives on a demo install.
///
/// Clamped, because the value is typed into a settings box and both ends are
/// reachable by accident. Zero or negative would delete a project the instant it
/// was created — including the one whose creation scheduled the call — and an
/// absurd figure would schedule a future call so far out that it is effectively
/// a leak. One hour to a year.
Duration demoRetention(Settings settings) {
  final hours = settings.demoModeRetentionHours.clamp(1, 24 * 365);
  return Duration(hours: hours);
}

/// A service class for handling settings-related operations.
class SettingsService {
  SettingsService();

  /// Retrieves the settings from the database.
  ///
  /// \param session The current session.
  /// \returns The retrieved [Settings] object.
  /// \throws [Exception] if the settings could not be loaded.
  Future<Settings> getSettings(Session session) async {
    session.log("Retrieving settings", level: LogLevel.info);
    await _checkAndCreateSettings(session);
    var settings = await Settings.db.find(session, where: (t) => t.id > 0);
    if (settings.isEmpty) {
      session.log("Failed to load settings", level: LogLevel.error);
      throw Exception('Failed to load settings');
    }
    session.log("Settings retrieved successfully", level: LogLevel.info);
    return settings.first;
  }

  Future<Settings> getSettingsExternal(
    Session session,
    String? password,
  ) async {
    var settings = await getSettings(session);
    if (!await _isAdmin(session, settings, password)) {
      throw ArgumentException(message: 'This password is not correct.');
    }
    return settings;
  }

  /// Throws unless the caller may administer this server.
  ///
  /// Use this for operations that need admin rights but must not read the
  /// settings out — notably writing the OIDC client secret, which is write-only.
  Future<void> requireAdmin(Session session, String? password) async {
    await getSettingsExternal(session, password);
  }

  /// Either a signed-in session whose email is on the admin list, or — **only
  /// while sign-in is not being enforced** — the settings password.
  ///
  /// Once single sign-on is enforcing, the password stops being accepted
  /// entirely. Identity is then the only way in, so a user who happens to know
  /// the shared password cannot use it to reach an administrator's settings.
  ///
  /// ⚠️ **This trades away part of the lockout escape**, knowingly. The password
  /// used to work regardless, precisely because the identity provider can be the
  /// thing that is broken. What is left:
  ///
  /// - A provider that has **never** answered discovery leaves `isEnforcing`
  ///   false — the fail-open rule — so the password still works. This is the
  ///   common misconfiguration, and it is still recoverable from the UI.
  /// - A provider that answered once and **then** broke keeps enforcing from the
  ///   cached document. Nobody can sign in, and the password no longer helps.
  ///   Recovery is `FLUMIP_AUTH_ENABLED=false` plus a restart, or
  ///   `UPDATE settings SET "loginRequired" = false;`. Both are in
  ///   docs/authentication.md and HANDOFF.md.
  ///
  /// Never throws on the runtime lookup, for the reason given on
  /// `FlumipEndpoint.requireLogin`: a half-initialised process must not turn
  /// every settings call into a 500. An unavailable runtime means "not
  /// enforcing", which keeps the password working — the safe direction, since
  /// the alternative is a server nobody can configure.
  ///
  /// ⚠️ **An admin session short-circuits before any hashing happens.** That is
  /// worth keeping: verifying a PBKDF2 hash costs a few hundred milliseconds by
  /// design, and a signed-in administrator never supplies a password at all.
  Future<bool> _isAdmin(
    Session session,
    Settings settings,
    String? password,
  ) async {
    if (session.authenticated?.scopes.contains(adminScope) ?? false) {
      return true;
    }

    var enforcing = false;
    if (sl.isRegistered<AuthRuntime>()) {
      try {
        enforcing = sl<AuthRuntime>().isEnforcing;
      } catch (_) {
        enforcing = false;
      }
    }
    if (enforcing) return false;

    if (password == null) return false;
    final stored = settings.settingsPassword;
    if (stored == null || stored.isEmpty) return false;

    if (looksLikePasswordHash(stored)) {
      return verifyPassword(password, stored);
    }

    // Everything below is the one-way door out of plaintext.
    //
    // An install created before hashing still has its password sitting in the
    // column as typed. It has to keep working — this is the credential that gets
    // an administrator back into a server whose identity provider is broken, and
    // silently invalidating it on upgrade would be a lockout delivered by
    // deployment. So it is accepted once, and the accepting is what replaces it.
    //
    // ⚠️ The upgrade writes only this column. `updateRow` would otherwise write
    // every field of the row we happen to be holding, and this runs inside a
    // *read* — a settings save landing concurrently would be silently rolled
    // back to whatever this session loaded.
    if (!constantTimeEquals(utf8.encode(password), utf8.encode(stored))) {
      return false;
    }

    settings.settingsPassword = hashPassword(password);
    await Settings.db.updateRow(
      session,
      settings,
      columns: (t) => [t.settingsPassword],
    );
    session.log(
      "Replaced the plaintext settings password with a hash",
      level: LogLevel.info,
    );
    return true;
  }

  /// Ensures exactly one settings row exists, without ever discarding it.
  ///
  /// An existing row is never deleted. It holds the settings password and (once
  /// SSO is configured) the OIDC credentials, so replacing it with defaults
  /// would silently restore `settingsPassword = "changeme"` and
  /// `loginRequired = false` — reverting an authenticated install to wide-open
  /// access with a publicly known admin password.
  ///
  /// \param session The current session.
  Future<void> _checkAndCreateSettings(Session session) async {
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
      orderBy: (t) => t.id,
    );

    if (settings.isEmpty) {
      session.log("No settings found, creating defaults", level: LogLevel.info);
      // ⚠️ The settings password is seeded here rather than as a model default,
      // because a hash cannot be written into the yaml. A fresh install with a
      // null column would have no break-glass credential at all, so — with
      // single sign-on off, which is the default — nobody could open the
      // settings tab to configure the server they just installed.
      await Settings.db.insertRow(
        session,
        Settings(settingsPassword: hashPassword(defaultSettingsPassword)),
      );
      return;
    }

    if (settings.length > 1) {
      // Keep the oldest row — it is the one the install has been using — and
      // drop the duplicates rather than resetting everything to defaults.
      final keep = settings.first.id!;
      session.log(
        "Found ${settings.length} settings rows, keeping id $keep and "
        "deleting the duplicates",
        level: LogLevel.warning,
      );
      await Settings.db.deleteWhere(
        session,
        where: (t) => t.id.notEquals(keep),
      );
    }
  }

  /// Updates the settings in the database.
  ///
  /// Merges [settings] into the stored row instead of replacing it: only the
  /// fields listed here are taken from the client. Everything else keeps its
  /// stored value.
  ///
  /// This matters for two reasons. The Flutter settings tab builds a fresh
  /// [Settings] object from its text controllers, so any field it does not
  /// populate would otherwise be written back as its *default* on every save.
  /// And [Settings.oidcClientSecret] is `serverOnly`, so it is absent from the
  /// object the client sends and can only be written through
  /// `SettingsEndpoint.setOidcClientSecret`.
  ///
  /// \param session The current session.
  /// \param settings The [Settings] object to merge in.
  Future<void> updateSettings(Session session, Settings settings) async {
    session.log("Updating settings", level: LogLevel.info);
    final stored = await getSettings(session);

    stored
      ..demoMode = settings.demoMode
      ..demoModeRetentionHours = settings.demoModeRetentionHours
      ..baseDir = settings.baseDir
      ..projectDir = settings.projectDir
      ..genomeDir = settings.genomeDir
      ..customSnpDir = settings.customSnpDir
      ..snpSourceAllowedHosts = settings.snpSourceAllowedHosts
      ..toolsDir = settings.toolsDir
      ..mipgenExecutable = settings.mipgenExecutable
      ..exonExtractScript = settings.exonExtractScript
      ..bigGenePredToGenePredExecutable =
          settings.bigGenePredToGenePredExecutable
      ..mailActive = settings.mailActive
      ..smtpServer = settings.smtpServer
      ..smtpPort = settings.smtpPort
      ..smtpUser = settings.smtpUser
      ..smtpFrom = settings.smtpFrom
      ..startTLS = settings.startTLS
      ..loginRequired = settings.loginRequired
      ..oidcIssuer = settings.oidcIssuer
      ..oidcClientId = settings.oidcClientId
      ..oidcScopes = settings.oidcScopes
      ..oidcButtonLabel = settings.oidcButtonLabel
      ..oidcAllowedEmailDomains = settings.oidcAllowedEmailDomains
      ..oidcAdminEmails = settings.oidcAdminEmails
      ..authPublicUrl = settings.authPublicUrl;
    // oidcClientSecret is deliberately absent: it is serverOnly, so it arrives
    // as null from the client and is written only by setOidcClientSecret.

    // settingsPassword is deliberately absent, alongside oidcClientSecret: it is
    // serverOnly, arrives as null from the client, and is written only by
    // setSettingsPassword.

    await Settings.db.updateRow(session, stored);
    session.log("Settings updated successfully", level: LogLevel.info);
  }

  /// Replaces the settings password, which is stored hashed.
  ///
  /// ⚠️ **An empty password is refused rather than stored**, unlike the SMTP
  /// password and the OIDC client secret, where empty means "clear it". Those
  /// two are optional; this one is the way back into a server whose identity
  /// provider has broken. Clearing it would leave an install with single sign-on
  /// off and no way to reach its own settings, recoverable only by editing the
  /// database directly.
  ///
  /// \throws [ArgumentException] if [newPassword] is empty or only whitespace.
  Future<void> setSettingsPassword(Session session, String newPassword) async {
    if (newPassword.trim().isEmpty) {
      throw ArgumentException(
        message:
            'The settings password cannot be blank. Type the password you '
            'want to use, or leave the box empty to keep the current one.',
      );
    }

    final settings = await getSettings(session);
    settings.settingsPassword = hashPassword(newPassword);
    await Settings.db.updateRow(
      session,
      settings,
      columns: (t) => [t.settingsPassword],
    );
    session.log("Settings password changed", level: LogLevel.info);
  }

  /// Whether the settings password is still `changeme`.
  ///
  /// The settings tab used to show the password in a box, so "this install is
  /// still on the shipped default" was visible by reading it. Hashing takes that
  /// away, and saying nothing would leave the default quietly in place on every
  /// install that never got round to changing it — so the tab asks instead.
  ///
  /// Nothing is leaked by answering: only an administrator can get this far.
  Future<bool> settingsPasswordIsDefault(Session session) async {
    final stored = (await getSettings(session)).settingsPassword;
    if (stored == null || stored.isEmpty) return false;
    // A row that predates hashing still holds the password as typed, and it is
    // just as much the default when it says so in plaintext.
    if (!looksLikePasswordHash(stored)) {
      return stored == defaultSettingsPassword;
    }
    return verifyPassword(defaultSettingsPassword, stored);
  }
}
