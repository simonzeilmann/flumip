import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

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

  Future<Settings> getSettingsExternal(Session session, String? password) async {
    var settings = await getSettings(session);
    if (!_isAdmin(session, settings, password)) {
      throw ArgumentException(message: 'Invalid password');
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
  bool _isAdmin(Session session, Settings settings, String? password) {
    if (session.authenticated?.scopes.contains(adminScope) ?? false) return true;

    var enforcing = false;
    if (sl.isRegistered<AuthRuntime>()) {
      try {
        enforcing = sl<AuthRuntime>().isEnforcing;
      } catch (_) {
        enforcing = false;
      }
    }
    if (enforcing) return false;

    return password != null && password == settings.settingsPassword;
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
      await Settings.db.insertRow(session, Settings());
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
      await Settings.db.deleteWhere(session, where: (t) => t.id.notEquals(keep));
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
      ..baseDir = settings.baseDir
      ..projectDir = settings.projectDir
      ..genomeDir = settings.genomeDir
      ..customSnpDir = settings.customSnpDir
      ..snpSourceAllowedHosts = settings.snpSourceAllowedHosts
      ..toolsDir = settings.toolsDir
      ..mipgenExecutable = settings.mipgenExecutable
      ..exonExtractScript = settings.exonExtractScript
      ..ucscTrackGenerator = settings.ucscTrackGenerator
      ..binCreationScript = settings.binCreationScript
      ..bigGenePredToGenePredExecutable =
          settings.bigGenePredToGenePredExecutable
      ..mailActive = settings.mailActive
      ..smtpServer = settings.smtpServer
      ..smtpPort = settings.smtpPort
      ..smtpUser = settings.smtpUser
      ..smtpFrom = settings.smtpFrom
      ..startTLS = settings.startTLS
      ..loginRequired = settings.loginRequired
      ..settingsPassword = settings.settingsPassword
      ..oidcIssuer = settings.oidcIssuer
      ..oidcClientId = settings.oidcClientId
      ..oidcScopes = settings.oidcScopes
      ..oidcButtonLabel = settings.oidcButtonLabel
      ..oidcAllowedEmailDomains = settings.oidcAllowedEmailDomains
      ..oidcAdminEmails = settings.oidcAdminEmails
      ..authPublicUrl = settings.authPublicUrl;
    // oidcClientSecret is deliberately absent: it is serverOnly, so it arrives
    // as null from the client and is written only by setOidcClientSecret.

    await Settings.db.updateRow(session, stored);
    session.log("Settings updated successfully", level: LogLevel.info);
  }
}
