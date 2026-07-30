import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/oidc_discovery.dart';
import 'package:flumip_server/src/services/http_client.dart';

/// The result of a successful authorization-code exchange.
class TokenResponse {
  const TokenResponse({required this.idToken, this.accessToken});

  final String idToken;

  /// Kept only for the immediately following userinfo call when the ID token
  /// carries no email. Never persisted: once the exchange is done this server
  /// has no further business with the provider, so storing it would create a
  /// long-lived credential with no purpose.
  final String? accessToken;
}

/// The protocol half of the OIDC flow: the three HTTPS calls, and building the
/// authorization URL.
///
/// Holds no state and touches no database, so all of it is testable against a
/// fake [HttpJsonClient].
class OidcClient {
  OidcClient();

  HttpJsonClient get _http => sl<HttpJsonClient>();

  /// Fetches and validates the discovery document for [issuer].
  Future<OidcDiscovery> discover(String issuer) async {
    final url = '$issuer/.well-known/openid-configuration';
    final json = await _http.getJson(url);
    return OidcDiscovery.parse(json, expectedIssuer: issuer);
  }

  /// The URL to redirect the browser to, starting the flow.
  ///
  /// PKCE is included even though this is a confidential client with a secret:
  /// it costs nothing and it closes authorization-code injection, which the
  /// secret alone does not (OAuth 2.1 makes it mandatory for this reason).
  Uri authorizationUrl({
    required OidcDiscovery discovery,
    required AuthConfig config,
    required String state,
    required String nonce,
    required String codeVerifier,
  }) {
    final base = Uri.parse(discovery.authorizationEndpoint);
    return base.replace(
      queryParameters: {
        // Preserved so a provider that puts query parameters in its
        // authorization endpoint keeps them.
        ...base.queryParameters,
        'response_type': 'code',
        'client_id': config.clientId,
        'redirect_uri': config.redirectUri,
        'scope': config.scopes,
        'state': state,
        'nonce': nonce,
        'code_challenge': AuthTokens.codeChallengeS256(codeVerifier),
        'code_challenge_method': 'S256',
      },
    );
  }

  /// Exchanges an authorization [code] for an ID token.
  ///
  /// `redirect_uri` has to be sent again and has to match the one used in the
  /// authorization request exactly (RFC 6749 §4.1.3) — a mismatch here is the
  /// most common cause of `invalid_grant`.
  Future<TokenResponse> exchangeCode({
    required OidcDiscovery discovery,
    required AuthConfig config,
    required String code,
    required String codeVerifier,
  }) async {
    final json = await _http.postForm(
      discovery.tokenEndpoint,
      fields: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': config.redirectUri,
        'code_verifier': codeVerifier,
        // Also sent in the body, not only in the Basic header: some providers
        // require it there, and none object to the redundancy.
        'client_id': config.clientId,
      },
      basicAuth: (config.clientId, config.clientSecret),
    );

    final idToken = json['id_token'];
    if (idToken is! String || idToken.isEmpty) {
      throw FormatException(
        'The token endpoint returned no id_token. Check that the "openid" '
        'scope is requested and that the client is configured for OpenID '
        'Connect rather than plain OAuth 2.',
      );
    }
    return TokenResponse(
      idToken: idToken,
      accessToken: json['access_token'] as String?,
    );
  }

  /// Fetches the email and display name from the userinfo endpoint.
  ///
  /// Only used when the ID token carried no `email` claim. Returns null when the
  /// provider advertises no userinfo endpoint.
  Future<Map<String, dynamic>?> userinfo({
    required OidcDiscovery discovery,
    required String accessToken,
  }) async {
    final endpoint = discovery.userinfoEndpoint;
    if (endpoint == null || endpoint.isEmpty) return null;
    return _http.getJson(endpoint, bearer: accessToken);
  }
}
