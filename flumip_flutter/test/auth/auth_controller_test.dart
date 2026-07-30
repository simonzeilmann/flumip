import 'package:flumip_flutter/auth/auth_controller.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_client/serverpod_client.dart';

/// [AuthController]'s two pieces of I/O are constructor parameters, so this runs
/// on the Dart VM with no browser, no server and no widget tree.
void main() {
  const anySession = SessionTokenResponse(
    token: 'a-token',
    expiresIn: Duration(minutes: 30),
    email: 'a@uni.example',
    displayName: 'Ada Lovelace',
  );

  /// Records where a sign-in or sign-out navigation went.
  late List<String> navigations;

  AuthController controllerFor({
    AuthConfigSnapshot config =
        const AuthConfigSnapshot(enabled: false, buttonLabel: 'Sign in'),
    Object? configError,
    SessionTokenResponse? session,
    Object? sessionError,
    int? sessionNullAfter,
  }) {
    var sessionCalls = 0;
    return AuthController(
      navigate: navigations.add,
      fetchConfig: () async {
        if (configError != null) throw configError;
        return config;
      },
      fetchSession: () async {
        if (sessionError != null) throw sessionError;
        sessionCalls++;
        if (sessionNullAfter != null && sessionCalls > sessionNullAfter) {
          return null;
        }
        return session;
      },
    );
  }

  setUp(() => navigations = []);

  group('sign-in disabled — the default install', () {
    test('bootstrap reports disabled', () async {
      final controller = controllerFor();
      await controller.bootstrap();
      expect(controller.state, AuthState.disabled);
    });

    test('no auth key provider is installed', () async {
      // The load-bearing assertion for "running without authentication is the
      // standard case": with no provider, not one request carries an
      // Authorization header, so the server's handler is never even reached.
      final controller = controllerFor();
      await controller.bootstrap();
      expect(controller.authKeyProvider, isNull);
    });

    test('the session endpoint is not even asked', () async {
      var asked = false;
      final controller = AuthController(
        navigate: navigations.add,
        fetchConfig: () async =>
            const AuthConfigSnapshot(enabled: false, buttonLabel: 'x'),
        fetchSession: () async {
          asked = true;
          return null;
        },
      );
      await controller.bootstrap();
      expect(asked, isFalse);
    });
  });

  group('sign-in enabled', () {
    const enabled = AuthConfigSnapshot(enabled: true, buttonLabel: 'Uni login');

    test('with no session, the state is signedOut', () async {
      final controller = controllerFor(config: enabled);
      await controller.bootstrap();
      expect(controller.state, AuthState.signedOut);
      expect(controller.authKeyProvider, isNull);
      expect(controller.buttonLabel, 'Uni login');
    });

    test('with a session, the state is signedIn', () async {
      final controller = controllerFor(config: enabled, session: anySession);
      await controller.bootstrap();
      expect(controller.state, AuthState.signedIn);
      expect(controller.authKeyProvider, isNotNull);
      expect(controller.user!.email, 'a@uni.example');
      expect(controller.user!.displayName, 'Ada Lovelace');
    });

    test('the provider yields a Bearer authorization header', () async {
      final controller = controllerFor(config: enabled, session: anySession);
      await controller.bootstrap();
      final header = await controller.authKeyProvider!.authHeaderValue;
      expect(header, isNotNull);
      expect(header, wrapAsBearerAuthHeaderValue('a-token'));
    });

    test('listeners are notified of the state change', () async {
      final controller = controllerFor(config: enabled, session: anySession);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.bootstrap();
      expect(notifications, greaterThan(0));
    });
  });

  group('failure handling', () {
    test('a server that cannot answer still yields a usable app', () async {
      // A blank screen would be the worst outcome: on a default install there is
      // nothing to sign in to anyway, so degrade to "no authentication".
      final controller = controllerFor(configError: Exception('offline'));
      await controller.bootstrap();
      expect(controller.state, AuthState.disabled);
      expect(controller.errorMessage, contains('offline'));
      expect(controller.authKeyProvider, isNull);
    });

    test('a failing session fetch does not throw out of bootstrap', () async {
      final controller = controllerFor(
        config: const AuthConfigSnapshot(enabled: true, buttonLabel: 'x'),
        sessionError: Exception('network down'),
      );
      await expectLater(controller.bootstrap(), completes);
      expect(controller.state, AuthState.disabled);
    });
  });

  group('revalidate', () {
    test('a session that has gone away moves the app to signedOut', () async {
      final controller = controllerFor(
        config: const AuthConfigSnapshot(enabled: true, buttonLabel: 'x'),
        session: anySession,
        // The bootstrap fetch and the provider's priming refresh succeed; the
        // next one finds the session gone.
        sessionNullAfter: 2,
      );
      await controller.bootstrap();
      expect(controller.state, AuthState.signedIn);

      await controller.revalidate();
      expect(controller.state, AuthState.signedOut);
      expect(controller.authKeyProvider, isNull);
      expect(controller.user, isNull);
    });

    test('does nothing when sign-in is disabled', () async {
      final controller = controllerFor();
      await controller.bootstrap();
      await controller.revalidate();
      expect(controller.state, AuthState.disabled);
    });
  });

  group('navigation', () {
    test('signIn goes to /auth/login on the site origin', () async {
      final controller = controllerFor();
      controller.signIn('https://flumip.example');
      // A full-page navigation, not a popup: the cookie has to be set in the
      // browsing context the app runs in.
      expect(navigations, ['https://flumip.example/auth/login']);
    });

    test('signOut goes to /auth/logout and drops the credential', () async {
      final controller = controllerFor(
        config: const AuthConfigSnapshot(enabled: true, buttonLabel: 'x'),
        session: anySession,
      );
      await controller.bootstrap();

      controller.signOut('https://flumip.example');
      expect(navigations, ['https://flumip.example/auth/logout']);
      // Only the server can clear an HttpOnly cookie, but the in-memory bearer
      // goes immediately.
      expect(controller.authKeyProvider, isNull);
      expect(controller.user, isNull);
    });
  });
}
