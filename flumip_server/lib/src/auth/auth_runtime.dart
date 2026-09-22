import 'dart:async';
import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/auth/oidc_discovery.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';

/// The in-memory view of the authentication configuration.
///
/// It exists because [Endpoint.requireLogin] is a *synchronous* getter that
/// Serverpod reads on every single call, so the gate cannot do a database round
/// trip. This holds the answer, refreshed when the settings are saved and on a
/// timer.
///
/// Process-local by design. The propagation points are isolated in
/// [broadcastConfigChange] and [AuthService.broadcastRevocation] so that moving
/// to several server processes later is a change in two methods plus
/// `redis: enabled: true`, rather than a refactor of every call site. Today both
/// systemd units run a single `--role=monolith` process with one `--server-id`
/// and no load balancer, so there is exactly one cache to keep coherent and
/// Redis would add a network hop and a failure mode for no behavioural gain.
class AuthRuntime {
  AuthRuntime({
    this.refreshInterval = const Duration(seconds: 30),
    this._environment,
  });

  /// How often the configuration and discovery document are re-read.
  ///
  /// Doubles as the self-heal for "the provider was unreachable at boot": the
  /// gate starts open in that case and closes as soon as a tick succeeds.
  final Duration refreshInterval;

  /// Overridable so tests do not depend on the real process environment.
  final Map<String, String>? _environment;

  Map<String, String> get environment => _environment ?? Platform.environment;

  AuthConfig _config = AuthConfig.disabled;
  OidcDiscovery? _discovery;
  String? _discoveryError;
  Timer? _timer;

  /// The effective configuration as of the last refresh.
  AuthConfig get config => _config;

  /// The discovery document, or null if it has never been fetched successfully.
  OidcDiscovery? get discovery => _discovery;

  /// Why the last discovery attempt failed, for the settings tab to show.
  String? get discoveryError => _discoveryError;

  /// Whether requests must carry a valid session.
  ///
  /// Read synchronously on every endpoint call, so it must stay a field read.
  bool get isEnforcing => _config.isEnforcing(hasDiscovery: _discovery != null);

  /// Whether a sign-in is possible, i.e. whether to show the app's sign-in
  /// button. Distinct from [isEnforcing]: a signed-in identity is still useful
  /// when authentication is not compulsory.
  bool get canSignIn => _config.isComplete && _discovery != null;

  /// Re-reads the settings and, when the configuration is complete, the
  /// discovery document.
  ///
  /// **Never throws.** It runs before `pod.start()` (where the settings table may
  /// not exist yet because migrations have not been applied), from a timer with
  /// no error handler, and from `updateSettings`. A throw in any of those either
  /// crashes the boot or leaves the gate in an undefined state, so every failure
  /// mode here degrades instead.
  Future<void> refresh(Session session) async {
    Settings? settings;
    try {
      settings = await sl<SettingsService>().getSettings(session);
    } catch (e) {
      // Expected once, before the first migration creates the table.
      session.log(
        'Could not read the settings while refreshing the authentication '
        'configuration; falling back to environment variables only. $e',
        level: LogLevel.warning,
      );
    }

    _config = AuthConfig.resolve(
      settings: settings,
      env: environment,
      clientSecret: _configuredClientSecret(),
      serverpodConfig: session.server.serverpod.config,
    );

    if (!_config.loginRequired) {
      // Nothing to probe, and probing anyway would log warnings about an
      // unconfigured provider on every tick of an install that never wanted
      // authentication in the first place.
      _discovery = null;
      _discoveryError = null;
      return;
    }

    if (!_config.isComplete) {
      _discovery = null;
      _discoveryError =
          'Incomplete configuration: '
          '${_missingFields().join(', ')} not set.';
      session.log(
        'Authentication is switched on but not fully configured '
        '(${_missingFields().join(', ')} missing), so it is not being '
        'enforced and the server stays reachable without signing in. '
        'Finish the configuration in Settings, or set '
        '${AuthEnv.strict}=true to refuse requests instead.',
        level: LogLevel.warning,
      );
      return;
    }

    try {
      _discovery = await sl<OidcClient>().discover(_config.issuer);
      _discoveryError = null;
    } catch (e) {
      _discoveryError = '$e';
      if (_discovery == null) {
        // Never succeeded: fail open, because enforcing with no reachable
        // provider is a lockout nobody can undo from the UI.
        session.log(
          'Could not reach the identity provider at ${_config.issuer}, and it '
          'has not been reached since this server started. Authentication is '
          'not being enforced. $e',
          level: LogLevel.warning,
        );
      } else {
        // Succeeded before: keep enforcing and keep the cached document. A
        // transient provider outage must not drop everyone's session.
        session.log(
          'The identity provider at ${_config.issuer} is temporarily '
          'unreachable; continuing with the cached discovery document. $e',
          level: LogLevel.warning,
        );
      }
    }
  }

  /// Starts the periodic refresh. Call once, after `pod.start()`.
  ///
  /// Deliberately not done in the constructor: a timer created there would leak
  /// out of every test that builds an [AuthRuntime].
  void startPeriodicRefresh(Serverpod pod) {
    _timer?.cancel();
    _timer = Timer.periodic(refreshInterval, (_) async {
      final session = await pod.createSession(enableLogging: false);
      try {
        await refresh(session);
        await sl<AuthService>().pruneExpired(session);
      } catch (e) {
        // refresh() is already total; this is belt-and-braces so a timer
        // callback can never bring the isolate down.
        session.log(
          'Authentication refresh tick failed: $e',
          level: LogLevel.error,
        );
      } finally {
        await session.close();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Applies a configuration change made through the settings.
  ///
  /// The single propagation point for configuration: with several server
  /// processes this becomes `session.messages.postMessage(global: true)` plus a
  /// subscriber that calls [refresh]. Every caller already goes through here, so
  /// that change stays local to this method.
  Future<void> broadcastConfigChange(Session session) => refresh(session);

  List<String> _missingFields() => [
    if (_config.issuer.isEmpty) 'issuer',
    if (_config.clientId.isEmpty) 'client ID',
    if (_config.clientSecret.isEmpty) 'client secret',
  ];

  /// The secret from Serverpod's password mechanism, if configured.
  ///
  /// `loadCustomPasswords` in `server.dart` registers the alias, which reads
  /// [AuthEnv.clientSecret] and falls back to `config/passwords.yaml`.
  String? _configuredClientSecret() {
    try {
      return Serverpod.instance.getPassword('oidcClientSecret');
    } catch (_) {
      // No Serverpod instance (a pure unit test) or no such password.
      return null;
    }
  }
}
