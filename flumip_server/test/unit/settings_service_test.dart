import 'package:flumip_server/src/services/settings_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Settings standard', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();
    final settingsService = SettingsService();

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
}