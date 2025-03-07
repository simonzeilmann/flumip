import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/settings_service.dart';

class SettingsEndpoint extends Endpoint {
  get settingsService => SettingsService();

  Future<Settings> getSettings(Session session) async {
    return settingsService.getSettings(session);
  }

  Future<void> updateSettings(Session session, Settings settings) async {
    return settingsService.updateSettings(session, settings);
  }
}