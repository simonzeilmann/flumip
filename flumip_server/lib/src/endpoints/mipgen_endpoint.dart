import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for handling MIP generation-related operations.
class MipgenEndpoint extends Endpoint {
  final mipgenService = MipgenService();

  /// Creates a BED file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  Future<void> createBedFile(Session session, int projectID) async {
    session.log("Creating BED file for project ID: $projectID",
        level: LogLevel.info);
    try {
      return mipgenService.createBedFile(session, projectID);
    } catch (e) {
      session.log("Error creating BED file for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Generates MIPs for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \param deleteExcessFiles Whether to delete excess files after generating MIPs.
  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    session.log("Generating MIPs for project ID: $projectID",
        level: LogLevel.info);
    try {
      return mipgenService.generateMips(session, projectID, deleteExcessFiles);
    } catch (e) {
      session.log("Error generating MIPs for project ID: $projectID",
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
