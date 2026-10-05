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
      // `aud` is a string or an array (RFC 7519 §4.1.3). Getting only the
      // string case right is a common way to break against providers that
      // always send an array.
      //
      // ⚠️ This used to assert that validation passed as well. It no longer
      // does without an `azp` — see the azp group below. Several audiences and
      // no way to tell which client the token was for is exactly the case
      // OIDC Core §3.1.3.7 item 4 asks about.
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(audience: ['flumip', 'another-client'])),
      );
      expect(parsed.audiences, ['flumip', 'another-client']);
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

  group('azp — OpenID Connect Core §3.1.3.7 items 4 and 5', () {
    // ⚠️ `aud` containing our client id is not enough on its own. A provider may
    // issue a token to client A and list client B as an extra audience, so
    // without azp a token minted for a different client of the same provider is
    // accepted here.
    test('a token issued to another client is refused', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(
          claims(
            audience: ['flumip', 'other-client'],
            extra: {'azp': 'other-client'},
          ),
        ),
      );
      expect(
        () => validate(parsed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('issued to "other-client"'),
          ),
        ),
      );
    });

    test('several audiences and no azp is refused', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(audience: ['flumip', 'other-client'])),
      );
      expect(
        () => validate(parsed),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('no "azp"'),
          ),
        ),
      );
    });

    test('several audiences with our azp is accepted', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(
          claims(audience: ['flumip', 'other'], extra: {'azp': 'flumip'}),
        ),
      );
      expect(() => validate(parsed), returnsNormally);
      expect(parsed.authorizedParty, 'flumip');
    });

    test('a single audience and no azp is the ordinary case', () {
      // Item 4 only asks for azp when there are several audiences. Requiring it
      // always would refuse most providers.
      final parsed = IdTokenClaims.parse(unsignedJwt(claims()));
      expect(() => validate(parsed), returnsNormally);
      expect(parsed.authorizedParty, isNull);
    });

    test('a single audience with a wrong azp is still refused', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(claims(extra: {'azp': 'somebody-else'})),
      );
      expect(() => validate(parsed), throwsA(isA<FormatException>()));
    });
  });

  group('the payload is kept for reading a configured claim', () {
    // Which claim carries group membership is a per-provider setting, so it
    // cannot be a field on IdTokenClaims — there is no standard name for it.
    test('carries claims this class has no field for', () {
      final parsed = IdTokenClaims.parse(
        unsignedJwt(
          claims(
            extra: {
              'groups': ['cardiology'],
              'realm_access': {
                'roles': ['research'],
              },
            },
          ),
        ),
      );
      expect(parsed.payload['groups'], ['cardiology']);
      expect(parsed.payload['realm_access'], {
        'roles': ['research'],
      });
    });
  });

  group('email_verified', () {
    test('is read when present, and null when the provider omits it', () {
      expect(
        IdTokenClaims.parse(
          unsignedJwt(claims(extra: {'email_verified': true})),
        ).emailVerified,
        isTrue,
      );
      expect(
        IdTokenClaims.parse(
          unsignedJwt(claims(extra: {'email_verified': false})),
        ).emailVerified,
        isFalse,
      );
      // ⚠️ Null is not false. AuthService treats the two differently: an
      // explicit false is refused, an absent claim is allowed and logged.
      expect(IdTokenClaims.parse(unsignedJwt(claims())).emailVerified, isNull);
    });
  });
}
