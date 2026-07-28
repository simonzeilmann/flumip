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

    test('getSettings resets to a single default row when duplicated',
        () async {
      // Seed two rows so there is not exactly one; getSettings must reset.
      await Settings.db.insertRow(session, Settings());
      await Settings.db.insertRow(session, Settings());
      final settings = await settingsService.getSettings(session);
      expect(settings.baseDir, '/opt/flumip');
      final all = await Settings.db.find(session, where: (t) => t.id > 0);
      expect(all.length, 1);
    }, tags: ['unit']);
  });
}