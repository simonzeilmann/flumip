import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/genome.dart';
import 'package:flumip_server/src/generated/project.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Service class for handling process-related operations.
class ProcessService {
  ProcessService();

  /// Checks if the process is running for the specified project.
  ///
  /// Throws an [ArgumentError] if the project ID does not exist.
  ///
  /// \param session The current session.
  /// \param projectModel The project model to check.
  /// \returns A boolean indicating whether the process is running.
  Future<bool> checkIfMipgenProcessIsRunning(
    Session session,
    Project projectModel,
  ) async {
    ProjectService projectService = sl<ProjectService>();

    session.log(
      "Checking if process is running for project ID: ${projectModel.id}",
      level: LogLevel.info,
    );
    var project = await projectService.getProject(session, projectModel.id!);
    if (project.id == null) {
      session.log(
        "Project ID does not exist: ${projectModel.id}",
        level: LogLevel.error,
      );
      throw ArgumentError('Project id does not exist');
    }
    var process = await sl<ProcessRunner>().run("ps", [
      "-p",
      project.pid.toString(),
    ]);
    if (process.exitCode > 1) {
      session.log(
        "Error running process check for project ID: ${projectModel.id}",
        level: LogLevel.error,
      );
      throw Exception(
        'Failed to check mipgen process for project ${projectModel.id}: '
        '`ps` exited with code ${process.exitCode}: ${process.stderr}',
      );
    } else {
      var lines = process.stdout.split("\n");
      if (lines.length > 1) {
        if (lines[1].contains("mipgen")) {
          session.log(
            "Process is running for project ID: ${projectModel.id}",
            level: LogLevel.info,
          );
          return true;
        }
      }
      session.log(
        "Process is not running for project ID: ${projectModel.id}",
        level: LogLevel.info,
      );
      return false;
    }
  }

  /// Checks if the BWA index process is running for the specified gene.
  ///
  /// Throws an [ArgumentError] if the gene ID does not exist.
  ///
  /// \param session The current session.
  /// \param geneModel The gene model to check.
  /// \returns A boolean indicating whether the BWA process is running.
  Future<bool> checkIfIndexProcessIsRunning(
    Session session,
    Genome genomeModel,
  ) async {
    GenomeService genomeService = sl<GenomeService>();

    session.log(
      "Checking if index process is running for gene ID: ${genomeModel.id}",
      level: LogLevel.info,
    );
    var genome = await genomeService.getGenome(session, genomeModel.id!);
    if (genome.id == null) {
      session.log(
        "Gene ID does not exist: ${genomeModel.id}",
        level: LogLevel.error,
      );
      throw ArgumentError('Gene id does not exist');
    }
    var process = await sl<ProcessRunner>().run("ps", [
      "-p",
      genome.indexPID.toString(),
    ]);
    if (process.exitCode > 1) {
      session.log(
        "Error running process check for gene ID: ${genomeModel.id}",
        level: LogLevel.error,
      );
      throw Exception(
        'Failed to check index process for genome ${genomeModel.id}: '
        '`ps` exited with code ${process.exitCode}: ${process.stderr}',
      );
    } else {
      var lines = process.stdout.split("\n");
      if (lines.length > 1) {
        if (lines[1].contains(genome.indexPID.toString()) &&
            lines[1].contains("bwa")) {
          session.log(
            "Process is running for gene ID: ${genomeModel.id}",
            level: LogLevel.info,
          );
          return true;
        }
      }
      session.log(
        "Process is not running for gene ID: ${genomeModel.id}",
        level: LogLevel.info,
      );
      return false;
    }
  }

  /// Gets the process PID for the specified process name.
  ///
  /// \param session The current session.
  /// \param processName The name of the process to get the PID for.
  /// \param processSearch The search string to identify the specific process.
  /// \returns The PID of the process.
  Future<int> getProcessPID(
    Session session,
    String processName,
    String processSearch,
  ) async {
    session.log(
      "Getting process PID for process name: $processName",
      level: LogLevel.info,
    );
    int processPID = 0;

    var process = await sl<ProcessRunner>().run("pgrep", [
      "--list-full",
      processName,
    ]);
    if (process.exitCode == 1) {
      session.log("Process is not running", level: LogLevel.info);
      return processPID;
    }
    if (process.exitCode > 1) {
      session.log(
        "Error running pgrep for process name: $processName",
        level: LogLevel.error,
      );
      throw Exception(
        'Failed to run pgrep for process "$processName": '
        'exited with code ${process.exitCode}: ${process.stderr}',
      );
    } else {
      var lines = process.stdout.split("\n");
      for (var line in lines) {
        if (line.contains(processSearch)) {
          processPID = int.parse(line.split(" ")[0]);
          session.log(
            "Found PID $processPID for process name: $processName",
            level: LogLevel.info,
          );
          break;
        }
      }
    }

    return processPID;
  }

  Future<void> terminateProcess(Session session, int pid) async {
    session.log("Terminating process with PID: $pid", level: LogLevel.info);
    var process = await sl<ProcessRunner>().run("kill", ["-9", pid.toString()]);
    if (process.exitCode > 1) {
      session.log(
        "Error terminating process with PID: $pid",
        level: LogLevel.error,
      );
    }
  }
}
