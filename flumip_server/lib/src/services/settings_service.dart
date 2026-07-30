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

  Future<Settings> getSettingsExternal(Session session, String password) async {
    var settings = await getSettings(session);
    if (settings.settingsPassword != password) {
      throw ArgumentException(message: 'Invalid password');
    }
    return settings;
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
      ..smtpPassword = settings.smtpPassword
      ..smtpFrom = settings.smtpFrom
      ..startTLS = settings.startTLS
      ..loginRequired = settings.loginRequired
      ..settingsPassword = settings.settingsPassword;

    await Settings.db.updateRow(session, stored);
    session.log("Settings updated successfully", level: LogLevel.info);
  }
}
