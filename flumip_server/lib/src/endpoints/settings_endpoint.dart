import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/settings_service.dart';

/// Endpoint for handling settings-related operations.
class SettingsEndpoint extends Endpoint {
  get settingsService => SettingsService();

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \returns The retrieved [Settings] object.
  Future<Settings> getSettings(Session session) async {
    session.log("Retrieving settings", level: LogLevel.info);
    try {
      return settingsService.getSettings(session);
    } catch (e) {
      session.log("Error retrieving settings",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Updates the settings.
  ///
  /// \param session The current session.
  /// \param settings The [Settings] object to update.
  Future<void> updateSettings(Session session, Settings settings) async {
    session.log("Updating settings", level: LogLevel.info);
    try {
      return settingsService.updateSettings(session, settings);
    } catch (e) {
      session.log("Error updating settings",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
