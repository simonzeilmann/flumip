import 'dart:convert';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/genome.dart';
import 'package:flumip_server/src/generated/project.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Service class for handling process-related operations.
/// How long a system utility that answers immediately is given before it is
/// treated as wedged. `ps`, `pgrep` and `kill` all return in milliseconds.
const quickToolTimeout = Duration(seconds: 10);

/// How far down a process tree [ProcessService.terminateProcess] will walk.
/// mipgen's own tree is two or three deep; this is headroom, not a target.
const _maxTreeDepth = 8;

/// How many descendants it will collect before giving up and killing those.
const _maxTreeSize = 200;

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
    var process =
        await sl<ProcessRunner>().run(
      "ps",
      ["-p", project.pid.toString()],
      // A liveness check that has not answered in ten seconds is not going
      // to; without a deadline it would hold the progress future call open.
      timeout: quickToolTimeout,
    );
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
    var process = await sl<ProcessRunner>()
        .run("ps", ["-p", genome.indexPID.toString()]);
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

    var process =
        await sl<ProcessRunner>().run(
      "pgrep",
      ["--list-full", processName],
      timeout: quickToolTimeout,
    );
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

  /// Kills [pid] **and everything it started**.
  ///
  /// ⚠️ `kill -9 <pid>` alone is not enough here, and the gap is expensive.
  /// mipgen spawns bwa and friends, and killing only mipgen leaves those
  /// children running — reparented to init, still pinned to every core, still
  /// writing into a project directory that is on its way to being deleted. On a
  /// design cancelled after a minute that is hours of CPU nobody is waiting for.
  ///
  /// Children are collected before anything is killed: once a parent dies its
  /// children are reparented, and `pgrep -P` can no longer find them from here.
  /// They are then killed leaves-first so that a parent cannot fork again while
  /// its descendants are being taken down.
  Future<void> terminateProcess(Session session, int pid) async {
    session.log("Terminating process tree at PID: $pid", level: LogLevel.info);

    final tree = await _descendants(session, pid);
    // Leaves first, parent last.
    for (final target in [...tree.reversed, pid]) {
      final result = await sl<ProcessRunner>().run(
        "kill",
        ["-9", target.toString()],
        timeout: quickToolTimeout,
      );
      // Exit code 1 is "no such process", which is the ordinary outcome for a
      // child that finished between the walk and the kill.
      if (result.exitCode > 1) {
        session.log(
          "Error terminating process with PID: $target",
          level: LogLevel.error,
        );
      }
    }

    if (tree.isNotEmpty) {
      session.log(
        "Terminated ${tree.length} child process(es) of PID $pid",
        level: LogLevel.info,
      );
    }
  }

  /// Every descendant of [pid], breadth-first, parents before children.
  ///
  /// Bounded twice over: [_maxTreeDepth] on how deep it will walk and
  /// [_maxTreeSize] on how many it will collect. A process that forks while
  /// being walked would otherwise keep this loop going indefinitely, inside a
  /// delete request somebody is waiting on.
  Future<List<int>> _descendants(Session session, int pid) async {
    final found = <int>[];
    var frontier = [pid];

    for (var depth = 0; depth < _maxTreeDepth && frontier.isNotEmpty; depth++) {
      final next = <int>[];
      for (final parent in frontier) {
        if (found.length >= _maxTreeSize) break;
        final result = await sl<ProcessRunner>().run(
          "pgrep",
          ["-P", parent.toString()],
          timeout: quickToolTimeout,
        );
        // 1 means "no children", which is the common case and not an error.
        if (result.exitCode != 0) continue;
        for (final line in const LineSplitter().convert(result.stdout)) {
          final child = int.tryParse(line.trim());
          if (child == null || child <= 1) continue;
          if (found.contains(child)) continue;
          found.add(child);
          next.add(child);
        }
      }
      frontier = next;
    }

    if (found.length >= _maxTreeSize) {
      session.log(
        "Process tree at PID $pid hit the $_maxTreeSize-process cap; "
        "killing what was found.",
        level: LogLevel.warning,
      );
    }
    return found;
  }
}
