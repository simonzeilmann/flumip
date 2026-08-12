/// The subset of an OpenID Connect discovery document this server uses.
///
/// Fetched from `<issuer>/.well-known/openid-configuration` so that an admin
/// only has to supply the issuer, rather than transcribing four endpoint URLs.
class OidcDiscovery {
  const OidcDiscovery({
    required this.issuer,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.userinfoEndpoint,
    this.supportsS256 = true,
  });

  final String issuer;
  final String authorizationEndpoint;
  final String tokenEndpoint;

  /// Optional: used only when the ID token carries no `email` claim.
  final String? userinfoEndpoint;

  /// Whether the provider advertises PKCE with S256.
  ///
  /// Advisory only. Providers that predate the metadata field omit it while
  /// still supporting S256, so this is not used to refuse a sign-in — it is
  /// surfaced in the settings tab's discovery probe instead.
  final bool supportsS256;

  /// Parses a discovery document, checking that it describes [expectedIssuer].
  ///
  /// The issuer check is not a formality: it is what stops a mistyped or
  /// hijacked discovery URL from pointing this server at someone else's
  /// authorization endpoint (OIDC Discovery §4.3).
  static OidcDiscovery parse(
    Map<String, dynamic> json, {
    required String expectedIssuer,
  }) {
    final issuer = _requireString(json, 'issuer');
    if (_normalise(issuer) != _normalise(expectedIssuer)) {
      throw FormatException(
        'The discovery document declares issuer "$issuer" but was fetched for '
        '"$expectedIssuer". Check the issuer setting for a typo or a stray '
        'path segment.',
      );
    }

    final methods = json['code_challenge_methods_supported'];

    return OidcDiscovery(
      issuer: issuer,
      authorizationEndpoint: _requireString(json, 'authorization_endpoint'),
      tokenEndpoint: _requireString(json, 'token_endpoint'),
      userinfoEndpoint: json['userinfo_endpoint'] as String?,
      supportsS256: methods is! List || methods.contains('S256'),
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'The discovery document is missing the required "$key" field.',
      );
    }
    return value;
  }

  static String _normalise(String issuer) {
    var result = issuer.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
