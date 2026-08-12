import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generation and hashing of the opaque credentials this server issues.
///
/// Nothing here is a JWT and nothing here is verifiable offline: the session
/// cookie and the API bearer are both random strings whose only meaning is the
/// database row they hash to. That is deliberate — it keeps revocation
/// immediate, which a self-contained signed token cannot offer.
abstract final class AuthTokens {
  /// 32 bytes is 256 bits of entropy, well past guessing range for a value that
  /// is also rate-limited by being a single indexed lookup.
  static const tokenBytes = 32;

  static final _random = Random.secure();

  /// A fresh URL-safe opaque token.
  ///
  /// Unpadded so it is safe in a cookie value and in an `Authorization` header
  /// without further escaping.
  static String newToken() {
    final bytes = List<int>.generate(tokenBytes, (_) => _random.nextInt(256));
    return _base64UrlUnpadded(bytes);
  }

  /// The sha256 of [value] as lower-case hex.
  ///
  /// Only hashes are persisted. A stolen database backup therefore yields no
  /// usable sessions, and there is no reversible secret at rest.
  static String sha256Hex(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  /// A PKCE code verifier: the same shape as [newToken], which satisfies the
  /// 43–128 character unreserved-character requirement of RFC 7636 §4.1.
  static String newCodeVerifier() => newToken();

  /// The S256 code challenge for [verifier], per RFC 7636 §4.2.
  ///
  /// base64url of the raw sha256 *bytes* — not of the hex string, which is the
  /// usual way to get this subtly wrong and produce an `invalid_grant` that
  /// gives no hint as to why.
  static String codeChallengeS256(String verifier) =>
      _base64UrlUnpadded(sha256.convert(ascii.encode(verifier)).bytes);

  static String _base64UrlUnpadded(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
