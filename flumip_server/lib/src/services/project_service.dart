import 'dart:io';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../generated/protocol.dart';

class ProjectService {

  late final String projectFolder;

  ProjectService() {
    projectFolder = "/opt/mipgen/projects";
  }

  Future<Project> getProject(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    }
    return project;
  }

  Future<Project> createProject(Session session, String projectName) async {
    if(projectName == '') {
      throw ArgumentError('Project name cannot be empty');
    }
    var row = Project(name: projectName);
    var project = await Project.db.insertRow(session, row);

    await Directory("$projectFolder/${project.id}").create();
    return project;
  }

  Future<void> deleteProject(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    } else {
      await Project.db.deleteRow(session, project);
      Directory("$projectFolder/$id").delete(recursive: true);
    }
  }

  Future<List<Project>> getProjects(Session session) async {
    var projects = await Project.db.find(
      session,
      where: (t) => t.id > 0,
    );

    return projects;
  }

  Future<bool> checkProjectDirectoryExists(int id) async {
    return await Directory("$projectFolder/$id").exists();
  }

  updateProject(Session session, Project project) {
    Project.db.updateRow(session, project);
  }
}
