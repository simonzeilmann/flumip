import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../services/project_service.dart';
import '../generated/protocol.dart';

/// Endpoint for handling project-related operations.
class ProjectEndpoint extends Endpoint {
  get projectService => ProjectService();

  /// Creates a new project.
  ///
  /// \param session The current session.
  /// \param name The name of the project.
  /// \param options The options for the project.
  /// \param description An optional description of the project.
  /// \returns The created [Project] object.
  Future<Project> createProject(
      Session session, String name, ProjectOptions options,
      [String? description]) async {
    session.log("Creating project with name: $name", level: LogLevel.info);
    try {
      return projectService.createProject(session, name, options, description);
    } catch (e) {
      session.log("Error creating project with name: $name",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Deletes a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to delete.
  Future<void> deleteProject(Session session, int id) async {
    session.log("Deleting project with ID: $id", level: LogLevel.info);
    try {
      return projectService.deleteProject(session, id);
    } catch (e) {
      session.log("Error deleting project with ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves all projects.
  ///
  /// \param session The current session.
  /// \returns A list of [Project] objects.
  Future<List<Project>> getProjects(Session session) async {
    session.log("Retrieving all projects", level: LogLevel.info);
    try {
      return projectService.getProjects(session);
    } catch (e) {
      session.log("Error retrieving all projects",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves a project by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project to retrieve.
  /// \returns The retrieved [Project] object.
  Future<Project> getProject(Session session, int id) async {
    session.log("Retrieving project with ID: $id", level: LogLevel.info);
    try {
      return projectService.getProject(session, id);
    } catch (e) {
      session.log("Error retrieving project with ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Adds a gene to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to add.
  Future<void> addGeneToProject(Session session, int id, String gene) async {
    session.log("Adding gene to project with ID: $id", level: LogLevel.info);
    try {
      return projectService.addGeneToProject(session, id, gene);
    } catch (e) {
      session.log("Error adding gene to project with ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Removes a gene from a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param gene The gene to remove.
  Future<void> removeGeneFromProject(
      Session session, int id, String gene) async {
    session.log("Removing gene from project with ID: $id",
        level: LogLevel.info);
    try {
      return projectService.removeGeneFromProject(session, id, gene);
    } catch (e) {
      session.log("Error removing gene from project with ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Adds multiple genes to a project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \param genes The list of genes to add.
  Future<void> addGenesToProject(
      Session session, int id, List<String> genes) async {
    session.log("Adding genes to project with ID: $id", level: LogLevel.info);
    try {
      return projectService.addGenesToProject(session, id, genes);
    } catch (e) {
      session.log("Error adding genes to project with ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
