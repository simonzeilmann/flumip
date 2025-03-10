import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';

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
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
    );
    if (settings.isEmpty || settings.length != 1) {
      session.log("Failed to load settings", level: LogLevel.error);
      throw Exception('Failed to load settings');
    }
    session.log("Settings retrieved successfully", level: LogLevel.info);
    return settings.first;
  }

  /// Checks if the settings exist in the database and creates them if they do not.
  ///
  /// \param session The current session.
  Future<void> _checkAndCreateSettings(Session session) async {
    session.log("Checking and creating settings if necessary",
        level: LogLevel.info);
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
    );
    if (settings.isEmpty || settings.length != 1) {
      session.log(
          "Settings not found or multiple settings found, resetting settings",
          level: LogLevel.warning);
      await Settings.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await Settings.db.insertRow(session, Settings());
      session.log("Settings created successfully", level: LogLevel.info);
    }
  }

  /// Updates the settings in the database.
  ///
  /// \param session The current session.
  /// \param settings The [Settings] object to update.
  Future<void> updateSettings(Session session, Settings settings) async {
    session.log("Updating settings", level: LogLevel.info);
    await Settings.db.updateRow(session, settings);
    session.log("Settings updated successfully", level: LogLevel.info);
  }
}
