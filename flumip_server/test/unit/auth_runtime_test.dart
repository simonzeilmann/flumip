import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/http_client.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_http_json_client.dart';

/// A [SettingsService] whose read always fails, standing in for the window on a
/// fresh database where the `settings` table does not exist yet because
/// migrations run inside `pod.start()`.
class ThrowingSettingsService extends SettingsService {
  @override
  Future<Settings> getSettings(Session session) async =>
      throw Exception('relation "settings" does not exist');
}

void main() {
  const issuer = 'https://idp.example.org';
  final http = FakeHttpJsonClient();

  Future<void> configure(
    Session session, {
    bool loginRequired = true,
    String storedIssuer = issuer,
    String clientId = 'flumip',
    String? clientSecret = 's3cret',
  }) async {
    final settings = await SettingsService().getSettings(session);
    settings
      ..loginRequired = loginRequired
      ..oidcIssuer = storedIssuer
      ..oidcClientId = clientId
      ..authPublicUrl = 'https://flumip.example';
    settings.oidcClientSecret = clientSecret;
    await Settings.db.updateRow(session, settings);
  }

  withServerpod('AuthRuntime gate', (sessionBuilder, endpoints) {
    setup(httpClient: http);
    final session = sessionBuilder.build();

    setUp(http.reset);

    test('starts disabled before anything has been read', () {
      final runtime = AuthRuntime(environment: const {});
      expect(runtime.isEnforcing, isFalse);
      expect(runtime.canSignIn, isFalse);
      expect(runtime.config.loginRequired, isFalse);
    });

    test('stays open when authentication is not switched on', () async {
      await configure(session, loginRequired: false);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);

      expect(runtime.isEnforcing, isFalse);
      // No provider is probed either — otherwise an install that never wanted
      // authentication would log a warning every 30 seconds.
      expect(http.requests, isEmpty);
      expect(runtime.discoveryError, isNull);
    });

    test('enforces once configured and the provider answers', () async {
      await configure(session);
      http.stubProvider(issuer: issuer);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);

      expect(runtime.isEnforcing, isTrue);
      expect(runtime.canSignIn, isTrue);
      expect(runtime.discovery, isNotNull);
      expect(runtime.discoveryError, isNull);
    });

    test('fails open on an incomplete configuration', () async {
      // Enforcing with no way to sign in is a lockout nobody can undo from the
      // UI, so an unfinished configuration must leave the server reachable.
      await configure(session, clientSecret: null);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);

      expect(runtime.config.loginRequired, isTrue);
      expect(runtime.config.isComplete, isFalse);
      expect(runtime.isEnforcing, isFalse);
      expect(runtime.discoveryError, contains('client secret'));
      expect(http.requests, isEmpty);
    });

    test('fails open when the provider has never been reachable', () async {
      await configure(session);
      http.getError = HttpJsonException(
        503,
        '$issuer/.well-known/openid-configuration',
        'Service Unavailable',
      );
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);

      expect(runtime.isEnforcing, isFalse);
      expect(runtime.discovery, isNull);
      expect(runtime.discoveryError, contains('503'));
    });

    test('keeps enforcing when the provider goes down after succeeding once',
        () async {
      // A transient provider outage must not drop everyone's live session.
      await configure(session);
      http.stubProvider(issuer: issuer);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);
      expect(runtime.isEnforcing, isTrue);

      http.getError = HttpJsonException(500, issuer, 'boom');
      await runtime.refresh(session);

      expect(runtime.isEnforcing, isTrue, reason: 'the cached document stands');
      expect(runtime.discovery, isNotNull);
      expect(runtime.discoveryError, contains('500'));
    });

    test('self-heals when the provider comes back', () async {
      // This is what makes the periodic refresh worth having: a provider that
      // was down at boot leaves the gate open, and it closes on its own.
      await configure(session);
      http.getError = HttpJsonException(503, issuer, 'down');
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);
      expect(runtime.isEnforcing, isFalse);

      http.getError = null;
      http.stubProvider(issuer: issuer);
      await runtime.refresh(session);

      expect(runtime.isEnforcing, isTrue);
      expect(runtime.discoveryError, isNull);
    });

    test('FLUMIP_AUTH_STRICT fails closed instead', () async {
      await configure(session, clientSecret: null);
      final runtime = AuthRuntime(
        environment: const {AuthEnv.strict: 'true'},
      );
      await runtime.refresh(session);

      expect(runtime.config.isComplete, isFalse);
      expect(runtime.isEnforcing, isTrue);
    });

    test('does not throw when the settings cannot be read', () async {
      // Happens once on a fresh database: refresh runs before pod.start()
      // applies the migration that creates the table. A throw here would crash
      // the boot.
      sl.registerSingleton<SettingsService>(ThrowingSettingsService());
      addTearDown(() => sl.registerSingleton<SettingsService>(
            SettingsService(),
          ));

      final runtime = AuthRuntime(environment: const {});
      await expectLater(runtime.refresh(session), completes);
      expect(runtime.isEnforcing, isFalse);
    });

    test('falls back to the environment when the settings cannot be read',
        () async {
      sl.registerSingleton<SettingsService>(ThrowingSettingsService());
      addTearDown(() => sl.registerSingleton<SettingsService>(
            SettingsService(),
          ));
      http.stubProvider(issuer: issuer);

      final runtime = AuthRuntime(environment: const {
        AuthEnv.enabled: 'true',
        AuthEnv.issuer: issuer,
        AuthEnv.clientId: 'flumip',
        AuthEnv.publicUrl: 'https://flumip.example',
      });
      await runtime.refresh(session);

      expect(runtime.config.loginRequired, isTrue);
      expect(runtime.config.issuer, issuer);
      // Still not complete: no secret is configured, so it fails open.
      expect(runtime.isEnforcing, isFalse);
    });

    test('FLUMIP_AUTH_ENABLED=false switches a configured install off',
        () async {
      // The documented break-glass route out of a lockout.
      await configure(session);
      http.stubProvider(issuer: issuer);

      final enforcing = AuthRuntime(environment: const {});
      await enforcing.refresh(session);
      expect(enforcing.isEnforcing, isTrue);

      final overridden = AuthRuntime(
        environment: const {AuthEnv.enabled: 'false'},
      );
      await overridden.refresh(session);
      expect(overridden.isEnforcing, isFalse);
      expect(overridden.config.envOverrides, contains(AuthEnv.enabled));
    });

    test('an environment issuer overrides the stored one', () async {
      await configure(session, storedIssuer: 'https://stored.example.org');
      http.stubProvider(issuer: 'https://env.example.org');

      final runtime = AuthRuntime(environment: const {
        AuthEnv.issuer: 'https://env.example.org',
      });
      await runtime.refresh(session);

      expect(runtime.config.issuer, 'https://env.example.org');
      expect(runtime.discovery!.issuer, 'https://env.example.org');
    });

    test('broadcastConfigChange picks up a settings change', () async {
      await configure(session, loginRequired: false);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);
      expect(runtime.isEnforcing, isFalse);

      await configure(session, loginRequired: true);
      http.stubProvider(issuer: issuer);
      await runtime.broadcastConfigChange(session);

      expect(runtime.isEnforcing, isTrue);
    });

    test('the redirect URI is derived from the configured public URL', () async {
      await configure(session);
      http.stubProvider(issuer: issuer);
      final runtime = AuthRuntime(environment: const {});
      await runtime.refresh(session);

      expect(
        runtime.config.redirectUri,
        'https://flumip.example/auth/callback',
      );
      expect(runtime.config.cookieSecure, isTrue);
    });

    test('constructing one starts no timer', () {
      // A timer created in the constructor leaks out of every test that builds
      // an AuthRuntime, and the suite hangs at teardown.
      final runtime = AuthRuntime(environment: const {});
      expect(() => runtime.stop(), returnsNormally);
    });
  });
}
