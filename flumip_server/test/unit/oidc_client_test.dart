import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/auth/oidc_discovery.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/http_client.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';

/// Pure tests: [OidcClient] talks to the provider only through the
/// [HttpJsonClient] seam, so none of this needs a network or a database.
void main() {
  const issuer = 'https://idp.example.org';
  late FakeHttpJsonClient http;
  late OidcClient client;

  setUp(() {
    http = FakeHttpJsonClient();
    setup(httpClient: http);
    client = OidcClient();
  });

  AuthConfig configFor({
    String redirectUri = 'https://flumip.example/auth/callback',
  }) => AuthConfig.resolve(
    settings: Settings(
      loginRequired: true,
      oidcIssuer: issuer,
      oidcClientId: 'flumip',
      oidcClientSecret: 's3cret',
      oidcScopes: 'openid email profile',
      authPublicUrl: Uri.parse(redirectUri).origin,
    ),
    env: const {},
  );

  const discovery = OidcDiscovery(
    issuer: issuer,
    authorizationEndpoint: '$issuer/authorize',
    tokenEndpoint: '$issuer/token',
    userinfoEndpoint: '$issuer/userinfo',
  );

  group('discover', () {
    test('fetches the well-known document and parses the endpoints', () async {
      http.stubProvider(issuer: issuer);
      final result = await client.discover(issuer);

      expect(http.lastRequest!.url, '$issuer/.well-known/openid-configuration');
      expect(result.authorizationEndpoint, '$issuer/authorize');
      expect(result.tokenEndpoint, '$issuer/token');
      expect(result.userinfoEndpoint, '$issuer/userinfo');
      expect(result.supportsS256, isTrue);
    });

    test('accepts an issuer whose document declares a trailing slash', () async {
      // Providers are inconsistent about this and it must not break discovery.
      http.stubGet('$issuer/.well-known/openid-configuration', {
        'issuer': '$issuer/',
        'authorization_endpoint': '$issuer/authorize',
        'token_endpoint': '$issuer/token',
      });
      expect(await client.discover(issuer), isA<OidcDiscovery>());
    });

    test('refuses a document declaring a different issuer', () async {
      // OIDC Discovery §4.3: this is what stops a mistyped or hijacked discovery
      // URL from pointing this server at someone else's authorization endpoint.
      http.stubGet('$issuer/.well-known/openid-configuration', {
        'issuer': 'https://evil.example',
        'authorization_endpoint': 'https://evil.example/authorize',
        'token_endpoint': 'https://evil.example/token',
      });
      expect(
        () => client.discover(issuer),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('declares issuer'),
          ),
        ),
      );
    });

    test('refuses a document missing a required endpoint', () async {
      http.stubGet('$issuer/.well-known/openid-configuration', {
        'issuer': issuer,
        'authorization_endpoint': '$issuer/authorize',
      });
      expect(
        () => client.discover(issuer),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('token_endpoint'),
          ),
        ),
      );
    });

    test('notes when the provider does not advertise S256', () async {
      http.stubGet('$issuer/.well-known/openid-configuration', {
        'issuer': issuer,
        'authorization_endpoint': '$issuer/authorize',
        'token_endpoint': '$issuer/token',
        'code_challenge_methods_supported': ['plain'],
      });
      expect((await client.discover(issuer)).supportsS256, isFalse);
    });

    test('assumes S256 when the metadata field is absent', () async {
      // Providers that predate the field still support it, so its absence must
      // not be read as "unsupported".
      http.stubGet('$issuer/.well-known/openid-configuration', {
        'issuer': issuer,
        'authorization_endpoint': '$issuer/authorize',
        'token_endpoint': '$issuer/token',
      });
      expect((await client.discover(issuer)).supportsS256, isTrue);
    });

    test('surfaces the status and body when the provider errors', () async {
      http.getError = HttpJsonException(
        404,
        '$issuer/.well-known/openid-configuration',
        'Not Found',
      );
      expect(() => client.discover(issuer), throwsA(isA<HttpJsonException>()));
    });
  });

  group('authorizationUrl', () {
    test('carries every parameter the flow needs', () {
      final url = client.authorizationUrl(
        discovery: discovery,
        config: configFor(),
        state: 'the-state',
        nonce: 'the-nonce',
        codeVerifier: 'the-verifier',
      );

      expect(url.origin + url.path, '$issuer/authorize');
      final q = url.queryParameters;
      expect(q['response_type'], 'code');
      expect(q['client_id'], 'flumip');
      expect(q['redirect_uri'], 'https://flumip.example/auth/callback');
      expect(q['scope'], 'openid email profile');
      expect(q['state'], 'the-state');
      expect(q['nonce'], 'the-nonce');
      expect(q['code_challenge_method'], 'S256');
      expect(q['code_challenge'], AuthTokens.codeChallengeS256('the-verifier'));
    });

    test('never puts the code verifier itself in the URL', () {
      final url = client.authorizationUrl(
        discovery: discovery,
        config: configFor(),
        state: 's',
        nonce: 'n',
        codeVerifier: 'the-verifier',
      );
      // The whole point of PKCE: only the challenge travels via the browser.
      expect(url.toString(), isNot(contains('the-verifier')));
    });

    test(
      'preserves query parameters already on the authorization endpoint',
      () {
        const withQuery = OidcDiscovery(
          issuer: issuer,
          authorizationEndpoint: '$issuer/authorize?tenant=uni',
          tokenEndpoint: '$issuer/token',
        );
        final url = client.authorizationUrl(
          discovery: withQuery,
          config: configFor(),
          state: 's',
          nonce: 'n',
          codeVerifier: 'v',
        );
        expect(url.queryParameters['tenant'], 'uni');
        expect(url.queryParameters['response_type'], 'code');
      },
    );
  });

  group('exchangeCode', () {
    test('sends the grant, code, verifier and redirect URI', () async {
      http.stubProvider(
        issuer: issuer,
        idTokenClaims: {'iss': issuer, 'sub': 'u', 'aud': 'flumip', 'exp': 1},
      );

      await client.exchangeCode(
        discovery: discovery,
        config: configFor(),
        code: 'the-code',
        codeVerifier: 'the-verifier',
      );

      final request = http.lastPostTo('$issuer/token')!;
      expect(request.fields!['grant_type'], 'authorization_code');
      expect(request.fields!['code'], 'the-code');
      expect(request.fields!['code_verifier'], 'the-verifier');
      // Must match the authorization request exactly (RFC 6749 §4.1.3); a
      // mismatch is the most common cause of invalid_grant.
      expect(
        request.fields!['redirect_uri'],
        'https://flumip.example/auth/callback',
      );
      expect(request.fields!['client_id'], 'flumip');
    });

    test('authenticates with client_secret_basic', () async {
      http.stubProvider(
        issuer: issuer,
        idTokenClaims: {'iss': issuer, 'sub': 'u', 'aud': 'flumip', 'exp': 1},
      );
      await client.exchangeCode(
        discovery: discovery,
        config: configFor(),
        code: 'c',
        codeVerifier: 'v',
      );
      expect(http.lastPostTo('$issuer/token')!.basicAuth, ('flumip', 's3cret'));
    });

    test('returns the id token and access token', () async {
      http.stubPost('$issuer/token', {
        'id_token': 'a.b.c',
        'access_token': 'the-access-token',
      });
      final result = await client.exchangeCode(
        discovery: discovery,
        config: configFor(),
        code: 'c',
        codeVerifier: 'v',
      );
      expect(result.idToken, 'a.b.c');
      expect(result.accessToken, 'the-access-token');
    });

    test('explains a response with no id_token', () async {
      // What a client configured for plain OAuth 2 rather than OIDC returns.
      http.stubPost('$issuer/token', {'access_token': 'only-this'});
      expect(
        () => client.exchangeCode(
          discovery: discovery,
          config: configFor(),
          code: 'c',
          codeVerifier: 'v',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('openid'),
          ),
        ),
      );
    });

    test('propagates the provider error body', () async {
      http.postError = HttpJsonException(
        400,
        '$issuer/token',
        '{"error":"invalid_grant"}',
      );
      expect(
        () => client.exchangeCode(
          discovery: discovery,
          config: configFor(),
          code: 'c',
          codeVerifier: 'v',
        ),
        throwsA(
          isA<HttpJsonException>().having(
            (e) => e.toString(),
            'toString',
            contains('invalid_grant'),
          ),
        ),
      );
    });
  });

  group('userinfo', () {
    test('sends the access token as a bearer', () async {
      http.stubGet('$issuer/userinfo', {'email': 'a@uni.example'});
      final info = await client.userinfo(
        discovery: discovery,
        accessToken: 'the-access-token',
      );
      expect(info!['email'], 'a@uni.example');
      expect(http.lastRequest!.bearer, 'the-access-token');
    });

    test(
      'returns null when the provider advertises no userinfo endpoint',
      () async {
        const noUserinfo = OidcDiscovery(
          issuer: issuer,
          authorizationEndpoint: '$issuer/authorize',
          tokenEndpoint: '$issuer/token',
        );
        expect(
          await client.userinfo(discovery: noUserinfo, accessToken: 'x'),
          isNull,
        );
        expect(http.requests, isEmpty);
      },
    );
  });
}
