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
  /// ⚠️ A plain [ArgumentError] on purpose, unlike the services a request can
  /// reach. Everything here runs from a future call — nothing is waiting on the
  /// other end of a connection — so these land in the server log, which is where
  /// a diagnostic with a `ps` exit code belongs. Turning them into
  /// `ArgumentException` would dress up an internal fault as something a user
  /// could act on.
  ///
  /// ⚠️ "Running" means *this project's* mipgen is alive under the stored pid,
  /// not merely that some mipgen is. It used to accept any process whose `ps`
  /// line said "mipgen", and a pid outlives the process it was recorded for:
  /// after a restart — every restart, in a container, where pids are handed
  /// out from 1 again — the stored pid can belong to another project's run,
  /// and this project then reads as running until that one ends. See
  /// [isMipgenRunOf].
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
    final process = await _describe(
      project.pid,
      'mipgen process for project ${projectModel.id}',
    );
    if (process != null && isMipgenRunOf(process, project)) {
      session.log(
        "Process is running for project ID: ${projectModel.id}",
        level: LogLevel.info,
      );
      return true;
    }
    if (process != null) {
      session.log(
        "PID ${project.pid} of project ${projectModel.id} now belongs to "
        "another process (${process.name}); treating the run as finished.",
        level: LogLevel.warning,
      );
    }
    session.log(
      "Process is not running for project ID: ${projectModel.id}",
      level: LogLevel.info,
    );
    return false;
  }

  /// Checks if the BWA index process is running for the specified gene.
  ///
  /// Throws an [ArgumentError] if the gene ID does not exist.
  ///
  /// Same identity rule as [checkIfMipgenProcessIsRunning]: the stored pid only
  /// counts while it is still `bwa index` on this genome's FASTA ([isIndexRunOf]).
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
    final process = await _describe(
      genome.indexPID,
      'index process for genome ${genomeModel.id}',
    );
    if (process != null && isIndexRunOf(process, genome)) {
      session.log(
        "Process is running for gene ID: ${genomeModel.id}",
        level: LogLevel.info,
      );
      return true;
    }
    if (process != null) {
      session.log(
        "Index PID ${genome.indexPID} of genome ${genomeModel.id} now belongs "
        "to another process (${process.name}); treating the index as finished.",
        level: LogLevel.warning,
      );
    }
    session.log(
      "Process is not running for gene ID: ${genomeModel.id}",
      level: LogLevel.info,
    );
    return false;
  }

  /// Stops [project]'s mipgen run and everything it started — but only if the
  /// stored pid is still that run. Returns whether anything was killed.
  ///
  /// ⚠️ The check is the point. `kill -9` on a stored pid that has since been
  /// handed to another process takes down whatever that is now: another
  /// project's design, or after a container restart quite possibly a process of
  /// the server's own. A pid that is no longer this run is logged and left
  /// alone; the run it named is already gone.
  Future<bool> terminateMipgenRun(Session session, Project project) async {
    final process = await _describe(
      project.pid,
      'mipgen process for project ${project.id}',
    );
    if (process == null || !isMipgenRunOf(process, project)) {
      session.log(
        "Not terminating PID ${project.pid} for project ${project.id}: it is "
        "no longer this project's mipgen run.",
        level: LogLevel.info,
      );
      return false;
    }
    await terminateProcess(session, project.pid!);
    return true;
  }

  /// What `ps` says is running under [pid]: its executable name and full
  /// command line. Null when there is no such process, or no pid to look up.
  ///
  /// `comm` and `args` rather than the default columns, because the default
  /// `CMD` is only the executable name — enough to say "a mipgen", never enough
  /// to say whose. Both headers are suppressed (`=`), so the output is the one
  /// line or nothing.
  ///
  /// Throws when `ps` itself fails (exit code above 1); exit code 1 is "no
  /// such process", the ordinary answer for a run that has finished.
  Future<({String name, String commandLine})?> _describe(
    int? pid,
    String what,
  ) async {
    // `ps -p 0` would only exit 1 ("process ID out of range"), which is the
    // same answer, so it is not worth a process.
    if (pid == null || pid <= 0) return null;
    final result = await sl<ProcessRunner>().run(
      "ps",
      ["-o", "comm=", "-o", "args=", "-p", pid.toString()],
      // A liveness check that has not answered in ten seconds is not going
      // to; without a deadline it would hold the progress future call open.
      timeout: quickToolTimeout,
    );
    if (result.exitCode > 1) {
      throw Exception(
        'Failed to check $what: '
        '`ps` exited with code ${result.exitCode}: ${result.stderr}',
      );
    }
    final line = result.stdout.toString().trim();
    if (result.exitCode == 1 || line.isEmpty) return null;
    final gap = line.indexOf(RegExp(r'\s'));
    if (gap < 0) return (name: line, commandLine: '');
    return (
      name: line.substring(0, gap),
      commandLine: line.substring(gap).trim(),
    );
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
    ], timeout: quickToolTimeout);
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
      final result = await sl<ProcessRunner>().run("kill", [
        "-9",
        target.toString(),
      ], timeout: quickToolTimeout);
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
        final result = await sl<ProcessRunner>().run("pgrep", [
          "-P",
          parent.toString(),
        ], timeout: quickToolTimeout);
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

/// Whether [process] is [project]'s own mipgen run.
///
/// Matched on the project's folder, which mipgen is given as
/// `-regions_to_scan <projectDir>/<folderName>/genes.bed`. The folder name is a
/// UUID, so it names exactly one project — unlike `-project_name`, which is the
/// user's free-text name: two projects may share it, and one may be a prefix of
/// another ("BRCA" and "BRCA panel").
///
/// A zombie reads as `[mipgen] <defunct>` in `args` and so does not match,
/// which is right: it has finished, it just has not been reaped.
bool isMipgenRunOf(
  ({String name, String commandLine}) process,
  Project project,
) {
  final folder = project.folderName;
  if (folder == null || folder.isEmpty) return false;
  return process.name == 'mipgen' &&
      process.commandLine.contains(mipgenRunMarker(folder));
}

/// The part of a mipgen command line that identifies whose run it is. Shared
/// with the `pgrep` lookup in `MipgenService` that records the pid in the
/// first place, so the two cannot drift apart.
String mipgenRunMarker(String folderName) => '/$folderName/genes.bed';

/// Whether [process] is `bwa index` on [genome]'s FASTA.
bool isIndexRunOf(({String name, String commandLine}) process, Genome genome) {
  final fasta = genome.fastaPath;
  if (fasta == null || fasta.isEmpty) return false;
  return process.name == 'bwa' && process.commandLine.endsWith(' index $fasta');
}
