import 'package:serverpod/server.dart';

import '../services/project_service.dart';

class ProjectEndpoint extends Endpoint {
  get projectService => ProjectService();

  Future<bool> createProject(Session session, String name) async {
    return projectService.createProject(session, name);
  }

  Future<void> deleteProject(Session session, String name) async {
    projectService.deleteProject(session, name);
  }

  Future<List<String>> getProjects(Session session) async {
    return projectService.getProjects(session);
  }
}
