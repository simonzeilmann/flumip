import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
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

    test('getSettingsExternal returns settings for the correct password',
        () async {
      // Ensure the default row (settingsPassword == "changeme") exists.
      await settingsService.getSettings(session);
      final settings =
          await settingsService.getSettingsExternal(session, 'changeme');
      expect(settings.baseDir, '/opt/flumip');
    }, tags: ['unit']);

    test('getSettingsExternal throws for an invalid password', () async {
      await settingsService.getSettings(session);
      expect(
        () => settingsService.getSettingsExternal(session, 'wrong'),
        throwsA(predicate(
            (e) => e is Exception && '$e'.contains('Invalid password'))),
      );
    }, tags: ['unit']);

    test('getSettings never discards the existing row', () async {
      final original = await settingsService.getSettings(session);
      original.settingsPassword = 'not-the-default';
      original.loginRequired = true;
      await settingsService.updateSettings(session, original);

      // A second read must not reset the row back to its defaults: doing so
      // would restore settingsPassword = "changeme" and loginRequired = false.
      final reread = await settingsService.getSettings(session);
      expect(reread.id, original.id);
      expect(reread.settingsPassword, 'not-the-default');
      expect(reread.loginRequired, isTrue);
    }, tags: ['unit']);

    test('getSettings dedupes to the lowest id and keeps its values', () async {
      final kept = await settingsService.getSettings(session);
      kept.settingsPassword = 'keep-me';
      await settingsService.updateSettings(session, kept);

      // Seed extra rows so there is not exactly one.
      await Settings.db.insertRow(session, Settings());
      await Settings.db.insertRow(session, Settings());

      final settings = await settingsService.getSettings(session);
      expect(settings.id, kept.id);
      expect(settings.settingsPassword, 'keep-me');
      final all = await Settings.db.find(session, where: (t) => t.id > 0);
      expect(all.length, 1);
    }, tags: ['unit']);

    test('updateSettings merges onto the stored row rather than replacing it',
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
    }, tags: ['unit']);

    test('updateSettings never blanks the server-only OIDC client secret',
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
    }, tags: ['unit']);
  });
}