import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/password_hash.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

/// The settings password used to start out as the well-known `changeme` on
/// every install and could be guessed at full speed. With it, an attacker can
/// set `mipgenExecutable` — code execution. These pin both fixes.
void main() {
  group('SettingsPasswordThrottle', () {
    late DateTime now;
    late SettingsPasswordThrottle throttle;

    setUp(() {
      now = DateTime.utc(2026, 11, 11, 12);
      throttle = SettingsPasswordThrottle(freeAttempts: 3, clock: () => now);
    });

    /// One wrong guess, made as soon as its turn comes.
    Duration fail() {
      final wait = throttle.acquire();
      now = now.add(wait);
      throttle.release(success: false);
      return wait;
    }

    test('lets the first few attempts through at once', () {
      expect([fail(), fail(), fail()], everyElement(Duration.zero));
    });

    test('then spaces guesses out, doubling up to a ceiling', () {
      fail();
      fail();
      fail();
      final waits = [for (var i = 0; i < 8; i++) fail().inSeconds];
      expect(waits, [1, 2, 4, 8, 16, 30, 30, 30]);
    });

    test('⚠️ parallel guesses queue instead of each getting a turn', () {
      // A sleep per request alone would be no limit against concurrency.
      fail();
      fail();
      fail();
      final waits = [for (var i = 0; i < 4; i++) throttle.acquire().inSeconds];
      expect(waits, [1, 3, 7, 15]);
    });

    test('refuses rather than queueing past the maximum wait', () {
      for (var i = 0; i < 9; i++) {
        fail();
      }
      throttle.acquire(); // 30 s away
      throttle.acquire(); // 60 s away
      expect(
        () => throttle.acquire(),
        throwsA(
          isA<ArgumentException>().having(
            (e) => e.message,
            'message',
            contains('Wait'),
          ),
        ),
      );
    });

    test('forgets the failures after a quiet spell', () {
      for (var i = 0; i < 8; i++) {
        fail();
      }
      now = now.add(const Duration(minutes: 16));
      expect(throttle.acquire(), Duration.zero);
    });

    test('a correct password clears the backoff for the next call', () {
      for (var i = 0; i < 8; i++) {
        fail();
      }
      final wait = throttle.acquire();
      expect(wait, greaterThan(Duration.zero));
      now = now.add(wait);
      throttle.release(success: true);

      // The administrator who just got in is not slowed on the next call…
      expect(throttle.acquire(), Duration.zero);
      throttle.release(success: true);
      expect(throttle.acquire(), Duration.zero);
      throttle.release(success: true);
      // …while a guesser gets exactly one undelayed guess out of it.
      expect(fail(), Duration.zero);
      expect(fail(), greaterThan(Duration.zero));
    });
  });

  test('generated passwords are long, readable and different', () {
    final a = generateSettingsPassword();
    final b = generateSettingsPassword();
    expect(a, matches(RegExp(r'^[a-zA-Z2-9]{5}(-[a-zA-Z2-9]{5}){3}$')));
    expect(a, isNot(contains(RegExp('[01lIO]'))));
    expect(a, isNot(b));
  });

  withServerpod('The first settings password', (sessionBuilder, endpoints) {
    setup();
    final session = sessionBuilder.build();

    Future<void> freshInstall() =>
        Settings.db.deleteWhere(session, where: (t) => t.id > 0);

    test('is changeme in test and development run modes', () async {
      await freshInstall();
      final lines = <String>[];
      final service = SettingsService(
        runMode: ServerpodRunMode.development,
        announce: lines.add,
      );
      final settings = await service.getSettings(session);
      expect(
        verifyPassword(defaultSettingsPassword, settings.settingsPassword!),
        isTrue,
      );
      expect(lines, isEmpty);
    });

    test('⚠️ is random in production, and announced exactly once', () async {
      await freshInstall();
      final lines = <String>[];
      final service = SettingsService(
        runMode: ServerpodRunMode.production,
        environment: const {},
        announce: lines.add,
      );

      final settings = await service.getSettings(session);
      await service.getSettings(session);

      expect(lines, hasLength(1));
      expect(lines.single, startsWith(initialSettingsPasswordLogPrefix));
      final password = lines.single
          .substring(initialSettingsPasswordLogPrefix.length)
          .split('\n')
          .first;

      // Only the hash is stored.
      expect(settings.settingsPassword, isNot(contains(password)));
      expect(verifyPassword(password, settings.settingsPassword!), isTrue);
      expect(
        verifyPassword(defaultSettingsPassword, settings.settingsPassword!),
        isFalse,
      );
      expect(await service.settingsPasswordIsDefault(session), isFalse);
      expect(await service.getSettingsExternal(session, password), isNotNull);
    });

    test('comes from FLUMIP_INITIAL_SETTINGS_PASSWORD when set', () async {
      await freshInstall();
      final lines = <String>[];
      final service = SettingsService(
        runMode: ServerpodRunMode.production,
        environment: const {initialSettingsPasswordEnv: 'from the installer'},
        announce: lines.add,
      );

      final settings = await service.getSettings(session);
      expect(
        verifyPassword('from the installer', settings.settingsPassword!),
        isTrue,
      );
      // The installer already knows it; it is never printed.
      expect(lines, isEmpty);
    });

    test('never touches an existing install', () async {
      // An install still on changeme keeps working — and keeps being nagged.
      final dev = SettingsService(runMode: ServerpodRunMode.development);
      await dev.getSettings(session);

      final lines = <String>[];
      final prod = SettingsService(
        runMode: ServerpodRunMode.production,
        environment: const {initialSettingsPasswordEnv: 'ignored'},
        announce: lines.add,
      );
      expect(
        await prod.getSettingsExternal(session, defaultSettingsPassword),
        isNotNull,
      );
      expect(await prod.settingsPasswordIsDefault(session), isTrue);
      expect(lines, isEmpty);
    });
  });

  withServerpod('Guessing the settings password', (sessionBuilder, endpoints) {
    setup();
    final session = sessionBuilder.build();

    test('slows down after repeated wrong guesses, and recovers', () async {
      var now = DateTime.utc(2026, 11, 11, 12);
      final slept = <Duration>[];
      final service = SettingsService(
        throttle: SettingsPasswordThrottle(freeAttempts: 2, clock: () => now),
        sleep: (d) async {
          slept.add(d);
          now = now.add(d);
        },
      );
      await service.getSettings(session);

      Future<void> guess() => expectLater(
        service.getSettingsExternal(session, 'wrong'),
        throwsA(isA<ArgumentException>()),
      );

      await guess();
      await guess();
      expect(slept, isEmpty);
      await guess();
      await guess();
      expect(slept.map((d) => d.inSeconds), [1, 2]);

      // The right password still gets in — after its turn — and the next call
      // from the administrator is not delayed at all.
      await service.getSettingsExternal(session, defaultSettingsPassword);
      expect(slept.map((d) => d.inSeconds), [1, 2, 4]);
      await service.getSettingsExternal(session, defaultSettingsPassword);
      expect(slept, hasLength(3));
    });

    test('a signed-in administrator is never throttled', () async {
      // The short-circuit before any hashing also skips the throttle, so a
      // flood of guesses cannot keep an SSO administrator out.
      final throttle = SettingsPasswordThrottle(freeAttempts: 0);
      final service = SettingsService(throttle: throttle);
      for (var i = 0; i < 3; i++) {
        throttle.acquire();
        throttle.release(success: false);
      }
      final admin = sessionBuilder
          .copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              'boss@uni.example',
              {adminScope},
            ),
          )
          .build();
      await expectLater(service.getSettingsExternal(admin, 'wrong'), completes);
    });
  });
}
