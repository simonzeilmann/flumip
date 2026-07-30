import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../services/file_service.dart';
import 'flumip_endpoint.dart';

/// Endpoint for handling file-related operations.
class FileEndpoint extends FlumipEndpoint {
  final fileService = FileService();

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  Future<void> deleteByProducts(Session session, int projectID) async {
    session.log("Deleting byproducts for project ID: $projectID",
        level: LogLevel.info);
    try {
      await requireProject(session, projectID);
      return fileService.deleteByproducts(session, projectID);
    } catch (e) {
      session.log("Error deleting byproducts for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    session.log("Showing SNP MIPs result for project ID: $projectID",
        level: LogLevel.info);
    try {
      await requireProject(session, projectID);
      return fileService.showSnpMipsResult(session, projectID);
    } catch (e) {
      session.log("Error showing SNP MIPs result for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  Future<List<String>> showMipsResult(Session session, int projectID) async {
    session.log("Showing MIPs result for project ID: $projectID",
        level: LogLevel.info);
    try {
      await requireProject(session, projectID);
      return fileService.showMipsResult(session, projectID);
    } catch (e) {
      session.log("Error showing MIPs result for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    session.log("Showing MIPs progress for project ID: $projectID",
        level: LogLevel.info);
    try {
      await requireProject(session, projectID);
      return fileService.showMipsProgress(session, projectID);
    } catch (e) {
      session.log("Error showing MIPs progress for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<List<String>> showUSCSTrack(Session session, int projectID) async {
    session.log("Showing USCSTrack for project ID: $projectID",
        level: LogLevel.info);
    try {
      await requireProject(session, projectID);
      return fileService.showUSCSTrack(session, projectID);
    } catch (e) {
      session.log("Error showing USCSTrack for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
