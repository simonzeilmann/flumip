import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:test/test.dart';

void main() {
  group('newToken', () {
    test('is URL-safe and unpadded', () {
      for (var i = 0; i < 50; i++) {
        final token = AuthTokens.newToken();
        // Safe to drop straight into a cookie value and an Authorization header.
        expect(token, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
        expect(token, isNot(contains('=')));
      }
    });

    test('encodes 32 bytes', () {
      // 32 bytes base64-encode to 44 characters including one pad character.
      expect(AuthTokens.newToken().length, 43);
    });

    test('contains no colon, which is why the wire scheme must be Bearer', () {
      // Serverpod's wrapAsBasicAuthHeaderValue is built for its own auth keys,
      // which have the shape `id:hash`. relic's typed `authorization` parser
      // base64-decodes a `Basic` value and splits it on a colon, so a token
      // without one is rejected with a 400 *before* the authentication handler
      // runs. base64url tokens never contain a colon, so `Basic` can never work
      // here — see SessionAuthKeyProvider.authHeaderValue.
      for (var i = 0; i < 100; i++) {
        expect(AuthTokens.newToken(), isNot(contains(':')));
      }
    });

    test('does not repeat', () {
      final tokens = {for (var i = 0; i < 1000; i++) AuthTokens.newToken()};
      expect(tokens, hasLength(1000));
    });
  });

  group('sha256Hex', () {
    test('matches a known digest', () {
      expect(
        AuthTokens.sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('is stable and 64 hex characters', () {
      final hash = AuthTokens.sha256Hex(AuthTokens.newToken());
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('differs for different inputs', () {
      expect(AuthTokens.sha256Hex('a'), isNot(AuthTokens.sha256Hex('b')));
    });
  });

  group('codeChallengeS256', () {
    test('matches the worked example from RFC 7636 appendix B', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expected = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
      expect(AuthTokens.codeChallengeS256(verifier), expected);
    });

    test('hashes the raw bytes, not the hex digest', () {
      // Getting this wrong yields an invalid_grant with no hint as to why, so it
      // is worth pinning explicitly.
      const verifier = 'some-verifier';
      final hexOfDigest = sha256.convert(ascii.encode(verifier)).toString();
      expect(
        AuthTokens.codeChallengeS256(verifier),
        isNot(base64Url.encode(utf8.encode(hexOfDigest)).replaceAll('=', '')),
      );
    });

    test('is URL-safe and unpadded', () {
      final challenge = AuthTokens.codeChallengeS256(AuthTokens.newToken());
      expect(challenge, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });
  });

  group('newCodeVerifier', () {
    test('satisfies the RFC 7636 length and character requirements', () {
      final verifier = AuthTokens.newCodeVerifier();
      expect(verifier.length, greaterThanOrEqualTo(43));
      expect(verifier.length, lessThanOrEqualTo(128));
      expect(verifier, matches(RegExp(r'^[A-Za-z0-9._~-]+$')));
    });
  });
}
