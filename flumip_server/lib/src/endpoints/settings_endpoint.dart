import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/mail_service.dart';
import '../services/settings_service.dart';

/// Endpoint for handling settings-related operations.
///
/// Deliberately **not** a [FlumipEndpoint]: [userSettings] has to answer before
/// the app knows anything, and the password route below has to keep working on
/// an install with no identities at all.
///
/// Every method gates itself instead, on an authenticated admin session or — only
/// while sign-in is not being enforced — the settings password. See
/// `SettingsService._isAdmin` for what that trades away, and for the escape that
/// is left when the identity provider is the thing that broke.
class SettingsEndpoint extends Endpoint {
  /// Instance of the settings service.
  SettingsService get settingsService => SettingsService();

  /// Instance of the mail service.
  MailService get mailService => MailService();

  /// What the calling user may see, and how they may get in.
  ///
  /// Answered for **anyone**, signed in or not, and deliberately leaks nothing:
  /// two booleans the app needs before it can decide what to draw. Without it
  /// the Settings tab has to guess — which is what produced the behaviour this
  /// replaced, where an administrator was shown a password box for a password
  /// they did not need, and a user was shown one that would have worked.
  ///
  /// **The extension point for per-user settings**: see [UserSettingsDto].
  ///
  /// \param session The current session.
  Future<UserSettingsDto> userSettings(Session session) async {
    final isAdmin = session.authenticated?.scopes.contains(adminScope) ?? false;
    return UserSettingsDto(
      isAdmin: isAdmin,
      // Not simply !enforcing: an admin never needs the box, so saying the
      // password is accepted would offer them a route they have no use for.
      passwordAccepted: !isAdmin && !_isEnforcing(),
    );
  }

  /// Mirrors `FlumipEndpoint.requireLogin`, including its refusal to throw.
  bool _isEnforcing() {
    if (!sl.isRegistered<AuthRuntime>()) return false;
    try {
      return sl<AuthRuntime>().isEnforcing;
    } catch (_) {
      return false;
    }
  }

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

      // Read before writing, so the transition can be detected rather than
      // inferred from the incoming object — which may not be what actually gets
      // stored, since updateSettings merges an explicit field list.
      final wasRequiringLogin =
          (await settingsService.getSettings(session)).loginRequired;

      await settingsService.updateSettings(session, settings);
      await sl<AuthRuntime>().broadcastConfigChange(session);

      final nowRequiringLogin =
          (await settingsService.getSettings(session)).loginRequired;
      if (wasRequiringLogin && !nowRequiringLogin) {
        // Switching sign-in off ends every session, the caller's included.
        // Otherwise the tokens issued while it was on stay valid for their full
        // lifetime, so the app goes on showing people as signed in — and an
        // administrator as an administrator — on a server that no longer
        // authenticates anyone. The admin who threw the switch is logged out
        // too, which is the point: there is nothing left to be signed in to.
        final ended = await sl<AuthService>().revokeAllSessions(session);
        session.log(
          'Sign-in switched off; ended $ended session(s).',
          level: LogLevel.info,
        );
      }
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
