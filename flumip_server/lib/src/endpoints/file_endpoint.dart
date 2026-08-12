import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import 'package:flumip_server/service_locator.dart';

import '../generated/protocol.dart';
import '../services/file_service.dart';
import '../services/project_service.dart';
import '../web/routes/ucsc_track.dart';
import 'flumip_endpoint.dart';

/// Endpoint for handling file-related operations.
class FileEndpoint extends FlumipEndpoint {
  final fileService = FileService();

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  Future<void> deleteByProducts(Session session, int projectID) async {
    session.log(
      "Deleting byproducts for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return fileService.deleteByproducts(session, projectID);
    } catch (e) {
      session.log(
        "Error deleting byproducts for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    session.log(
      "Showing SNP MIPs result for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return fileService.showSnpMipsResult(session, projectID);
    } catch (e) {
      session.log(
        "Error showing SNP MIPs result for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  Future<List<String>> showMipsResult(Session session, int projectID) async {
    session.log(
      "Showing MIPs result for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return fileService.showMipsResult(session, projectID);
    } catch (e) {
      session.log(
        "Error showing MIPs result for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    session.log(
      "Showing MIPs progress for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return fileService.showMipsProgress(session, projectID);
    } catch (e) {
      session.log(
        "Error showing MIPs progress for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  Future<List<String>> showUSCSTrack(Session session, int projectID) async {
    session.log(
      "Showing USCSTrack for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return fileService.showUSCSTrack(session, projectID);
    } catch (e) {
      session.log(
        "Error showing USCSTrack for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// The token for this project's public UCSC track URL.
  ///
  /// The app builds `<siteUrl>/ucsc_track/<token>` from this and hands that URL
  /// to genome.ucsc.edu. It used to build the URL from the project id, which made
  /// every track world-readable and enumerable — see [UCSCTrackRoute] for why the
  /// route itself cannot require a session.
  ///
  /// This is the access check that the public route cannot do: the token is only
  /// ever released to somebody allowed to open the project.
  Future<String> getUcscTrackToken(Session session, int projectID) async {
    session.log(
      "UCSC track token requested for project ID: $projectID",
      level: LogLevel.info,
    );
    try {
      await requireProject(session, projectID);
      return sl<ProjectService>().ensureTrackToken(session, projectID);
    } catch (e) {
      session.log(
        "Error getting UCSC track token for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Lists a project's files, so the app can offer them for download.
  ///
  /// Names and sizes only — the bytes come from the `/download/...` web route,
  /// which streams them. Routing a multi-gigabyte file through a serialised
  /// endpoint response would mean holding it in memory on both sides.
  ///
  /// Empty for a project whose generation never ran; that is not an error.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  Future<List<ProjectFileDto>> listProjectFiles(
    Session session,
    int projectID,
  ) async {
    try {
      await requireProject(session, projectID);
      final files = await fileService.listProjectFiles(session, projectID);
      return files
          .map((f) => ProjectFileDto(name: f.name, sizeBytes: f.sizeBytes))
          .toList();
    } catch (e) {
      session.log(
        "Error listing files for project ID: $projectID",
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }
}
