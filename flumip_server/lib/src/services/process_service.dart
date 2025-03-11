import 'dart:io';

import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/project.dart';

/// Service class for handling process-related operations.
class ProcessService {
  ProcessService();

  final projectService = ProjectService();

  /// Checks if the process is running for the specified project.
  ///
  /// Throws an [ArgumentError] if the project ID does not exist.
  ///
  /// \param session The current session.
  /// \param projectModel The project model to check.
  /// \returns A boolean indicating whether the process is running.
  Future<bool> checkIfProcessIsRunning(
      Session session, Project projectModel) async {
    session.log(
        "Checking if process is running for project ID: ${projectModel.id}",
        level: LogLevel.info);
    var project = await projectService.getProject(session, projectModel.id!);
    if (project.id == null) {
      session.log("Project ID does not exist: ${projectModel.id}",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }
    var process = await Process.run("ps", ["-p", project.pid.toString()]);
    if (process.exitCode > 1) {
      session.log(
          "Error running process check for project ID: ${projectModel.id}",
          level: LogLevel.error);
      //TODO: error handling
      throw ();
    } else {
      var lines = process.stdout.split("\n");
      if (lines.length > 1) {
        if(lines[1].contains("mipgen")) {
          session.log("Process is running for project ID: ${projectModel.id}",
              level: LogLevel.info);
          return true;
        }
        else {
          session.log("Process is not running for project ID: ${projectModel.id}",
              level: LogLevel.info);
          return false;
        }
      }
      session.log("Process is not running for project ID: ${projectModel.id}",
          level: LogLevel.info);
      return false;
    }
  }

  /// Gets the process PID for the specified process name.
  ///
  /// \param session The current session.
  /// \param processName The name of the process to get the PID for.
  /// \returns The PID of the process.
  Future<int> getProcessPID(Session session, String processName) async {
    session.log("Getting process PID for process name: $processName",
        level: LogLevel.info);
    int mipgenPID = 0;

    var process = await Process.run("pgrep", ["--list-full", "mipgen"]);
    if (process.exitCode == 1) {
      session.log("Mipgen is not running", level: LogLevel.info);
      return mipgenPID;
    }
    if (process.exitCode > 1) {
      session.log("Error running pgrep for process name: $processName",
          level: LogLevel.error);
      //TODO: error handling
      throw ();
    } else {
      var lines = process.stdout.split("\n");
      for (var line in lines) {
        if (line.contains("-project_name $processName")) {
          mipgenPID = int.parse(line.split(" ")[0]);
          session.log("Found PID $mipgenPID for process name: $processName",
              level: LogLevel.info);
          break;
        }
      }
    }

    return mipgenPID;
  }
}
