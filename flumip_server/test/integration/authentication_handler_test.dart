import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import 'test_tools/serverpod_test_tools.dart';

/// An [AuthService] whose lookup always fails, standing in for a dropped database
/// connection during a request.
class ThrowingAuthService extends AuthService {
  @override
  Future<AuthApiToken?> resolveApiToken(Session session, String token) async =>
      throw Exception('connection closed');
}

void main() {
  const issuer = 'https://idp.example.org';
  final http = FakeHttpJsonClient();

  Future<void> enableSso(Session session, {String adminEmails = ''}) async {
    final settings = await Settings.db.findFirstRow(session) ?? Settings();
    settings
      ..loginRequired = true
      ..oidcIssuer = issuer
      ..oidcClientId = 'flumip'
      ..oidcClientSecret = 's3cret'
      ..oidcAdminEmails = adminEmails
      ..authPublicUrl = 'https://flumip.example';
    if (settings.id == null) {
      await Settings.db.insertRow(session, settings);
    } else {
      await Settings.db.updateRow(session, settings);
    }
    http.stubProvider(issuer: issuer);
    await sl<AuthRuntime>().refresh(session);
  }

  /// Signs in and returns a usable bearer token.
  Future<String> bearerToken(Session session, {String? email}) async {
    final authService = sl<AuthService>();
    final url = await authService.beginFlow(session);
    final state = url.queryParameters['state']!;
    final flow = await AuthFlow.db.findFirstRow(
      session,
      where: (t) => t.state.equals(state),
    );
    http.stubProvider(
      issuer: issuer,
      idTokenClaims: {
        'iss': issuer,
        'aud': 'flumip',
        'sub': 'user-123',
        'nonce': flow!.nonce,
        'email': email ?? 'a@uni.example',
        'exp': epochSeconds(
          DateTime.now().toUtc().add(const Duration(minutes: 5)),
        ),
      },
    );
    final signedIn = await authService.completeCallback(
      session,
      code: 'c',
      state: state,
    );
    final issued = (await authService.issueApiToken(
      session,
      signedIn.cookieValue,
    ))!;
    return issued.token;
  }

  withServerpod('flumipAuthenticationHandler', (sessionBuilder, endpoints) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();

    setUp(http.reset);

    test('resolves a valid token to the signed-in identity', () async {
      await enableSso(session);
      final token = await bearerToken(session);

      final info = await flumipAuthenticationHandler(session, token);
      expect(info, isNotNull);
      expect(info!.userIdentifier, 'a@uni.example');
      expect(info.scopes, isEmpty);
      expect(int.tryParse(info.authId), isNotNull);
    });

    test('grants the admin scope to an address on the admin list', () async {
      await enableSso(session, adminEmails: 'boss@uni.example');
      final token = await bearerToken(session, email: 'boss@uni.example');

      final info = await flumipAuthenticationHandler(session, token);
      expect(info!.scopes, contains(adminScope));
    });

    test(
      'the authId names the browser session, so logout can revoke it',
      () async {
        await enableSso(session);
        final token = await bearerToken(session);
        final info = await flumipAuthenticationHandler(session, token);

        final authSession = await AuthSession.db.findFirstRow(session);
        expect(info!.authId, '${authSession!.id}');
      },
    );

    test('returns null for an unknown token', () async {
      await enableSso(session);
      expect(
        await flumipAuthenticationHandler(session, AuthTokens.newToken()),
        isNull,
      );
    });

    test('returns null for an expired token', () async {
      await enableSso(session);
      final token = await bearerToken(session);
      final row = await AuthApiToken.db.findFirstRow(session);
      row!.expires = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );
      await AuthApiToken.db.updateRow(session, row);

      expect(await flumipAuthenticationHandler(session, token), isNull);
    });

    test('returns null for a revoked token', () async {
      await enableSso(session);
      final token = await bearerToken(session);
      expect(await flumipAuthenticationHandler(session, token), isNotNull);

      final authSession = await AuthSession.db.findFirstRow(session);
      await sl<AuthService>().revokeSession(session, authSession!.id!);

      expect(await flumipAuthenticationHandler(session, token), isNull);
    });

    // The guard on the trap that motivated installing this handler
    // unconditionally in the first place: Serverpod's default handler throws
    // UnimplementedError, and the framework calls the handler for any request
    // carrying an authorization header. Anything other than a null return here
    // becomes a 500 on an unrelated endpoint, on every endpoint, with nothing in
    // the UI to suggest clearing the stale credential.
    group('never throws', () {
      final nasty = <String, String>{
        'empty': '',
        'whitespace': '   ',
        'not base64': '!!!!',
        'a JWT, which this server never issues': 'a.b.c',
        'SQL-looking': "' OR 1=1 --",
        'a percent sign': '%',
        'a null byte': 'abc\u0000def',
        'very long': 'x' * 10000,
        'unicode': '🔑🔑🔑',
        'a newline': 'abc\ndef',
      };

      for (final entry in nasty.entries) {
        test('for a token that is ${entry.key}', () async {
          await enableSso(session);
          await expectLater(
            flumipAuthenticationHandler(session, entry.value),
            completion(isNull),
          );
        });
      }

      test('when authentication is not configured at all', () async {
        // A browser holding a token from before SSO was switched off.
        await sl<AuthRuntime>().refresh(session);
        expect(sl<AuthRuntime>().isEnforcing, isFalse);
        await expectLater(
          flumipAuthenticationHandler(session, AuthTokens.newToken()),
          completion(isNull),
        );
      });

      test('when the lookup itself fails', () async {
        await enableSso(session);
        sl.registerSingleton<AuthService>(ThrowingAuthService());
        addTearDown(() => sl.registerSingleton<AuthService>(AuthService()));

        await expectLater(
          flumipAuthenticationHandler(session, AuthTokens.newToken()),
          completion(isNull),
        );
      });
    });
  });
}
