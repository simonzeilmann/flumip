import 'package:serverpod/server.dart';

import '../generated/project_options.dart';
import '../services/options_service.dart';

class OptionsEndpoint extends Endpoint {
  get optionsService => OptionsService();

  Future<ProjectOptions> createProjectOptions(Session session) async {
    try {
      return optionsService.createProjectOptions(session);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    try {
      return optionsService.getProjectOptions(session, id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProjectOptions(
      Session session, int id, ProjectOptions options) async {
    try {
      return optionsService.updateProjectOptions(session, id, options);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProjectOptions(Session session, int id) async {
    try {
      return optionsService.deleteProjectOptions(session, id);
    } catch (e) {
      rethrow;
    }
  }
}
