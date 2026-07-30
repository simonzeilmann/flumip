import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/mail_service.dart';
import '../services/settings_service.dart';

/// Endpoint for handling settings-related operations.
///
/// Deliberately **not** a [FlumipEndpoint]: this endpoint is how single sign-on
/// gets switched off, so putting it behind a login would make a misconfiguration
/// unrecoverable from the UI. Every method here gates itself instead, on either
/// the settings password or an authenticated admin session.
class SettingsEndpoint extends Endpoint {
  /// Instance of the settings service.
  SettingsService get settingsService => SettingsService();

  /// Instance of the mail service.
  MailService get mailService => MailService();

  /// Retrieves the settings.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \returns The retrieved [Settings] object.
  Future<Settings> getSettings(Session session, String? password) async {
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
  /// Gated like [getSettings]: the settings hold the SMTP credentials and the
  /// settings password itself, so writing them must be authenticated.
  ///
  /// The authentication configuration is re-read afterwards, so switching single
  /// sign-on on or off takes effect immediately rather than on the next refresh
  /// tick.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param settings The [Settings] object to update.
  Future<void> updateSettings(
    Session session,
    String? password,
    Settings settings,
  ) async {
    session.log("Updating settings", level: LogLevel.info);
    try {
      // Validates the caller; throws ArgumentException('Invalid password') when
      // neither the password nor an admin session authorises this.
      await settingsService.requireAdmin(session, password);
      await settingsService.updateSettings(session, settings);
      await sl<AuthRuntime>().broadcastConfigChange(session);
    } on ArgumentException {
      rethrow;
    } catch (e) {
      session.log("Error updating settings",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Sets the OIDC client secret.
  ///
  /// Separate from [updateSettings] because the secret is write-only: it is a
  /// `serverOnly` field, so it never travels to the browser and cannot be part of
  /// the [Settings] object the settings tab sends back. Passing an empty string
  /// clears it.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param secret The new client secret.
  Future<void> setOidcClientSecret(
    Session session,
    String? password,
    String secret,
  ) async {
    session.log("Setting the OIDC client secret", level: LogLevel.info);
    try {
      await settingsService.requireAdmin(session, password);
      final settings = await settingsService.getSettings(session);
      settings.oidcClientSecret = secret.trim().isEmpty ? null : secret.trim();
      await Settings.db.updateRow(session, settings);
      await sl<AuthRuntime>().broadcastConfigChange(session);
    } on ArgumentException {
      rethrow;
    } catch (e) {
      session.log("Error setting the OIDC client secret",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Everything the settings tab needs to show about the SSO setup that is not
  /// itself a stored setting.
  ///
  /// Runs a live discovery probe, mirroring how [sendTestMail] validates the SMTP
  /// configuration — the point is to fail here, with a readable message, rather
  /// than at someone's first sign-in attempt.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  Future<AuthAdminStatusDto> getAuthAdminStatus(
    Session session,
    String? password,
  ) async {
    await settingsService.requireAdmin(session, password);
    final runtime = sl<AuthRuntime>();
    // Re-resolve so the answer reflects the environment as it is now, not as of
    // the last refresh tick.
    await runtime.refresh(session);
    final config = runtime.config;

    var discovery = runtime.discovery;
    var error = runtime.discoveryError;
    if (config.isComplete && discovery == null) {
      // refresh() only probes when login is required; probe anyway so an admin
      // can validate the configuration before switching it on.
      try {
        discovery = await sl<OidcClient>().discover(config.issuer);
        error = null;
      } catch (e) {
        error = '$e';
      }
    }

    return AuthAdminStatusDto(
      enabled: config.loginRequired,
      enforcing: runtime.isEnforcing,
      secretConfigured: config.clientSecret.isNotEmpty,
      envOverrides: config.envOverrides,
      redirectUri: config.redirectUri,
      discoveryOk: discovery != null,
      discoveryError: error,
      authorizationEndpoint: discovery?.authorizationEndpoint,
      tokenEndpoint: discovery?.tokenEndpoint,
    );
  }

  /// Sends a test email so the SMTP configuration can be validated.
  ///
  /// \param session The current session.
  /// \param password The settings password, or null to rely on an admin session.
  /// \param to The recipient address.
  Future<void> sendTestMail(
    Session session,
    String? password,
    String to,
  ) async {
    session.log("Sending test mail", level: LogLevel.info);
    try {
      await settingsService.requireAdmin(session, password);
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
