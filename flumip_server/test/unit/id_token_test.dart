import 'package:flumip_server/src/auth/id_token.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';

/// The tokens here are unsigned, which is the point: this server does not verify
/// the signature because the token arrives directly from the token endpoint over
/// TLS (OIDC Core §3.1.3.7). See the [IdTokenClaims] class comment.
void main() {
  final now = DateTime.utc(2026, 7, 30, 12);

  Map<String, dynamic> claims({
    String issuer = 'https://idp.example.org',
    Object? audience = 'flumip',
    String subject = 'user-123',
    String? nonce = 'the-nonce',
    String? email = 'a@uni.example',
    Object? extra,
  }) => {
    'iss': issuer,
    'aud': audience,
    'sub': subject,
    'exp': epochSeconds(now.add(const Duration(minutes: 5))),
    'iat': epochSeconds(now),
    'nonce': ?nonce,
    'email': ?email,
    if (extra is Map<String, dynamic>) ...extra,
  };

  void validate(IdTokenClaims parsed, {String nonce = 'the-nonce'}) =>
      parsed.validate(
        issuer: 'https://idp.example.org',
        clientId: 'flumip',
        nonce: nonce,
        now: now,
      );

  group('parse', () {
    test('reads the standard claims', () {
      final parsed = IdTokenClaims.parse(unsignedJwt(claims()));
      expect(parsed.issuer, 'https://idp.example.org');
      expect(parsed.subject, 'user-123');
      expect(parsed.audiences, ['flumip']);
      expect(parsed.email, 'a@uni.example');
      expect(parsed.nonce, 'the-nonce');
      expect(parsed.expires, now.add(const Duration(minutes: 5)));
      expect(parsed.issuedAt, now);
    });

    test('accepts an audience array', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(audience: ['flumip', 'another-client'])),
      );
      expect(parsed.audiences, ['flumip', 'another-client']);
      expect(() => validate(parsed), returnsNormally);
    });

    test('handles every base64url padding length', () {
      // JWT segments are unpadded, so the decoder has to restore the padding.
      // Varying the subject length walks the payload through all four residues.
      for (final padding in ['', 'a', 'ab', 'abc', 'abcd']) {
        final parsed = IdTokenClaims.parse(
          unsignedJwt(claims(subject: 'user-$padding')),
        );
        expect(parsed.subject, 'user-$padding');
      }
    });

    test('returns a null email when the claim is absent', () {
      // Drives the userinfo fallback in AuthService.completeCallback.
      final parsed = IdTokenClaims.parse(unsignedJwt(claims(email: null)));
      expect(parsed.email, isNull);
    });

    test('reads a display name from name or preferred_username', () {
      expect(
        IdTokenClaims.parse(
          unsignedJwt(claims(extra: {'name': 'Ada Lovelace'})),
        ).name,
        'Ada Lovelace',
      );
      expect(
        IdTokenClaims.parse(
          unsignedJwt(claims(extra: {'preferred_username': 'ada'})),
        ).name,
        'ada',
      );
    });

    test('reads a fractional exp', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt({...claims(), 'exp': epochSeconds(now) + 300.5}),
      );
      expect(parsed.expires.isAfter(now), isTrue);
    });

    test('rejects a token that is not three segments', () {
      expect(
        () => IdTokenClaims.parse('not.a-jwt'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('three dot-separated parts'),
          ),
        ),
      );
    });

    test('rejects a payload that is not base64url', () {
      expect(
        () => IdTokenClaims.parse('header.!!!not-base64!!!.signature'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a payload that is not JSON', () {
      expect(
        () => IdTokenClaims.parse('header.bm90LWpzb24.signature'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing iss, sub, aud or exp', () {
      for (final missing in ['iss', 'sub', 'aud', 'exp']) {
        final payload = claims()..remove(missing);
        expect(
          () => IdTokenClaims.parse(unsignedJwt(payload)),
          throwsA(isA<FormatException>()),
          reason: 'a token without "$missing" must be refused',
        );
      }
    });
  });

  group('validate', () {
    test('accepts a well-formed token', () {
      expect(
        () => validate(IdTokenClaims.parse(unsignedJwt(claims()))),
        returnsNormally,
      );
    });

    test('rejects the wrong issuer', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(issuer: 'https://evil.example')),
      );
      expect(
        () => validate(parsed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('was issued by'),
          ),
        ),
      );
    });

    test('rejects an audience that is not this client, as a string', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(audience: 'someone-else')),
      );
      expect(() => validate(parsed), throwsA(isA<FormatException>()));
    });

    test('rejects an audience array that does not contain this client', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(audience: ['a', 'b'])),
      );
      expect(() => validate(parsed), throwsA(isA<FormatException>()));
    });

    test('rejects a mismatched nonce', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(nonce: 'a-different-nonce')),
      );
      expect(
        () => validate(parsed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('nonce does not match'),
          ),
        ),
      );
    });

    test('rejects an absent nonce', () {
      final parsed = IdTokenClaims.parse(unsignedJwt(claims(nonce: null)));
      expect(() => validate(parsed), throwsA(isA<FormatException>()));
    });

    test('tolerates expiry within the clock skew allowance', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt({
          ...claims(),
          'exp': epochSeconds(now.subtract(const Duration(minutes: 2))),
        }),
      );
      // Two minutes past, five minutes of allowance: a modest clock difference
      // between this server and the provider must not break sign-in.
      expect(() => validate(parsed), returnsNormally);
    });

    test('rejects expiry beyond the clock skew allowance', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt({
          ...claims(),
          'exp': epochSeconds(now.subtract(const Duration(minutes: 10))),
        }),
      );
      expect(
        () => validate(parsed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('clocks'),
          ),
        ),
      );
    });

    test('honours a custom skew', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt({
          ...claims(),
          'exp': epochSeconds(now.subtract(const Duration(minutes: 2))),
        }),
      );
      expect(
        () => parsed.validate(
          issuer: 'https://idp.example.org',
          clientId: 'flumip',
          nonce: 'the-nonce',
          now: now,
          skew: Duration.zero,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
