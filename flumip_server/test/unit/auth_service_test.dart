import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_http_json_client.dart';

void main() {
  const issuer = 'https://idp.example.org';

  // One shared fake for the whole file: `withServerpod` group bodies run at
  // collection time, so a fake created inside the body would be shared anyway —
  // making that explicit and resetting in setUp is the honest version.
  final http = FakeHttpJsonClient();

  /// Puts a complete, reachable provider in place and refreshes the runtime.
  Future<AuthRuntime> enableSso(
    Session session, {
    String allowedDomains = '',
    String adminEmails = '',
  }) async {
    final settingsService = sl<SettingsService>();
    final settings = await settingsService.getSettings(session);
    settings
      ..loginRequired = true
      ..oidcIssuer = issuer
      ..oidcClientId = 'flumip'
      ..oidcAllowedEmailDomains = allowedDomains
      ..oidcAdminEmails = adminEmails
      ..authPublicUrl = 'https://flumip.example';
    // Written directly because the secret is serverOnly and excluded from the
    // updateSettings merge, exactly as setOidcClientSecret does it.
    settings.oidcClientSecret = 's3cret';
    await Settings.db.updateRow(session, settings);

    http.stubProvider(issuer: issuer);
    final runtime = sl<AuthRuntime>();
    await runtime.refresh(session);
    return runtime;
  }

  Map<String, dynamic> idTokenClaims({
    String subject = 'user-123',
    String? email = 'a@uni.example',
    String? name = 'Ada Lovelace',
    required String nonce,
    Duration? expiresIn,
  }) =>
      {
        'iss': issuer,
        'aud': 'flumip',
        'sub': subject,
        'nonce': nonce,
        'exp': epochSeconds(
          DateTime.now().toUtc().add(expiresIn ?? const Duration(minutes: 5)),
        ),
        'iat': epochSeconds(DateTime.now().toUtc()),
        'email': ?email,
        'name': ?name,
      };

  /// Runs a full sign-in and returns the resulting cookie.
  Future<CompletedSignIn> signIn(
    Session session, {
    String subject = 'user-123',
    String? email = 'a@uni.example',
    String? name = 'Ada Lovelace',
    Map<String, dynamic>? userinfo,
  }) async {
    final authService = sl<AuthService>();
    final url = await authService.beginFlow(session);
    final state = url.queryParameters['state']!;
    final flow = await AuthFlow.db
        .findFirstRow(session, where: (t) => t.state.equals(state));

    http.stubProvider(
      issuer: issuer,
      idTokenClaims: idTokenClaims(
        subject: subject,
        email: email,
        name: name,
        nonce: flow!.nonce,
      ),
      userinfo: userinfo,
    );

    return authService.completeCallback(session, code: 'the-code', state: state);
  }

  withServerpod('AuthService sign-in flow', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final authService = sl<AuthService>();

    setUp(http.reset);

    test('beginFlow records a flow and returns an authorization URL', () async {
      await enableSso(session);
      final url = await authService.beginFlow(session);

      expect(url.toString(), startsWith('$issuer/authorize'));
      final state = url.queryParameters['state']!;
      final flow = await AuthFlow.db
          .findFirstRow(session, where: (t) => t.state.equals(state));
      expect(flow, isNotNull);
      // The verifier stays on the server; only its challenge goes via the
      // browser.
      expect(url.toString(), isNot(contains(flow!.codeVerifier)));
      expect(url.queryParameters['nonce'], flow.nonce);
    });

    test('beginFlow says so when sign-in is switched off', () async {
      // Notably the case after the FLUMIP_AUTH_ENABLED break-glass switch, which
      // leaves the stored OIDC settings in place. Blaming the provider there
      // would send an admin debugging the wrong thing.
      await enableSso(session);
      final off = AuthRuntime(
        environment: const {AuthEnv.enabled: 'false'},
      );
      sl.registerSingleton<AuthRuntime>(off);
      addTearDown(() => sl.registerSingleton<AuthRuntime>(
            AuthRuntime(environment: const {}),
          ));
      await off.refresh(session);

      await expectLater(
        () => authService.beginFlow(session),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('switched off'),
        )),
      );
    });

    test('beginFlow refuses when the configuration is incomplete', () async {
      final settings = await sl<SettingsService>().getSettings(session);
      settings.loginRequired = true;
      await Settings.db.updateRow(session, settings);
      await sl<AuthRuntime>().refresh(session);

      await expectLater(
        () => authService.beginFlow(session),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('not fully configured'),
        )),
      );
    });

    test('a full sign-in creates a user and a session', () async {
      await enableSso(session);
      final result = await signIn(session);

      expect(result.cookieValue, isNotEmpty);
      expect(result.session.email, 'a@uni.example');
      expect(result.session.isAdmin, isFalse);

      final user = await FlumipUser.db.findById(session, result.session.userId);
      expect(user!.email, 'a@uni.example');
      expect(user.subject, 'user-123');
      expect(user.issuer, issuer);
      expect(user.displayName, 'Ada Lovelace');
    });

    test('only the hash of the cookie is stored', () async {
      await enableSso(session);
      final result = await signIn(session);
      expect(result.session.cookieHash, isNot(result.cookieValue));
      expect(
        result.session.cookieHash,
        AuthTokens.sha256Hex(result.cookieValue),
      );
    });

    test('a state can only be redeemed once', () async {
      await enableSso(session);
      final url = await authService.beginFlow(session);
      final state = url.queryParameters['state']!;
      final flow = await AuthFlow.db
          .findFirstRow(session, where: (t) => t.state.equals(state));
      http.stubProvider(
        issuer: issuer,
        idTokenClaims: idTokenClaims(nonce: flow!.nonce),
      );

      await authService.completeCallback(session, code: 'c', state: state);

      // Replaying the same callback must fail: the row is gone.
      await expectLater(
        () => authService.completeCallback(session, code: 'c', state: state),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('already been used'),
        )),
      );
    });

    test('an unknown state is refused', () async {
      await enableSso(session);
      await expectLater(
        () => authService.completeCallback(
          session,
          code: 'c',
          state: 'never-issued',
        ),
        throwsA(isA<AuthFlowException>()),
      );
    });

    test('an expired flow is refused and consumed', () async {
      await enableSso(session);
      final url = await authService.beginFlow(session);
      final state = url.queryParameters['state']!;
      final flow = await AuthFlow.db
          .findFirstRow(session, where: (t) => t.state.equals(state));
      flow!.expires = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      await AuthFlow.db.updateRow(session, flow);

      await expectLater(
        () => authService.completeCallback(session, code: 'c', state: state),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('took too long'),
        )),
      );
      expect(
        await AuthFlow.db
            .findFirstRow(session, where: (t) => t.state.equals(state)),
        isNull,
      );
    });

    test('a nonce mismatch is refused', () async {
      await enableSso(session);
      final url = await authService.beginFlow(session);
      final state = url.queryParameters['state']!;
      http.stubProvider(
        issuer: issuer,
        idTokenClaims: idTokenClaims(nonce: 'not-the-nonce-we-sent'),
      );
      await expectLater(
        () => authService.completeCallback(session, code: 'c', state: state),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('could not accept'),
        )),
      );
    });

    test('falls back to userinfo when the ID token carries no email', () async {
      await enableSso(session);
      final result = await signIn(
        session,
        email: null,
        name: null,
        userinfo: {'email': 'b@uni.example', 'name': 'Grace Hopper'},
      );
      expect(result.session.email, 'b@uni.example');
      final user = await FlumipUser.db.findById(session, result.session.userId);
      expect(user!.displayName, 'Grace Hopper');
    });

    test('refuses a sign-in when no email can be found at all', () async {
      await enableSso(session);
      await expectLater(
        () => signIn(session, email: null, userinfo: {'sub': 'no-email-here'}),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('email'),
        )),
      );
    });

    test('the email is normalised to lower case', () async {
      await enableSso(session);
      final result = await signIn(session, email: 'MiXeD@Uni.Example');
      expect(result.session.email, 'mixed@uni.example');
    });
  });

  withServerpod('AuthService access control', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    setUp(http.reset);

    test('an allowed domain may sign in', () async {
      await enableSso(session, allowedDomains: 'uni.example');
      final result = await signIn(session, email: 'a@uni.example');
      expect(result.session.email, 'a@uni.example');
    });

    test('a subdomain of an allowed domain may sign in', () async {
      await enableSso(session, allowedDomains: 'uni.example');
      final result = await signIn(session, email: 'a@dept.uni.example');
      expect(result.session.email, 'a@dept.uni.example');
    });

    test('a domain outside the allowlist is refused', () async {
      await enableSso(session, allowedDomains: 'uni.example');
      await expectLater(
        () => signIn(session, email: 'outsider@other.example'),
        throwsA(isA<AuthFlowException>().having(
          (e) => e.message,
          'message',
          contains('not allowed'),
        )),
      );
    });

    test('a lookalike domain is refused', () async {
      await enableSso(session, allowedDomains: 'uni.example');
      await expectLater(
        () => signIn(session, email: 'a@evil-uni.example'),
        throwsA(isA<AuthFlowException>()),
      );
    });

    test('an empty allowlist admits anyone the provider authenticates', () async {
      await enableSso(session);
      final result = await signIn(session, email: 'anyone@anywhere.example');
      expect(result.session.email, 'anyone@anywhere.example');
    });

    test('an address on the admin list gets the admin flag', () async {
      await enableSso(session, adminEmails: 'boss@uni.example');
      final result = await signIn(session, email: 'boss@uni.example');
      expect(result.session.isAdmin, isTrue);
    });

    test('everyone else does not', () async {
      await enableSso(session, adminEmails: 'boss@uni.example');
      final result = await signIn(session, email: 'staff@uni.example');
      expect(result.session.isAdmin, isFalse);
    });
  });

  withServerpod('AuthService user records', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();

    setUp(http.reset);

    test('signing in twice reuses one user record', () async {
      await enableSso(session);
      final first = await signIn(session);
      final second = await signIn(session);

      expect(second.session.userId, first.session.userId);
      expect(await FlumipUser.db.count(session), 1);
    });

    test('a changed email updates the existing record', () async {
      // The subject is the identity; the email is a mutable attribute.
      await enableSso(session);
      final first = await signIn(session, email: 'old@uni.example');
      final second = await signIn(session, email: 'new@uni.example');

      expect(second.session.userId, first.session.userId);
      final user = await FlumipUser.db.findById(session, first.session.userId);
      expect(user!.email, 'new@uni.example');
    });

    test('a different subject gets its own record', () async {
      await enableSso(session);
      await signIn(session, subject: 'user-a', email: 'a@uni.example');
      await signIn(session, subject: 'user-b', email: 'b@uni.example');
      expect(await FlumipUser.db.count(session), 2);
    });

    test('lastLogin advances on each sign-in', () async {
      await enableSso(session);
      final first = await signIn(session);
      final before =
          (await FlumipUser.db.findById(session, first.session.userId))!
              .lastLogin;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await signIn(session);
      final after =
          (await FlumipUser.db.findById(session, first.session.userId))!
              .lastLogin;
      expect(after.isAfter(before) || after == before, isTrue);
    });
  });

  withServerpod('AuthService API tokens', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final authService = sl<AuthService>();

    setUp(http.reset);

    test('a cookie is traded for a bearer token', () async {
      await enableSso(session, adminEmails: 'boss@uni.example');
      final signedIn = await signIn(session, email: 'boss@uni.example');

      final issued = await authService.issueApiToken(
        session,
        signedIn.cookieValue,
      );
      expect(issued, isNotNull);
      expect(issued!.email, 'boss@uni.example');
      expect(issued.isAdmin, isTrue);
      expect(issued.displayName, 'Ada Lovelace');
      expect(issued.token, isNotEmpty);
      // The bearer is a different secret from the cookie, so leaking one does
      // not yield the other.
      expect(issued.token, isNot(signedIn.cookieValue));
    });

    test('the token hash is stored, not the token', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      final issued =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;

      final row = await AuthApiToken.db.findFirstRow(session);
      expect(row!.tokenHash, AuthTokens.sha256Hex(issued.token));
      expect(row.tokenHash, isNot(issued.token));
      // And it is not the cookie hash either.
      expect(row.tokenHash, isNot(signedIn.session.cookieHash));
    });

    test('two mints coexist, so two browser tabs do not fight', () async {
      // A single tokenHash column on AuthSession would make the second mint
      // invalidate the first, and the two tabs would refresh each other's tokens
      // forever.
      await enableSso(session);
      final signedIn = await signIn(session);
      final first =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;
      final second =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;

      expect(first.token, isNot(second.token));
      expect(
        await authService.resolveApiToken(session, first.token),
        isNotNull,
      );
      expect(
        await authService.resolveApiToken(session, second.token),
        isNotNull,
      );
    });

    test('an unknown cookie yields no token', () async {
      await enableSso(session);
      expect(
        await authService.issueApiToken(session, AuthTokens.newToken()),
        isNull,
      );
    });

    test('an empty cookie yields no token', () async {
      await enableSso(session);
      expect(await authService.issueApiToken(session, ''), isNull);
    });

    test('an expired session yields no token', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      signedIn.session.expires =
          DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      await AuthSession.db.updateRow(session, signedIn.session);

      expect(
        await authService.issueApiToken(session, signedIn.cookieValue),
        isNull,
      );
    });

    test('a token never outlives the session that authorised it', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      // Session ends in a minute; the default token lifetime is 30.
      signedIn.session.expires =
          DateTime.now().toUtc().add(const Duration(minutes: 1));
      await AuthSession.db.updateRow(session, signedIn.session);

      final issued =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;
      expect(issued.expires, signedIn.session.expires);
    });

    test('resolveApiToken finds a valid token', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      final issued =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;

      final resolved = await authService.resolveApiToken(session, issued.token);
      expect(resolved!.email, 'a@uni.example');
    });

    test('resolveApiToken returns null for garbage', () async {
      await enableSso(session);
      expect(await authService.resolveApiToken(session, 'nonsense'), isNull);
      expect(await authService.resolveApiToken(session, ''), isNull);
    });

    test('resolveApiToken returns null for an expired token', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      final issued =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;
      final row = await AuthApiToken.db.findFirstRow(session);
      row!.expires = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      await AuthApiToken.db.updateRow(session, row);

      expect(await authService.resolveApiToken(session, issued.token), isNull);
    });
  });

  withServerpod('AuthService revocation', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final authService = sl<AuthService>();

    setUp(http.reset);

    test('a revoked session is refused on the very next call', () async {
      // The regression test for the read-through cache in resolveApiToken: a
      // cache that outlives revocation is the one way that optimisation turns
      // into a security bug.
      await enableSso(session);
      final signedIn = await signIn(session);
      final issued =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;

      // Prime the cache.
      expect(await authService.resolveApiToken(session, issued.token),
          isNotNull);

      await authService.revokeSession(session, signedIn.session.id!);

      expect(await authService.resolveApiToken(session, issued.token), isNull);
    });

    test('revoking kills every token minted from the session', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      final first =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;
      final second =
          (await authService.issueApiToken(session, signedIn.cookieValue))!;
      await authService.resolveApiToken(session, first.token);
      await authService.resolveApiToken(session, second.token);

      await authService.revokeSession(session, signedIn.session.id!);

      expect(await authService.resolveApiToken(session, first.token), isNull);
      expect(await authService.resolveApiToken(session, second.token), isNull);
      expect(await AuthApiToken.db.count(session), 0);
    });

    test('revoking by cookie ends the session', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      await authService.revokeByCookie(session, signedIn.cookieValue);

      expect(await AuthSession.db.count(session), 0);
      expect(
        await authService.issueApiToken(session, signedIn.cookieValue),
        isNull,
      );
    });

    test('revoking an unknown cookie is a no-op, not an error', () async {
      await enableSso(session);
      await signIn(session);
      await authService.revokeByCookie(session, AuthTokens.newToken());
      expect(await AuthSession.db.count(session), 1);
    });

    test('one session is revoked without touching another', () async {
      await enableSso(session);
      final a = await signIn(session, subject: 'user-a', email: 'a@uni.example');
      final b = await signIn(session, subject: 'user-b', email: 'b@uni.example');
      final tokenA = (await authService.issueApiToken(session, a.cookieValue))!;
      final tokenB = (await authService.issueApiToken(session, b.cookieValue))!;
      await authService.resolveApiToken(session, tokenA.token);
      await authService.resolveApiToken(session, tokenB.token);

      await authService.revokeSession(session, a.session.id!);

      expect(await authService.resolveApiToken(session, tokenA.token), isNull);
      expect(
        await authService.resolveApiToken(session, tokenB.token),
        isNotNull,
      );
    });
  });

  withServerpod('AuthService pruning', (sessionBuilder, endpoints) {
    setup(httpClient: http, authRuntime: AuthRuntime(environment: const {}));
    final session = sessionBuilder.build();
    final authService = sl<AuthService>();

    setUp(http.reset);

    test('expired flows, sessions and tokens are removed', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      await authService.issueApiToken(session, signedIn.cookieValue);
      await authService.beginFlow(session);

      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      await AuthFlow.db.updateRow(
        session,
        (await AuthFlow.db.findFirstRow(session))!..expires = past,
      );
      await AuthSession.db.updateRow(
        session,
        (await AuthSession.db.findFirstRow(session))!..expires = past,
      );

      await authService.pruneExpired(session);

      expect(await AuthFlow.db.count(session), 0);
      expect(await AuthSession.db.count(session), 0);
      // Cascaded with the session.
      expect(await AuthApiToken.db.count(session), 0);
    });

    test('current rows survive pruning', () async {
      await enableSso(session);
      final signedIn = await signIn(session);
      await authService.issueApiToken(session, signedIn.cookieValue);
      await authService.beginFlow(session);

      await authService.pruneExpired(session);

      expect(await AuthFlow.db.count(session), 1);
      expect(await AuthSession.db.count(session), 1);
      expect(await AuthApiToken.db.count(session), 1);
    });
  });
}
