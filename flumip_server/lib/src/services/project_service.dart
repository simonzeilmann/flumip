import 'dart:io';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../generated/protocol.dart';
import 'package:uuid/uuid.dart';

class ProjectService {
  ProjectService();

  Future<Project> getProject(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    }
    return project;
  }

  Future<Project> createProject(
      Session session, String projectName, ProjectOptions options,
      [String? desc]) async {
    if (projectName == '') {
      throw ArgumentError('Project name cannot be empty');
    }

    var projectRow = Project(
        name: projectName,
        description: desc,
        folderName: Uuid().v7(),
        options: options.id!);
    var project = await Project.db.insertRow(session, projectRow);

    var settings = await SettingsService().getSettings(session);
    await Directory("${settings.projectDir}/${project.folderName}").create();
    return project;
  }

  Future<void> deleteProject(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    } else {
      await Project.db.deleteRow(session, project);
      await ProjectOptions.db.deleteWhere(
        session,
        where: (t) => t.id.equals(project.options),
      );

      var settings = await SettingsService().getSettings(session);
      Directory("${settings.projectDir}/${project.folderName}")
          .delete(recursive: true);
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
      project.genes!.add(gene.toUpperCase());
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
      for (var gene in genes) {
        if (gene.isEmpty || gene == '') {
          gene.toUpperCase();
        }
        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
          throw ArgumentError('Gene name contains invalid characters');
        }
      }
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

  updateProject(Session session, Project project) {
    Project.db.updateRow(session, project);
  }
}
