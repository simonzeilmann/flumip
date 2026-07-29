import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/mail_service.dart';
import '../services/settings_service.dart';

/// Endpoint for handling settings-related operations.
class SettingsEndpoint extends Endpoint {
  /// Instance of the settings service.
  SettingsService get settingsService => SettingsService();

  /// Instance of the mail service.
  MailService get mailService => MailService();

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \param password The password for authentication.
  /// \returns The retrieved [Settings] object.
  Future<Settings> getSettings(Session session, String password) async {
    session.log("Retrieving settings", level: LogLevel.info);
    try {
      return settingsService.getSettingsExternal(session, password);
    }
    on ArgumentException {
      rethrow;
    }
    catch (e) {
      session.log("Error retrieving settings",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Updates the settings.
  ///
  /// Password-gated like [getSettings]: the settings hold the SMTP credentials
  /// and the settings password itself, so writing them must be authenticated.
  ///
  /// \param session The current session.
  /// \param password The password for authentication.
  /// \param settings The [Settings] object to update.
  Future<void> updateSettings(
    Session session,
    String password,
    Settings settings,
  ) async {
    session.log("Updating settings", level: LogLevel.info);
    try {
      // Validates the supplied password against the stored one; throws
      // ArgumentException('Invalid password') when it does not match.
      await settingsService.getSettingsExternal(session, password);
      return await settingsService.updateSettings(session, settings);
    } on ArgumentException {
      rethrow;
    } catch (e) {
      session.log("Error updating settings",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Sends a test email so the SMTP configuration can be validated.
  ///
  /// \param session The current session.
  /// \param password The password for authentication.
  /// \param to The recipient address.
  Future<void> sendTestMail(
    Session session,
    String password,
    String to,
  ) async {
    session.log("Sending test mail", level: LogLevel.info);
    try {
      await settingsService.getSettingsExternal(session, password);
      return await mailService.sendTestMail(session, to);
    } on ArgumentException {
      rethrow;
    } catch (e) {
      session.log("Error sending test mail",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}