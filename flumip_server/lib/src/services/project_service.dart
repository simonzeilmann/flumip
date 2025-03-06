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
    if (projectName == '') {
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

  Future<void> addGeneToProject(Session session, int id, String gene) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    }
    if (project.genes != null && project.genes!.contains(gene)) {
      throw Exception('Gene already exists in project');
    }
    if (gene.isEmpty || gene == '') {
      throw ArgumentError('Supplied gene empty');
    }
    if (RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
      project.genes ??= [];
      project.genes!.add(gene);
      await Project.db.updateRow(session, project);
    } else {
      throw ArgumentError('Gene name contains invalid characters');
    }
  }

  Future<void> removeGeneFromProject(
      Session session, int id, String gene) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    } else {
      if (project.genes == null) {
        throw Exception('Project does not have any genes');
      }
      project.genes!.remove(gene);
      await Project.db.updateRow(session, project);
    }
  }

  Future<void> addGenesToProject(
      Session session, int id, List<String> genes) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    } else {
      project.genes = genes;
      await Project.db.updateRow(session, project);
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
