import 'package:serverpod/server.dart';

import '../services/project_service.dart';
import '../generated/protocol.dart';

class ProjectEndpoint extends Endpoint {
  get projectService => ProjectService();

  Future<Project> createProject(Session session, String name) async {
    return projectService.createProject(session, name);
  }

  Future<void> deleteProject(Session session, int id) async {
    projectService.deleteProject(session, id);
  }

  Future<List<Project>> getProjects(Session session) async {
    return projectService.getProjects(session);
  }

  Future<Project> getProject(Session session, int id) async {
    return projectService.getProject(session, id);
  }
}
