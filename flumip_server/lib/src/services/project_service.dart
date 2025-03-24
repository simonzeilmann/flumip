import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../generated/protocol.dart';
import 'package:uuid/uuid.dart';

/// A service class for handling project-related operations.
class ProjectService {
  ProjectService();

  /// Retrieves a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<Project> getProject(Session session, int id) async {
    session.log("Retrieving project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }
    session.log("Project retrieved with ID: $id", level: LogLevel.info);
    return project;
  }

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param projectName The name of the project to create.
  /// \param options The [ProjectOptions] for the project.
  /// \param desc An optional description for the project.
  /// \returns The created [Project] object.
  /// \throws [ArgumentError] if the project name is empty.
  Future<Project> createProject(
      Session session, String projectName, ProjectOptions options,
      [String? desc]) async {
    session.log("Creating project with name: $projectName",
        level: LogLevel.info);
    if (projectName == '') {
      session.log("Project name cannot be empty", level: LogLevel.error);
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
    session.log("Project created with ID: ${project.id}", level: LogLevel.info);
    return project;
  }

  /// Deletes a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<void> deleteProject(Session session, int id) async {
    session.log("Deleting project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    } else {
      await Project.db.deleteRow(session, project);
      await ProjectOptions.db.deleteWhere(
        session,
        where: (t) => t.id.equals(project.options),
      );

      if(project.active && project.pid != null && project.pid! > 0) {
        await sl<ProcessService>().terminateProcess(session, project.pid!);
      }
      var settings = await SettingsService().getSettings(session);
      Directory("${settings.projectDir}/${project.folderName}")
          .delete(recursive: true);
      session.log("Project deleted with ID: $id", level: LogLevel.info);
    }
  }

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [Exception] if the gene already exists in the project.
  /// \throws [ArgumentError] if the gene is empty or contains invalid characters.
  Future<void> addGeneToProject(Session session, int id, String gene) async {
    session.log("Adding gene to project with ID: $id", level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }
    if (project.genes != null && project.genes!.contains(gene)) {
      session.log("Gene already exists in project with ID: $id",
          level: LogLevel.error);
      throw Exception('Gene already exists in project');
    }
    if (gene.isEmpty || gene == '') {
      session.log("Supplied gene is empty", level: LogLevel.error);
      throw ArgumentError('Supplied gene empty');
    }
    if (RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
      project.genes ??= [];
      project.genes!.add(gene.toUpperCase());
      await Project.db.updateRow(session, project);
      session.log("Gene added to project with ID: $id", level: LogLevel.info);
    } else {
      session.log("Gene name contains invalid characters",
          level: LogLevel.error);
      throw ArgumentError('Gene name contains invalid characters');
    }
  }

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [Exception] if the project does not have any genes.
  Future<void> removeGeneFromProject(
      Session session, int id, String gene) async {
    session.log("Removing gene from project with ID: $id",
        level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    } else {
      if (project.genes == null) {
        session.log("Project does not have any genes", level: LogLevel.error);
        throw Exception('Project does not have any genes');
      }
      project.genes!.remove(gene);
      await Project.db.updateRow(session, project);
      session.log("Gene removed from project with ID: $id",
          level: LogLevel.info);
    }
  }

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  /// \throws [FileNotFoundException] if the project is not found.
  /// \throws [ArgumentError] if any gene is empty or contains invalid characters.
  Future<void> addGenesToProject(
      Session session, int id, List<String> genes) async {
    session.log("Adding multiple genes to project with ID: $id",
        level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    } else {
      for (var gene in genes) {
        if (gene.isEmpty || gene == '') {
          session.log("Supplied gene is empty", level: LogLevel.error);
          throw ArgumentError('Supplied gene empty');
        }
        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(gene)) {
          session.log("Gene name contains invalid characters",
              level: LogLevel.error);
          throw ArgumentError('Gene name contains invalid characters');
        }
      }
      project.genes = genes;
      await Project.db.updateRow(session, project);
      session.log("Multiple genes added to project with ID: $id",
          level: LogLevel.info);
    }
  }

  /// Retrieves all projects.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  Future<List<Project>> getProjects(Session session) async {
    session.log("Retrieving all projects", level: LogLevel.info);
    var projects = await Project.db.find(
      session,
      where: (t) => t.id > 0,
    );
    session.log("Projects retrieved", level: LogLevel.info);
    return projects;
  }

  /// Updates an existing project.
  ///
  /// \param session The current session.
  /// \param project The [Project] object to update.
  Future<void> updateProject(Session session, Project project) async {
    session.log("Updating project with ID: ${project.id}",
        level: LogLevel.info);
    await Project.db.updateRow(session, project);
    session.log("Project updated with ID: ${project.id}", level: LogLevel.info);
  }

  /// Sets the genome for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param geneId The ID of the genome to set.
  /// \throws [FileNotFoundException] if the project or genome is not found.
  Future<void> setGenomeById(Session session, int id, int geneId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }
    var genome = await Genome.db.findById(session, geneId);
    if (genome == null) {
      session.log("Gene not found with ID: $geneId", level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene not found');
    }
    project.genome = geneId;
    await Project.db.updateRow(session, project);
  }

  /// Sets the SNP for a project by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param snpId The ID of the SNP to set.
  /// \throws [FileNotFoundException] if the project or SNP is not found.
  Future<void> setSnpById(Session session, int id, int snpId) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }
    var snp = await Snp.db.findById(session, snpId);
    if (snp == null) {
      session.log("Snp not found with ID: $snpId", level: LogLevel.error);
      throw FileNotFoundException(message: 'Snp not found');
    }
    project.snp = snpId;
    await Project.db.updateRow(session, project);
  }
}