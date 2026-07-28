import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/project_options.dart';
import '../services/options_service.dart';

/// Endpoint for handling project options-related operations.
class OptionsEndpoint extends Endpoint {
  OptionsService get optionsService => OptionsService();

  /// Creates project options.
  ///
  /// \param session The current session.
  /// \returns The created [ProjectOptions] object.
  Future<ProjectOptions> createProjectOptions(Session session) async {
    session.log("Creating project options", level: LogLevel.info);
    try {
      return optionsService.createProjectOptions(session);
    } catch (e) {
      session.log("Error creating project options - $e", level: LogLevel.error);
      rethrow;
    }
  }

  /// Inserts project options.
  ///
  /// \param session The current session.
  /// \param options The [ProjectOptions] object to insert.
  /// \returns The inserted [ProjectOptions] object.
  Future<ProjectOptions> insertProjectOptions(
      Session session, ProjectOptions options) async {
    session.log("Inserting project options", level: LogLevel.info);
    try {
      return optionsService.insertProjectOptions(session, options);
    } catch (e) {
      session.log("Error inserting project options - $e",
          level: LogLevel.error);
      rethrow;
    }
  }

  /// Retrieves project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to retrieve.
  /// \returns The retrieved [ProjectOptions] object.
  Future<ProjectOptions> getProjectOptions(Session session, int id) async {
    session.log("Retrieving project options for ID: $id", level: LogLevel.info);
    try {
      return optionsService.getProjectOptions(session, id);
    } catch (e) {
      session.log("Error retrieving project options for ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Updates project options.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to update.
  /// \param options The [ProjectOptions] object to update.
  Future<void> updateProjectOptions(
      Session session, int id, ProjectOptions options) async {
    session.log("Updating project options for ID: $id", level: LogLevel.info);
    try {
      return optionsService.updateProjectOptions(session, id, options);
    } catch (e) {
      session.log("Error updating project options for ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Deletes project options by ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the project options to delete.
  Future<void> deleteProjectOptions(Session session, int id) async {
    session.log("Deleting project options for ID: $id", level: LogLevel.info);
    try {
      return optionsService.deleteProjectOptions(session, id);
    } catch (e) {
      session.log("Error deleting project options for ID: $id",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
