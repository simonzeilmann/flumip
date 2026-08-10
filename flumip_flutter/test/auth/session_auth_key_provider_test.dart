import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_client/serverpod_client.dart';

void main() {
  SessionTokenResponse tokenNamed(String token, {int minutes = 30}) =>
      SessionTokenResponse(
        token: token,
        expiresIn: Duration(minutes: minutes),
        email: 'a@uni.example',
      );

  group('refreshAuthKey', () {
    test('reports success and exposes the token as a Bearer header', () async {
      final provider = SessionAuthKeyProvider(
        fetchSession: () async => tokenNamed('t1'),
      );
      expect(await provider.refreshAuthKey(), RefreshAuthKeyResult.success);
      expect(await provider.authHeaderValue, wrapAsBearerAuthHeaderValue('t1'));
    });

    test('reports failedUnauthorized when the session is gone', () async {
      // 401 from /auth/session, i.e. the cookie expired or was signed out.
      final provider = SessionAuthKeyProvider(fetchSession: () async => null);
      expect(
        await provider.refreshAuthKey(),
        RefreshAuthKeyResult.failedUnauthorized,
      );
      expect(await provider.authHeaderValue, isNull);
    });

    test('reports failedOther when the request itself fails', () async {
      // Distinguishing these matters: the mutex decorator memoises
      // failedUnauthorized and stops trying, which would be wrong for a
      // transient network problem on a session that is still valid.
      final provider = SessionAuthKeyProvider(
        fetchSession: () async => throw Exception('connection reset'),
      );
      expect(await provider.refreshAuthKey(), RefreshAuthKeyResult.failedOther);
    });

    test('skips while the token is still comfortably valid', () async {
      var calls = 0;
      final provider = SessionAuthKeyProvider(
        fetchSession: () async {
          calls++;
          return tokenNamed('t1');
        },
      );
      await provider.refreshAuthKey();
      expect(await provider.refreshAuthKey(), RefreshAuthKeyResult.skipped);
      expect(calls, 1);
    });

    test('renews inside the refresh margin, before the token expires', () async {
      // Renewing early means a request in flight at expiry does not have to fail
      // and be retried.
      var calls = 0;
      final provider = SessionAuthKeyProvider(
        refreshMargin: const Duration(minutes: 5),
        fetchSession: () async {
          calls++;
          return tokenNamed('t$calls', minutes: 3);
        },
      );
      await provider.refreshAuthKey();
      expect(await provider.refreshAuthKey(), RefreshAuthKeyResult.success);
      expect(calls, 2);
    });

    test('force renews even when the token is fresh', () async {
      var calls = 0;
      final provider = SessionAuthKeyProvider(
        fetchSession: () async {
          calls++;
          return tokenNamed('t$calls');
        },
      );
      await provider.refreshAuthKey();
      expect(
        await provider.refreshAuthKey(force: true),
        RefreshAuthKeyResult.success,
      );
      expect(calls, 2);
      expect(await provider.authHeaderValue, wrapAsBearerAuthHeaderValue('t2'));
    });

    test('a lost session clears the token', () async {
      var signedIn = true;
      final provider = SessionAuthKeyProvider(
        fetchSession: () async => signedIn ? tokenNamed('t1') : null,
      );
      await provider.refreshAuthKey();
      expect(await provider.authHeaderValue, isNotNull);

      signedIn = false;
      await provider.refreshAuthKey(force: true);
      expect(await provider.authHeaderValue, isNull);
      expect(provider.lastSession, isNull);
    });

    test('stops asking once the session is proven gone', () async {
      // The poll-storm guard. Without it the app's ten-second timers would hit
      // /auth/session once per tick per timer, forever, after a session expires.
      var calls = 0;
      final provider = SessionAuthKeyProvider(
        fetchSession: () async {
          calls++;
          return null;
        },
      );

      for (var i = 0; i < 10; i++) {
        expect(
          await provider.refreshAuthKey(),
          RefreshAuthKeyResult.failedUnauthorized,
        );
      }
      expect(calls, 1);
    });

    test(
      'a forced refresh asks again, so a recovered session is noticed',
      () async {
        var signedIn = false;
        var calls = 0;
        final provider = SessionAuthKeyProvider(
          fetchSession: () async {
            calls++;
            return signedIn ? tokenNamed('t1') : null;
          },
        );

        await provider.refreshAuthKey();
        await provider.refreshAuthKey();
        expect(calls, 1, reason: 'the second call is memoised');

        signedIn = true;
        expect(
          await provider.refreshAuthKey(force: true),
          RefreshAuthKeyResult.success,
        );
        expect(calls, 2);
        // And normal refreshes work again afterwards.
        expect(await provider.refreshAuthKey(), RefreshAuthKeyResult.skipped);
      },
    );

    test('clear() forgets the token without a request', () async {
      var calls = 0;
      final provider = SessionAuthKeyProvider(
        fetchSession: () async {
          calls++;
          return tokenNamed('t1');
        },
      );
      await provider.refreshAuthKey();
      provider.clear();
      expect(await provider.authHeaderValue, isNull);
      expect(calls, 1);
    });
  });

  group('wrapped in the framework mutex decorator', () {
    test('stops retrying once the credential is proven dead', () async {
      // This is what keeps the app's ten-second polling timers from turning an
      // expired session into a refresh storm.
      var calls = 0;
      final provider = SessionAuthKeyProvider.wrapped(
        fetchSession: () async {
          calls++;
          return null;
        },
      );

      expect(
        await provider.refreshAuthKey(),
        RefreshAuthKeyResult.failedUnauthorized,
      );
      final callsAfterFirst = calls;

      for (var i = 0; i < 10; i++) {
        expect(
          await provider.refreshAuthKey(),
          RefreshAuthKeyResult.failedUnauthorized,
        );
      }
      expect(
        calls,
        callsAfterFirst,
        reason: 'the decorator must not keep asking a dead session',
      );
    });

    test('a valid session yields a header through the decorator', () async {
      final provider = SessionAuthKeyProvider.wrapped(
        fetchSession: () async => tokenNamed('t1'),
      );
      expect(await provider.authHeaderValue, wrapAsBearerAuthHeaderValue('t1'));
    });
  });

  group('SessionTokenResponse.fromJson', () {
    test('reads what /auth/session sends', () async {
      final parsed = SessionTokenResponse.fromJson({
        'token': 'abc',
        'expiresIn': 1800,
        'email': 'a@uni.example',
        'displayName': 'Ada',
        'isAdmin': true,
      });
      expect(parsed.token, 'abc');
      expect(parsed.expiresIn, const Duration(minutes: 30));
      expect(parsed.email, 'a@uni.example');
      expect(parsed.displayName, 'Ada');
      expect(parsed.isAdmin, isTrue);
    });

    test('tolerates the optional fields being absent', () async {
      final parsed = SessionTokenResponse.fromJson({
        'token': 'abc',
        'expiresIn': 60,
      });
      expect(parsed.email, isEmpty);
      expect(parsed.displayName, isEmpty);
      expect(parsed.isAdmin, isFalse);
    });
  });
}
