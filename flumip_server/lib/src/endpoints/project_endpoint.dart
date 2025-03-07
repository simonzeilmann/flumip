import 'package:serverpod/server.dart';

import '../services/project_service.dart';
import '../generated/protocol.dart';

class ProjectEndpoint extends Endpoint {
  get projectService => ProjectService();

  Future<Project> createProject(Session session, String name) async {
    try {
      return projectService.createProject(session, name);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProject(Session session, int id) async {
    try {
      return projectService.deleteProject(session, id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Project>> getProjects(Session session) async {
    try {
      return projectService.getProjects(session);
    } catch (e) {
      rethrow;
    }
  }

  Future<Project> getProject(Session session, int id) async {
    try {
      return projectService.getProject(session, id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addGeneToProject(Session session, int id, String gene) async {
    try {
      return projectService.addGeneToProject(session, id, gene);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeGeneFromProject(Session session, int id, String gene) async {
    try {
      return projectService.removeGeneFromProject(session, id, gene);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addGenesToProject(
      Session session, int id, List<String> genes) async {
    try {
      return projectService.addGenesToProject(session, id, genes);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    try {
      return projectService.getProjectOptions(session, id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProjectOptions(
      Session session, int id, ProjectOptions options) async {
    try {
      return projectService.updateProjectOptions(session, id, options);
    } catch (e) {
      rethrow;
    }
  }
}
