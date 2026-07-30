import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  const issuer = 'https://idp.example.org';

  // One shared fake for the whole file, reset per test: `withServerpod` group
  // bodies run at collection time, so anything created in a body is shared
  // whether or not that was intended.
  final http = FakeHttpJsonClient();

  /// Switches SSO on and makes the provider reachable, so the gate closes.
  Future<void> enforceSso(Session session) async {
    final settings = await Settings.db.findFirstRow(session) ?? Settings();
    settings
      ..loginRequired = true
      ..oidcIssuer = issuer
      ..oidcClientId = 'flumip'
      ..oidcClientSecret = 's3cret'
      ..authPublicUrl = 'https://flumip.example';
    if (settings.id == null) {
      await Settings.db.insertRow(session, settings);
    } else {
      await Settings.db.updateRow(session, settings);
    }
    http.stubProvider(issuer: issuer);
    await sl<AuthRuntime>().refresh(session);
    expect(sl<AuthRuntime>().isEnforcing, isTrue,
        reason: 'the test setup itself must actually close the gate');
  }

  withServerpod('Running without authentication (the default)',
      (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    setUp(() async {
      http.reset();
      // Default settings: loginRequired is false.
      await sl<AuthRuntime>().refresh(session);
    });

    test('the gate is open', () {
      expect(sl<AuthRuntime>().isEnforcing, isFalse);
    });

    // The single most important test in this change: the documented default is
    // that FLUMIP runs with no authentication at all, and that must keep working
    // exactly as it did before any of this existed.
    test('every gated endpoint answers an unauthenticated caller', () async {
      await expectLater(endpoints.project.getProjects(sessionBuilder), completes);
      await expectLater(
          endpoints.genome.getAllGenomes(sessionBuilder), completes);
    });

    test('the settings endpoint still takes the password', () async {
      final settings =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      expect(settings.baseDir, '/opt/flumip');
    });

    test('the auth endpoint reports that no sign-in is offered', () async {
      final config = await endpoints.auth.config(sessionBuilder);
      expect(config.enabled, isFalse);
    });

    test('there is no signed-in user', () async {
      expect(await endpoints.auth.me(sessionBuilder), isNull);
    });
  });

  withServerpod('Running with authentication enforced',
      (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    final signedIn = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        'staff@uni.example',
        const {},
      ),
    );
    final signedInAdmin = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        'boss@uni.example',
        {adminScope},
      ),
    );

    setUp(http.reset);

    test('a gated endpoint refuses an unauthenticated caller', () async {
      await enforceSso(session);
      await expectLater(
        endpoints.project.getProjects(sessionBuilder),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });

    test('a gated endpoint answers a signed-in caller', () async {
      await enforceSso(session);
      await expectLater(endpoints.project.getProjects(signedIn), completes);
      await expectLater(endpoints.genome.getAllGenomes(signedIn), completes);
    });

    test('the settings password still works — the break-glass route', () async {
      // The switch that turns authentication off must never sit behind the thing
      // it switches off. If this ever regresses, a misconfigured install becomes
      // unrecoverable from the UI.
      await enforceSso(session);
      final settings =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      expect(settings.loginRequired, isTrue);
    });

    test('an admin session unlocks settings without the password', () async {
      await enforceSso(session);
      final settings =
          await endpoints.settings.getSettings(signedInAdmin, null);
      expect(settings.loginRequired, isTrue);
    });

    test('a non-admin session does not unlock settings', () async {
      await enforceSso(session);
      await expectLater(
        endpoints.settings.getSettings(signedIn, null),
        throwsA(isA<ArgumentException>()),
      );
    });

    test('a wrong password is refused even while signed in as a non-admin',
        () async {
      await enforceSso(session);
      await expectLater(
        endpoints.settings.getSettings(signedIn, 'wrong'),
        throwsA(isA<ArgumentException>()),
      );
    });

    test('the auth config endpoint stays reachable unauthenticated', () async {
      // The app has to be able to ask "do I need to sign in?" before it holds
      // any credential, so this endpoint can never be gated.
      await enforceSso(session);
      final config = await endpoints.auth.config(sessionBuilder);
      expect(config.enabled, isTrue);
      expect(config.buttonLabel, 'Sign in with SSO');
    });

    test('me() reports the signed-in identity', () async {
      await enforceSso(session);
      final user = await endpoints.auth.me(signedInAdmin);
      expect(user!.email, 'boss@uni.example');
      expect(user.isAdmin, isTrue);
    });
  });

  withServerpod('Turning authentication back off', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    setUp(http.reset);

    test('saving the settings takes effect immediately', () async {
      await enforceSso(session);
      await expectLater(
        endpoints.project.getProjects(sessionBuilder),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );

      final settings =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');
      settings.loginRequired = false;
      await endpoints.settings
          .updateSettings(sessionBuilder, 'changeme', settings);

      // No waiting for the 30-second refresh tick: updateSettings re-resolves.
      expect(sl<AuthRuntime>().isEnforcing, isFalse);
      await expectLater(
        endpoints.project.getProjects(sessionBuilder),
        completes,
      );
    });

    test('the client secret survives an unrelated settings save', () async {
      await enforceSso(session);
      final settings =
          await endpoints.settings.getSettings(sessionBuilder, 'changeme');

      // The secret is never sent to the browser. Asserted on the wire format
      // rather than on the object, because these test endpoints call the server
      // in-process and so hand back the server-side object unserialised — the
      // real client receives toJsonForProtocol(), which omits serverOnly fields.
      expect(settings.oidcClientSecret, 's3cret');
      expect(settings.toJsonForProtocol(), isNot(contains('oidcClientSecret')));

      settings.smtpServer = 'smtp.example.org';
      await endpoints.settings
          .updateSettings(sessionBuilder, 'changeme', settings);

      final stored = await Settings.db.findFirstRow(session);
      expect(stored!.oidcClientSecret, 's3cret');
      expect(stored.smtpServer, 'smtp.example.org');
      expect(sl<AuthRuntime>().isEnforcing, isTrue);
    });

    test('setOidcClientSecret writes without reading back', () async {
      await enforceSso(session);
      await endpoints.settings
          .setOidcClientSecret(sessionBuilder, 'changeme', 'a-new-secret');

      final stored = await Settings.db.findFirstRow(session);
      expect(stored!.oidcClientSecret, 'a-new-secret');
    });

    test('an empty secret clears it', () async {
      await enforceSso(session);
      await endpoints.settings
          .setOidcClientSecret(sessionBuilder, 'changeme', '  ');

      final stored = await Settings.db.findFirstRow(session);
      expect(stored!.oidcClientSecret, isNull);
      // And the gate opens, because the configuration is no longer complete.
      expect(sl<AuthRuntime>().isEnforcing, isFalse);
    });

    test('getAuthAdminStatus reports the redirect URI and probe result',
        () async {
      await enforceSso(session);
      final status = await endpoints.settings
          .getAuthAdminStatus(sessionBuilder, 'changeme');

      expect(status.enabled, isTrue);
      expect(status.enforcing, isTrue);
      expect(status.secretConfigured, isTrue);
      expect(status.redirectUri, 'https://flumip.example/auth/callback');
      expect(status.discoveryOk, isTrue);
      expect(status.discoveryError, isNull);
      expect(status.authorizationEndpoint, '$issuer/authorize');
      expect(status.envOverrides, isEmpty);
    });

    test('getAuthAdminStatus surfaces a discovery failure readably', () async {
      await enforceSso(session);
      http.getError = Exception('Connection refused');
      // Drop the cached document so the probe has to go out again.
      await sl<AuthRuntime>().refresh(session);

      final status = await endpoints.settings
          .getAuthAdminStatus(sessionBuilder, 'changeme');
      expect(status.discoveryError, contains('Connection refused'));
    });

    test('getAuthAdminStatus refuses a wrong password', () async {
      await enforceSso(session);
      await expectLater(
        endpoints.settings.getAuthAdminStatus(sessionBuilder, 'nope'),
        throwsA(isA<ArgumentException>()),
      );
    });
  });
}
