import 'dart:async';
import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/auth/oidc_discovery.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:flumip_server/src/services/snp_service.dart';
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
  /// Doubles as the self-heal for "the provider was unreachable at boot": on
  /// an install nobody has signed in to yet the gate starts open in that case
  /// and closes as soon as a tick succeeds; on one that has had sign-ins it
  /// enforces throughout, and new sign-ins start working with that tick.
  final Duration refreshInterval;

  /// Overridable so tests do not depend on the real process environment.
  final Map<String, String>? _environment;

  Map<String, String> get environment => _environment ?? Platform.environment;

  AuthConfig _config = AuthConfig.disabled;
  OidcDiscovery? _discovery;

  /// The issuer [_discovery] was fetched for. A cached document describes one
  /// provider; it is no evidence about a different one the issuer was changed
  /// to.
  String? _discoveryIssuer;
  String? _discoveryError;
  Timer? _timer;

  /// Whether the settings have ever been read successfully by this process.
  bool _settingsRead = false;

  /// Whether a refresh has tried to read the settings and failed, with no
  /// successful read before it. See [isEnforcing].
  bool _settingsUnreadable = false;

  /// The issuer this install is known to have completed a sign-in with, from
  /// the database. See [_hasSignedInBefore].
  String? _provenIssuer;

  /// Whether to enforce although [_discovery] is null: set by the last failed
  /// discovery attempt, from [_hasSignedInBefore].
  bool _enforceWithoutDiscovery = false;

  /// The effective configuration as of the last refresh.
  AuthConfig get config => _config;

  /// The discovery document, or null if it has never been fetched successfully.
  OidcDiscovery? get discovery => _discovery;

  /// Why the last discovery attempt failed, for the settings tab to show.
  String? get discoveryError => _discoveryError;

  /// Whether requests must carry a valid session.
  ///
  /// Read synchronously on every endpoint call, so it must stay a field read.
  ///
  /// ⚠️ **A failure never opens the gate.** Three rules make that hold:
  ///
  /// - A settings read that fails after one has succeeded keeps the last
  ///   configuration, rather than falling back to the environment alone —
  ///   which would read as "sign-in off, public mode off" and open a server
  ///   that was enforcing a moment ago.
  /// - Before any read has succeeded, a failed read **enforces**, unless the
  ///   environment alone settles it ([_environmentKeepsOpen]). Nothing works
  ///   without the database anyway, so this costs nothing but a few 401s at
  ///   boot on a fresh install, and it closes the window in which a database
  ///   blip during a restart would open a public instance.
  /// - A provider that has not answered since this process started still
  ///   counts as working if this install has completed a sign-in with that
  ///   issuer before ([_hasSignedInBefore]). Otherwise a restart while the provider
  ///   is down would open an install that required sign-in yesterday. Existing
  ///   sessions live in the database, so they keep working meanwhile; only new
  ///   sign-ins wait for the provider.
  ///
  /// The deliberate fail-open survives for an install that has **never**
  /// signed anybody in with the configured issuer: a first-time typo in the
  /// issuer, a firewall, a client that does not exist. That is what keeps the
  /// settings password working long enough to undo it from the UI.
  bool get isEnforcing {
    if (_settingsUnreadable) return !_environmentKeepsOpen;
    return _config.isEnforcing(
      hasDiscovery: _discovery != null || _enforceWithoutDiscovery,
    );
  }

  /// Whether a sign-in is possible, i.e. whether to show the app's sign-in
  /// button. Distinct from [isEnforcing]: a signed-in identity is still useful
  /// when authentication is not compulsory.
  bool get canSignIn => _config.isComplete && _discovery != null;

  /// Whether the environment by itself switches both sign-in and public mode
  /// off, so that unreadable settings need not keep the gate closed.
  ///
  /// Both have to be explicit: with only `FLUMIP_AUTH_ENABLED=false`, public
  /// mode could still be on in the settings nobody can read.
  bool get _environmentKeepsOpen =>
      _config.envOverrides.contains(AuthEnv.enabled) &&
      _config.envOverrides.contains(AuthEnv.publicMode) &&
      !_config.loginRequired &&
      !_config.publicMode &&
      !_config.strict;

  /// Re-reads the settings and, when the configuration is complete, the
  /// discovery document.
  ///
  /// **Never throws.** It runs before `pod.start()` (where the settings table may
  /// not exist yet because migrations have not been applied), from a timer with
  /// no error handler, and from `updateSettings`. A throw in any of those either
  /// crashes the boot or leaves the gate in an undefined state, so every failure
  /// mode here degrades instead — and degrades **closed** when the server was
  /// enforcing; see [isEnforcing].
  Future<void> refresh(Session session) async {
    Settings? settings;
    try {
      settings = await sl<SettingsService>().getSettings(session);
    } catch (e) {
      session.log(
        _settingsRead
            ? 'Could not read the settings while refreshing the authentication '
                  'configuration; keeping the configuration from the last '
                  'successful read. $e'
            // Expected once, before the first migration creates the table.
            : 'Could not read the settings while refreshing the authentication '
                  'configuration, and they have not been read since this '
                  'server started, so requests are refused until they can be. '
                  'Set ${AuthEnv.enabled}=false and ${AuthEnv.publicMode}=false '
                  'to run without them. $e',
        level: LogLevel.warning,
      );
    }

    if (settings != null) {
      _settingsRead = true;
      _settingsUnreadable = false;
    } else if (!_settingsRead) {
      _settingsUnreadable = true;
    }

    // ⚠️ After a successful read, a failed one keeps [_config] as it was.
    // Resolving from the environment alone would switch sign-in and public mode
    // off on every install that configured them in Settings.
    if (settings != null || !_settingsRead) {
      _config = AuthConfig.resolve(
        settings: settings,
        env: environment,
        clientSecret: _configuredClientSecret(),
        serverpodConfig: session.server.serverpod.config,
      );
    }

    if (!_config.wantsSignIn) {
      // Nothing to probe, and probing anyway would log warnings about an
      // unconfigured provider on every tick of an install that never wanted
      // authentication in the first place.
      _discovery = null;
      _discoveryIssuer = null;
      _discoveryError = null;
      _enforceWithoutDiscovery = false;
      return;
    }

    if (!_config.isComplete) {
      _discovery = null;
      _discoveryIssuer = null;
      _enforceWithoutDiscovery = false;
      _discoveryError =
          'Incomplete configuration: '
          '${_missingFields().join(', ')} not set.';
      session.log(
        _config.publicMode
            // Guests are unaffected — public mode enforces on its own — but
            // nobody can sign in as an administrator, and with the settings
            // password refused that leaves the Settings tab unreachable.
            ? 'Public mode is on but single sign-on is not fully configured '
                  '(${_missingFields().join(', ')} missing), so no '
                  'administrator can sign in. Set ${AuthEnv.publicMode}=false '
                  'to get back into Settings.'
            : 'Authentication is switched on but not fully configured '
                  '(${_missingFields().join(', ')} missing), so it is not being '
                  'enforced and the server stays reachable without signing in. '
                  'Finish the configuration in Settings, or set '
                  '${AuthEnv.strict}=true to refuse requests instead.',
        level: LogLevel.warning,
      );
      return;
    }

    // A document cached for another issuer says nothing about this one, and
    // using it would send sign-ins to the old provider's endpoints.
    if (_discoveryIssuer != _config.issuer) {
      _discovery = null;
      _discoveryIssuer = null;
    }

    try {
      _discovery = await sl<OidcClient>().discover(_config.issuer);
      _discoveryIssuer = _config.issuer;
      _discoveryError = null;
      _enforceWithoutDiscovery = false;
    } catch (e) {
      _discoveryError = '$e';
      _enforceWithoutDiscovery =
          _discovery == null &&
          await _hasSignedInBefore(session, _config.issuer);
      if (_discovery != null) {
        // Succeeded before: keep enforcing and keep the cached document. A
        // transient provider outage must not drop everyone's session.
        session.log(
          'The identity provider at ${_config.issuer} is temporarily '
          'unreachable; continuing with the cached discovery document. $e',
          level: LogLevel.warning,
        );
      } else if (_enforceWithoutDiscovery) {
        // Not reached since this process started, but this install has signed
        // people in with it before: a restart during an outage, not a
        // misconfiguration. Keep enforcing; signed-in users carry on, new
        // sign-ins wait for the provider.
        session.log(
          'Could not reach the identity provider at ${_config.issuer} since '
          'this server started. People have signed in with it before, so '
          'sign-in stays enforced: existing sessions keep working, and new '
          'sign-ins will work once the provider answers. If it will not come '
          'back, set ${AuthEnv.enabled}=false and restart. $e',
          level: LogLevel.warning,
        );
      } else {
        // Never succeeded: fail open, because enforcing with no reachable
        // provider is a lockout nobody can undo from the UI.
        session.log(
          'Could not reach the identity provider at ${_config.issuer}, and '
          'nobody has ever signed in with it here. Authentication is not being '
          'enforced. $e',
          level: LogLevel.warning,
        );
      }
    }
  }

  /// Whether a sign-in with [issuer] has ever completed on this install.
  ///
  /// The evidence that a provider which is not answering *now* is a working
  /// provider having an outage, rather than a misconfiguration: a
  /// [FlumipUser] row with that issuer exists only because `/auth/callback`
  /// completed for it. Guests have their own issuer and never count. Keyed on
  /// the issuer, so pointing the install at a new (perhaps mistyped) one gets
  /// the never-worked fail-open again — changing the issuer takes an
  /// administrator anyway.
  ///
  /// Remembered once true. ⚠️ A failed lookup also answers true: the rule here
  /// is that no failure opens the gate, and a database that cannot answer this
  /// cannot serve the app either.
  Future<bool> _hasSignedInBefore(Session session, String issuer) async {
    if (_provenIssuer == issuer) return true;
    try {
      // The issuer is stored as the token sent it; the configuration has its
      // trailing slashes stripped (see `AuthConfig.resolve`).
      final count = await FlumipUser.db.count(
        session,
        where: (t) => t.issuer.equals(issuer) | t.issuer.equals('$issuer/'),
      );
      if (count == 0) return false;
    } catch (e) {
      session.log(
        'Could not check whether anybody has signed in with $issuer before; '
        'assuming they have, so sign-in stays enforced. $e',
        level: LogLevel.warning,
      );
      return true;
    }
    _provenIssuer = issuer;
    return true;
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
        await sl<SnpService>().deleteExpired(session);
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
