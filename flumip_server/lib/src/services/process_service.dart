import 'dart:io';

import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/server.dart';

import '../generated/project.dart';

class ProcessService {
  ProcessService();

  final projectService = ProjectService();

  Future<bool> checkIfProcessIsRunning(
      Session session, Project projectModel) async {
    var project = await projectService.getProject(session, projectModel.id!);
    if (project.id == null) {
      throw ArgumentError('Project id does not exist');
    }
    var process = await Process.run("ps", ["-p", project.pid.toString()]);
    if (process.exitCode > 1) {
      //TODO: error handling
      throw ();
    } else {
      var lines = process.stdout.split("\n");
      if (lines.Count > 1) {
        return true;
      }
      return false;
    }
  }

  Future<int> getProcessPID(Session session, String processName) async {
    int mipgenPID = 0;

    var process = await Process.run("pgrep", ["--list-full", "mipgen"]);
    if (process.exitCode == 1) {
      session.log("Mipgen is not running");
      return mipgenPID;
    }
    if (process.exitCode > 1) {
      //TODO: error handling
      throw ();
    } else {
      var lines = process.stdout.split("\n");
      for (var line in lines) {
        if (line.contains("-project_name $processName")) {
          mipgenPID = int.parse(line.split(" ")[0]);
          break;
        }
      }
    }

    return mipgenPID;
  }
}