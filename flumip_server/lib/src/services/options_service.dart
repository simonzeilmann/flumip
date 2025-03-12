import 'package:flumip_server/src/generated/project_options.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// A service class for handling project options.
class OptionsService {
  OptionsService();


  /// Creates a new project options entry.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  Future<ProjectOptions> createProjectOptions(Session session) async {
    var projectOptions = ProjectOptions();

    return projectOptions;
  }

  /// Inserts a new project options entry in the database.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  Future<ProjectOptions> insertProjectOptions(
      Session session, ProjectOptions options) async {
    var projectOptions = await ProjectOptions.db.insertRow(session, options);
    return projectOptions;
  }

  /// Retrieves a project options entry by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  /// \throws [FileNotFoundException] if the project options are not found.
  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    return projectOptions;
  }

  /// Updates an existing project options entry in the database.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to update.
  /// \param options The updated [ProjectOptions] object.
  /// \throws [FileNotFoundException] if the project options are not found.
  Future<void> updateProjectOptions(
      Session session, int id, ProjectOptions options) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    await ProjectOptions.db.updateRow(session, options);
  }

  /// Deletes a project options entry from the database.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to delete.
  /// \throws [FileNotFoundException] if the project options are not found.
  Future<void> deleteProjectOptions(Session session, int id) async {
    var projectOptions = await ProjectOptions.db.findById(session, id);
    if (projectOptions == null) {
      throw FileNotFoundException(message: 'Project options not found');
    }
    await ProjectOptions.db.deleteRow(session, projectOptions);
  }
}
