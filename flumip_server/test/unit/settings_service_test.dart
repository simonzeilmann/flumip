import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/password_hash.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Settings standard', (sessionBuilder, endpoints) {
    setup();
    var session = sessionBuilder.build();
    final settingsService = sl<SettingsService>();

    test(
      'calling `get settings` should return the standard settings',
      () async {
        final settings = await settingsService.getSettings(session);
        expect(settings.baseDir, "/opt/flumip");
      },
      tags: ['unit'],
    );
    test(
      'calling `updateSettings` should return the updated settings',
      () async {
        final settings = await settingsService.getSettings(session);
        settings.mipgenExecutable = "/new/path/to/mipgen";
        await settingsService.updateSettings(session, settings);
        final updatedSettings = await settingsService.getSettings(session);
        expect(updatedSettings.mipgenExecutable, "/new/path/to/mipgen");
      },
      tags: ['unit'],
    );
  });

  withServerpod('Settings password and reset', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final settingsService = SettingsService();

    test(
      'getSettingsExternal returns settings for the correct password',
      () async {
        // Ensure the default row (settingsPassword == "changeme") exists.
        await settingsService.getSettings(session);
        final settings = await settingsService.getSettingsExternal(
          session,
          'changeme',
        );
        expect(settings.baseDir, '/opt/flumip');
      },
      tags: ['unit'],
    );

    test('getSettingsExternal throws for an invalid password', () async {
      await settingsService.getSettings(session);
      expect(
        () => settingsService.getSettingsExternal(session, 'wrong'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                '$e'.contains('This password is not correct.'),
          ),
        ),
      );
    }, tags: ['unit']);

    test('getSettings never discards the existing row', () async {
      final original = await settingsService.getSettings(session);
      await settingsService.setSettingsPassword(session, 'not-the-default');
      original.loginRequired = true;
      await settingsService.updateSettings(session, original);

      // A second read must not reset the row back to its defaults: doing so
      // would restore settingsPassword = "changeme" and loginRequired = false.
      final reread = await settingsService.getSettings(session);
      expect(reread.id, original.id);
      expect(
        verifyPassword('not-the-default', reread.settingsPassword!),
        isTrue,
      );
      expect(reread.loginRequired, isTrue);
    }, tags: ['unit']);

    test('getSettings dedupes to the lowest id and keeps its values', () async {
      final kept = await settingsService.getSettings(session);
      await settingsService.setSettingsPassword(session, 'keep-me');

      // Seed extra rows so there is not exactly one.
      await Settings.db.insertRow(session, Settings());
      await Settings.db.insertRow(session, Settings());

      final settings = await settingsService.getSettings(session);
      expect(settings.id, kept.id);
      expect(verifyPassword('keep-me', settings.settingsPassword!), isTrue);
      final all = await Settings.db.find(session, where: (t) => t.id > 0);
      expect(all.length, 1);
    }, tags: ['unit']);

    test(
      'updateSettings merges onto the stored row rather than replacing it',
      () async {
        final stored = await settingsService.getSettings(session);

        // Simulates what the Flutter settings tab sends: a fresh object built
        // from the form controllers, carrying the stored row's id.
        final fromClient = Settings()
          ..id = stored.id
          ..smtpServer = 'smtp.example.org';
        await settingsService.updateSettings(session, fromClient);

        final reread = await settingsService.getSettings(session);
        expect(reread.id, stored.id);
        expect(reread.smtpServer, 'smtp.example.org');
      },
      tags: ['unit'],
    );

    test(
      'updateSettings never blanks the server-only OIDC client secret',
      () async {
        // Written the way SettingsEndpoint.setOidcClientSecret writes it: on the
        // stored row directly, never through the client-editable merge list.
        final stored = await settingsService.getSettings(session);
        stored.oidcClientSecret = 'top-secret';
        await Settings.db.updateRow(session, stored);

        // What the client sends: oidcClientSecret is serverOnly, so it is absent
        // from the wire format and deserializes as null. Saving anything else
        // must not erase it.
        final fromClient = Settings()
          ..id = stored.id
          ..smtpServer = 'smtp.example.org'
          ..oidcIssuer = 'https://idp.example.org';
        expect(fromClient.oidcClientSecret, isNull);
        await settingsService.updateSettings(session, fromClient);

        final reread = await settingsService.getSettings(session);
        expect(reread.oidcClientSecret, 'top-secret');
        expect(reread.oidcIssuer, 'https://idp.example.org');
      },
      tags: ['unit'],
    );
  });

  withServerpod('The settings password is stored hashed', (
    sessionBuilder,
    endpoints,
  ) {
    var session = sessionBuilder.build();
    final settingsService = SettingsService();

    test('a fresh install stores a hash, never the word itself', () async {
      // The whole point. It used to sit in the column as typed, and travel to
      // the browser on every getSettings besides.
      final settings = await settingsService.getSettings(session);
      expect(settings.settingsPassword, isNot(defaultSettingsPassword));
      expect(looksLikePasswordHash(settings.settingsPassword!), isTrue);
      expect(
        verifyPassword(defaultSettingsPassword, settings.settingsPassword!),
        isTrue,
      );
    }, tags: ['unit']);

    test('the default still opens the settings on a fresh install', () async {
      // An install nobody can configure is worse than one with a known default.
      final settings = await settingsService.getSettingsExternal(
        session,
        defaultSettingsPassword,
      );
      expect(settings.baseDir, '/opt/flumip');
    }, tags: ['unit']);

    test('a changed password works and the old one stops working', () async {
      await settingsService.getSettings(session);
      await settingsService.setSettingsPassword(session, 'a better password');

      expect(
        await settingsService.getSettingsExternal(session, 'a better password'),
        isA<Settings>(),
      );
      expect(
        () => settingsService.getSettingsExternal(
          session,
          defaultSettingsPassword,
        ),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                '$e'.contains('This password is not correct.'),
          ),
        ),
      );
    }, tags: ['unit']);

    test('⚠️ an empty password is refused, not stored', () async {
      // Unlike the SMTP password and the OIDC secret, where empty means "clear
      // it". Clearing this one leaves an install with sign-in off and no way
      // back into its own settings.
      await settingsService.getSettings(session);
      for (final empty in ['', '   ', '\t']) {
        expect(
          () => settingsService.setSettingsPassword(session, empty),
          throwsA(isA<ArgumentException>()),
          reason: 'stored "$empty"',
        );
      }

      final reread = await settingsService.getSettings(session);
      expect(
        verifyPassword(defaultSettingsPassword, reread.settingsPassword!),
        isTrue,
      );
    }, tags: ['unit']);

    test('⚠️ an ordinary settings save cannot touch the password', () async {
      // It is serverOnly, so it arrives as null from the client. If it were in
      // the merge list, every save from the settings tab would blank it.
      final stored = await settingsService.getSettings(session);
      final fromClient = Settings()
        ..id = stored.id
        ..smtpServer = 'smtp.example.org';
      expect(fromClient.settingsPassword, isNull);
      await settingsService.updateSettings(session, fromClient);

      final reread = await settingsService.getSettings(session);
      expect(
        verifyPassword(defaultSettingsPassword, reread.settingsPassword!),
        isTrue,
      );
      expect(reread.smtpServer, 'smtp.example.org');
    }, tags: ['unit']);

    test('reports whether the password is still the shipped default', () async {
      await settingsService.getSettings(session);
      expect(await settingsService.settingsPasswordIsDefault(session), isTrue);

      await settingsService.setSettingsPassword(session, 'something else');
      expect(await settingsService.settingsPasswordIsDefault(session), isFalse);
    }, tags: ['unit']);
  });

  withServerpod('A settings row that predates hashing', (
    sessionBuilder,
    endpoints,
  ) {
    var session = sessionBuilder.build();
    final settingsService = SettingsService();

    /// Puts the column back the way an install upgraded from an older build
    /// finds it: the password sitting there as typed.
    ///
    /// The migration only relaxes `NOT NULL` and drops the default, so every
    /// existing install arrives here — this is the state, not a hypothetical.
    Future<void> storePlaintext(String password) async {
      final stored = await settingsService.getSettings(session);
      stored.settingsPassword = password;
      await Settings.db.updateRow(session, stored);
    }

    test('⚠️ the plaintext password still works', () async {
      // It is the way back into a server whose identity provider has broken.
      // Invalidating it on upgrade would be a lockout delivered by deployment.
      await storePlaintext('legacy-secret');

      final settings = await settingsService.getSettingsExternal(
        session,
        'legacy-secret',
      );
      expect(settings.baseDir, '/opt/flumip');
    }, tags: ['unit']);

    test('and using it is what replaces it with a hash', () async {
      await storePlaintext('legacy-secret');
      await settingsService.getSettingsExternal(session, 'legacy-secret');

      final reread = await settingsService.getSettings(session);
      expect(looksLikePasswordHash(reread.settingsPassword!), isTrue);
      expect(verifyPassword('legacy-secret', reread.settingsPassword!), isTrue);

      // And it keeps working afterwards, through the hashed path this time.
      expect(
        await settingsService.getSettingsExternal(session, 'legacy-secret'),
        isA<Settings>(),
      );
    }, tags: ['unit']);

    test('a wrong password is refused and upgrades nothing', () async {
      await storePlaintext('legacy-secret');

      expect(
        () => settingsService.getSettingsExternal(session, 'not-it'),
        throwsA(
          predicate(
            (e) =>
                e is Exception &&
                '$e'.contains('This password is not correct.'),
          ),
        ),
      );

      final reread = await settingsService.getSettings(session);
      expect(reread.settingsPassword, 'legacy-secret');
    }, tags: ['unit']);

    test('a legacy "changeme" is still reported as the default', () async {
      await storePlaintext(defaultSettingsPassword);
      expect(await settingsService.settingsPasswordIsDefault(session), isTrue);
    }, tags: ['unit']);

    test('an empty column refuses every password', () async {
      // Not reachable through setSettingsPassword, which refuses to write one —
      // but a hand-edited database can get here, and "no password" must mean no
      // password rather than "any password".
      await storePlaintext('');

      for (final attempt in ['', 'changeme', 'anything']) {
        expect(
          () => settingsService.getSettingsExternal(session, attempt),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  '$e'.contains('This password is not correct.'),
            ),
          ),
          reason: 'tried "$attempt"',
        );
      }
    }, tags: ['unit']);
  });
}
