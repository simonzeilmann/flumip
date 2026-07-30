import 'dart:convert';

/// The claims of an ID token received from the token endpoint.
///
/// ## Why there is no signature verification here
///
/// This server obtains the ID token by POSTing directly to the provider's token
/// endpoint over TLS, authenticating itself with its client secret. OpenID
/// Connect Core §3.1.3.7 item 6 says exactly this case may skip signature
/// validation:
///
/// > If the ID Token is received via direct communication between the Client and
/// > the Token Endpoint (which it is in this flow), the TLS server validation
/// > MAY be used to validate the issuer in place of checking the token
/// > signature.
///
/// TLS already establishes that the bytes came from the provider, so a signature
/// check would re-verify the same fact using a key fetched over the same
/// channel. Skipping it removes a JWKS cache, key rotation handling and four
/// signature algorithms from this codebase.
///
/// **The precondition is structural and must stay that way**: [parse] has
/// exactly one caller, the `/auth/callback` route, acting on a response body it
/// just received from [OidcClient.exchangeCode]. Never add an endpoint, route or
/// service method that accepts an ID token from a client — an unsigned token is
/// trivially forged, and this comment is the only thing standing between that
/// and a full authentication bypass.
class IdTokenClaims {
  const IdTokenClaims({
    required this.issuer,
    required this.subject,
    required this.audiences,
    required this.expires,
    this.issuedAt,
    this.nonce,
    this.email,
    this.emailVerified,
    this.name,
  });

  final String issuer;
  final String subject;
  final List<String> audiences;
  final DateTime expires;
  final DateTime? issuedAt;
  final String? nonce;

  /// May be absent: `email` is in the `email` scope but not every provider
  /// returns it in the ID token even when granted. The callback falls back to
  /// the userinfo endpoint in that case.
  final String? email;
  final bool? emailVerified;
  final String? name;

  /// Decodes the payload of [idToken] without verifying its signature.
  ///
  /// See the class comment for why that is correct here, and for the one rule
  /// that keeps it correct.
  static IdTokenClaims parse(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw FormatException(
        'The ID token is not a JWT: expected three dot-separated parts, '
        'found ${parts.length}.',
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(utf8.decode(_decodeSegment(parts[1])))
          as Map<String, dynamic>;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('The ID token payload is not valid JSON: $e');
    }

    final expires = _requireTimestamp(payload, 'exp');
    final issuedAt = payload['iat'] == null ? null : _timestamp(payload['iat']);

    return IdTokenClaims(
      issuer: _requireString(payload, 'iss'),
      subject: _requireString(payload, 'sub'),
      audiences: _audiences(payload['aud']),
      expires: expires,
      issuedAt: issuedAt,
      nonce: payload['nonce'] as String?,
      email: (payload['email'] as String?)?.trim(),
      emailVerified: payload['email_verified'] as bool?,
      name: (payload['name'] ?? payload['preferred_username']) as String?,
    );
  }

  /// Checks the claims against what we asked for.
  ///
  /// Throws [FormatException] with a message meant to be readable in a server
  /// log by whoever is setting this up, since every one of these failures is a
  /// configuration problem rather than an attack in practice.
  void validate({
    required String issuer,
    required String clientId,
    required String nonce,
    required DateTime now,
    Duration skew = const Duration(minutes: 5),
  }) {
    if (this.issuer != issuer) {
      throw FormatException(
        'The ID token was issued by "${this.issuer}" but "$issuer" was '
        'expected.',
      );
    }
    if (!audiences.contains(clientId)) {
      throw FormatException(
        'The ID token is addressed to ${audiences.join(', ')} rather than to '
        'this client ("$clientId").',
      );
    }
    if (this.nonce != nonce) {
      // Guards against replaying an ID token from an unrelated sign-in.
      throw const FormatException(
        'The ID token nonce does not match the one sent with the '
        'authorization request.',
      );
    }
    if (now.isAfter(expires.add(skew))) {
      throw FormatException(
        'The ID token expired at $expires (now $now). If this is not a stale '
        'request, check that the clocks on this server and the identity '
        'provider agree.',
      );
    }
    if (subject.isEmpty) {
      throw const FormatException('The ID token has an empty subject.');
    }
  }

  /// `aud` is a string or an array of strings (RFC 7519 §4.1.3). Getting only
  /// the string case right is a common way to break against providers that
  /// always send an array.
  static List<String> _audiences(Object? aud) {
    if (aud is String) return [aud];
    if (aud is List) return aud.whereType<String>().toList();
    throw const FormatException('The ID token has no "aud" claim.');
  }

  /// JWT segments are base64url without padding; [base64Url.decode] requires
  /// the padding, so it has to be added back.
  static List<int> _decodeSegment(String segment) {
    final padded = segment.padRight((segment.length + 3) & ~3, '=');
    return base64Url.decode(padded);
  }

  static String _requireString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('The ID token is missing the "$key" claim.');
    }
    return value;
  }

  static DateTime _requireTimestamp(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      throw FormatException('The ID token is missing the "$key" claim.');
    }
    return _timestamp(value);
  }

  /// NumericDate: seconds since the epoch, UTC (RFC 7519 §2).
  static DateTime _timestamp(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).round(),
        isUtc: true,
      );
    }
    throw FormatException('Expected a numeric timestamp, found "$value".');
  }
}
