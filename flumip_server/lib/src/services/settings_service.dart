import 'package:serverpod/server.dart';

import '../generated/protocol.dart';

class SettingsService {

  SettingsService();

  Future<Settings> getSettings(Session session) async {
    await _checkAndCreateSettings(session);
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
    );
    if (settings.isEmpty || settings.length != 1) {
      throw Exception('Failed to load settings');
    }
    return settings.first;
  }

  Future<void> _checkAndCreateSettings(Session session) async {
    var settings = await Settings.db.find(
      session,
      where: (t) => t.id > 0,
    );
    if (settings.isEmpty || settings.length != 1) {
      await Settings.db.deleteWhere(
        session,
        where: (t) => t.id > 0,
      );
      await Settings.db.insertRow(session, Settings());
    }
  }

  Future<void> updateSettings(Session session, Settings settings) async {
    await Settings.db.updateRow(session, settings);
  }
}
