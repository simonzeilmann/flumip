import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/future_calls.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mail_service.dart';
import 'package:flumip_server/src/services/options_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Service class for handling MIP generation related operations.
/// Where mipgen's own output is kept, inside the project directory.
///
/// A normal project file, so it is listed and downloadable alongside the
/// results — which is the right place for it: when a run fails, this is the file
/// somebody needs to send you.
const mipgenLogName = 'mipgen.log';

/// How long a helper tool gets before it is treated as wedged.
///
/// The exon-extraction script and the UCSC track generator both read a gene
/// list and write a file; minutes, not hours.
const helperToolTimeout = Duration(minutes: 15);

class MipgenService {
  /// Constructor to initialize file paths for reference gene, fasta file, and SNP file.
  MipgenService();

  /// Creates a BED file for the specified project.
  ///
  /// Throws an [ArgumentError] if the project ID does not exist or if no genes are found in the project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project for which to create the BED file.
  Future<void> createBedFile(Session session, int projectID) async {
    ProjectService projectService = sl<ProjectService>();
    GenomeService genomeService = sl<GenomeService>();
    SettingsService settingsService = sl<SettingsService>();
    FileService fileService = sl<FileService>();

    session.log(
      "Starting createBedFile for project ID: $projectID",
      level: LogLevel.info,
    );
    var project = await projectService.getProject(session, projectID);
    if (project.id == null) {
      session.log(
        "Project ID does not exist: $projectID",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'Project id does not exist');
    }
    if (project.genome == null) {
      session.log(
        "No genome found in project ID: $projectID",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'No genome found in project');
    }
    var genome = await genomeService.getGenome(session, project.genome!);
    if (genome.refPath == null || genome.refPath!.isEmpty) {
      session.log(
        "No reference path found in genome ID: ${project.genome}",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'No reference path found in genome');
    }
    if (project.genes == null || project.genes!.isEmpty) {
      session.log(
        "No genes found in project ID: $projectID",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'No genes found in project');
    }

    var settings = await settingsService.getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    String bedFile = "${settings.projectDir}/${project.folderName}/genes.bed";
    if (await File(geneFile).exists()) {
      session.log(
        "Gene file exists, deleting: $geneFile",
        level: LogLevel.warning,
      );
      await fileService.deleteGeneFile(session, projectID);
    }
    session.log("Creating gene file: $geneFile", level: LogLevel.info);
    await fileService.createGeneFile(session, projectID, project.genes!);
    List<String> arg = [];
    arg.add(geneFile);
    arg.add(genome.refPath!);

    session.log(
      "Running exon extract script with arguments: $arg",
      level: LogLevel.info,
    );
    var process = await sl<ProcessRunner>().run(
      settings.exonExtractScript,
      arg,
      // Called straight from a request: without a deadline a wedged script
      // holds the connection open until something else gives up.
      timeout: helperToolTimeout,
    );

    if (process.exitCode != 0 || process.stdout == "") {
      session.log(
        "Failed to extract genes for project ID: $projectID",
        level: LogLevel.error,
      );
      throw BedCreationException(
        message: 'Error: The supplied genes cannot be found',
      );
    }

    session.log("Writing BED file: $bedFile", level: LogLevel.info);
    await fileService.writeStringToFile(session, bedFile, process.stdout);

    project.bedFileCreated = true;
    await projectService.updateProject(session, project);
    session.log(
      "BED file created successfully for project ID: $projectID",
      level: LogLevel.info,
    );
  }

  /// Generates MIPs for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project for which to generate MIPs.
  /// \param deleteExcessFiles Whether to delete intermediate files after MIP generation.
  Future<void> generateMips(
    Session session,
    int projectID,
    bool deleteExcessFiles,
  ) async {
    GenomeService genomeService = sl<GenomeService>();
    ProjectService projectService = sl<ProjectService>();
    SettingsService settingsService = sl<SettingsService>();
    OptionsService optionsService = sl<OptionsService>();
    ProcessService processService = sl<ProcessService>();

    session.log(
      "Starting generateMips for project ID: $projectID",
      level: LogLevel.info,
    );
    var project = await projectService.getProject(session, projectID);
    var options = await optionsService.getProjectOptions(
      session,
      project.options,
    );

    var settings = await settingsService.getSettings(session);

    // Checked rather than assumed, the way createBedFile already does it. A
    // project with no genome otherwise died on the null-check below and reached
    // the user as a 500 instead of a sentence.
    if (project.genome == null) {
      session.log(
        "No genome found in project ID: $projectID",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'No genome found in project');
    }

    var genome = await genomeService.getGenome(session, project.genome!);
    if (genome.fastaPath == null || genome.fastaPath!.isEmpty) {
      session.log(
        "No fasta path found in genome ID: ${project.genome}",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(message: 'No fasta path found in genome');
    }
    Snp? snp;
    if (project.snp != null) {
      snp = await genomeService.getSnp(session, project.snp!);

      // ⚠️ Loud rather than quiet, and this is a change in behaviour. The old
      // code simply left `-snp_file` off the command line when the paths were
      // empty, so a project whose SNP had gone bad still ran — and produced a
      // perfectly plausible set of MIPs designed without the masking the user
      // asked for. Nothing about the result would have said so. Now that an SNP
      // can fail to import or be deleted out from under a project, that failure
      // mode is reachable in normal use, and a refusal somebody has to read is
      // the only honest answer.
      if (snp.status != SnpImportStatus.ready ||
          snp.vcfPath.isEmpty ||
          snp.tbiPath.isEmpty) {
        session.log(
          "Refusing to run project ${project.id}: SNP ${snp.id} is "
          "${snp.status.name} and cannot be used.",
          level: LogLevel.error,
        );
        throw ArgumentException(
          message:
              'The SNP set "${snp.name}" is not usable '
              '(${snp.status.name}). Pick another one, or none, and try again.',
        );
      }
    }

    List<String> arg = [
      "-regions_to_scan",
      "${settings.projectDir}/${project.folderName}/genes.bed",
      "-project_name",
      project.name,
      "-bwa_genome_index",
      genome.fastaPath!,
      // Only the VCF goes on the command line; mipgen finds the tabix index
      // beside it by convention. The guard above has already established that
      // both are present.
      if (snp != null) ...["-snp_file", snp.vcfPath],
      "-min_capture_size",
      options.minCaptureSize.toString(),
      "-max_capture_size",
      options.maxCaptureSize.toString(),
      // Nullable on the model, and a null used to take the whole run down here.
      // The test seed helper carries a comment about working around it, which is
      // a fair sign it was a trap rather than an invariant.
      if (options.armLengths?.isNotEmpty ?? false) ...[
        "-arm_lengths",
        options.armLengths!,
      ],
      "-arm_length_sums",
      options.armLengthSums.toString(),
      "-ext_min_length",
      options.extMinLength.toString(),
      "-lig_min_length",
      options.ligMinLength.toString(),
      "-tag_sizes",
      options.tagSizes.toString(),
      "-masked_arm_threshold",
      options.maskedArmThreshold.toString(),
      "-target_arm_copy",
      options.targetArmCopy.toString(),
      "-max_arm_copy_product",
      options.maxArmCopyProduct.toString(),
      "-trf",
      options.trf == true ? "trf" : "off",
      if (options.genomeDir != null) ...["-genome_dir", options.genomeDir!],
      "-feature_flank",
      options.featureFlank.toString(),
      "-capture_increment",
      options.captureIncrement.toString(),
      "-logistic_heuristic",
      options.logisticHeuristic == true ? "on" : "off",
      "-max_mip_overlap",
      options.maxMipOverlap.toString(),
      "-starting_mip_overlap",
      options.startingMipOverlap.toString(),
      "-check_copy_number",
      options.checkCopyNumber == true ? "on" : "off",
      "-seal_both_strands",
      options.sealBothStrands == true ? "on" : "off",
      "-half_seal_both_strands",
      options.halfSealBothStrands == true ? "on" : "off",
      "-double_tile_strand_unaware",
      options.doubleTileStrandUnaware == true ? "on" : "off",
      "-double_tile_strands_separately",
      options.doubleTileStrandsSeparately == true ? "on" : "off",
      "-score_method",
      options.scoreMethod.name,
      "-logistic_optimal_score",
      options.logisticOptimalScore.toString(),
      "-svr_optimal_score",
      options.svrOptimalScore.toString(),
      "-logistic_priority_score",
      options.logisticPriorityScore.toString(),
      "-svr_priority_score",
      options.svrPriorityScore.toString(),
      "-silent_mode",
      options.silentMode == true ? "on" : "off",
      "-bwa_threads",
      options.bwaThreads.toString(),
    ];

    session.log(
      "Starting MIP generation process with arguments: $arg",
      level: LogLevel.info,
    );
    final projectDir = "${settings.projectDir}/${project.folderName}";
    await sl<ProcessRunner>().start(
      settings.mipgenExecutable,
      arg,
      workingDirectory: projectDir,
      runInShell: true,
      // ⚠️ Without this, mipgen's own explanation of what went wrong goes into a
      // pipe nobody reads, and every failure reaches the user as the single
      // string "MIP generation failed". It lands in the project directory, so it
      // is listed and downloadable like any other result file.
      outputPath: "$projectDir/$mipgenLogName",
    );
    project.started = DateTime.now();
    project.active = true;
    var mipgenPID = await processService.getProcessPID(
      session,
      "mipgen",
      "-project_name ${project.name}",
    );
    project.pid = mipgenPID;
    project.cleanup = deleteExcessFiles;
    await projectService.updateProject(session, project);
    session.log(
      "MIP generation started with PID: $mipgenPID for project ID: $projectID",
      level: LogLevel.info,
    );

    await scheduleMipgenProgressCheck(
      session,
      project,
      delay: const Duration(seconds: 15),
    );
  }

  /// The last thing mipgen said before it stopped, or an empty string.
  ///
  /// Only the tail is used: mipgen echoes its whole configuration on startup,
  /// which is a screenful of noise, and the useful part is always at the end.
  /// Blank lines and its own progress chatter are dropped so the message is the
  /// error rather than the last `[mipgen] feature #N`.
  Future<String> _lastWordsOf(Settings settings, Project project) async {
    try {
      final log = File(
        "${settings.projectDir}/${project.folderName}/$mipgenLogName",
      );
      if (!await log.exists()) return '';

      final lines = (await log.readAsLines())
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('[mipgen] feature #'))
          .toList();
      if (lines.isEmpty) return '';

      final tail = lines.length > 3 ? lines.sublist(lines.length - 3) : lines;
      final joined = tail.join(' — ');
      return joined.length > 400 ? '${joined.substring(0, 400)}…' : joined;
    } catch (_) {
      // A diagnosis is a nicety; failing to read it must not stop the project
      // being marked finished.
      return '';
    }
  }

  /// Schedules a delayed future call that polls the MIP generation progress for
  /// [project]. Used both to start polling and to reschedule the next check.
  Future<void> scheduleMipgenProgressCheck(
    Session session,
    Project project, {
    Duration delay = const Duration(seconds: 10),
  }) async {
    await session.serverpod.futureCalls
        .callWithDelay(delay)
        .checkMipgenProgress
        .run(project);
  }

  /// Marks the MIP generation process as finished for the specified project.
  ///
  /// \param session The current session.
  /// \param projectModel The project model to update.
  Future<void> mipgenIsFinished(Session session, Project projectModel) async {
    ProjectService projectService = sl<ProjectService>();
    SettingsService settingsService = sl<SettingsService>();
    FileService fileService = sl<FileService>();

    final settings = await settingsService.getSettings(session);
    session.log(
      "Finishing MIP generation for project ID: ${projectModel.id}",
      level: LogLevel.info,
    );
    var project = await projectService.getProject(session, projectModel.id!);
    if (project.id == null) {
      session.log(
        "Project ID does not exist: ${projectModel.id}",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'Project id does not exist');
    }

    if (project.cleanup) {
      session.log(
        "Deleting byproducts for project ID: ${project.id}",
        level: LogLevel.info,
      );
      await fileService.deleteByproducts(session, project.id!);
    }

    // Finalize the project. Any failure while reading progress, sizing the
    // output, or generating the UCSC track must not leave the project stuck in
    // the active state, so the terminal bookkeeping (clearing the pid, marking
    // the project inactive, and persisting it) always runs in `finally`.
    try {
      var progress = await fileService.showMipsProgress(session, project.id!);
      if (progress.isEmpty) {
        session.log(
          "MIP generation failed for project ID: ${project.id}",
          level: LogLevel.warning,
        );
        // Say *why*, if mipgen said anything. Its last words are almost always
        // the actual cause — a missing index, an unreadable file, a region that
        // is not in the genome — and they used to be thrown away.
        final reason = await _lastWordsOf(settings, project);
        project.error = reason.isEmpty
            ? "MIP generation failed, and mipgen said nothing about why. "
                  "Check $mipgenLogName in this project's files."
            : "MIP generation failed: $reason";
      } else {
        project.size = await fileService.getDirSize(
          "${settings.projectDir}/${project.folderName!}",
        );
        if (project.started != null) {
          project.completedIn = DateTime.now().difference(project.started!);
        }
        await _generateUCSCTrack(session, project);
        session.log(
          "MIP generation finished for project ID: ${project.id}",
          level: LogLevel.info,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        "Error finalizing MIP generation for project ID: ${project.id}: $e",
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
      project.error = "MIP generation failed: $e";
    } finally {
      project.pid = 0;
      project.active = false;
      await projectService.updateProject(session, project);
    }

    // Notify after the project has been persisted, so the email reflects the
    // final state (size, duration, error). Guarded independently: finalization
    // has already completed at this point and must never be affected by mail.
    try {
      await sl<MailService>().notifyProjectFinished(
        session,
        project,
        failed: project.error.isNotEmpty,
      );
    } catch (e, stackTrace) {
      session.log(
        "Error notifying about MIP generation for project ID: ${project.id}: $e",
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generates a UCSC track for the specified project.
  ///
  /// \param session The current session.
  /// \param project The project for which to generate the UCSC track.
  /// \returns A future that completes when the UCSC track generation process is finished.
  Future<void> _generateUCSCTrack(Session session, Project project) async {
    SettingsService settingsService = sl<SettingsService>();

    var settings = await settingsService.getSettings(session);
    var projectDir = "${settings.projectDir}/${project.folderName}";

    List<String> arg = [];
    arg.add(settings.ucscTrackGenerator);
    arg.add("$projectDir/${project.name}.picked_mips.txt");
    arg.add("${project.name}_ucsc_track");

    session.log(
      "Starting UCSC track generation process with arguments: $arg",
      level: LogLevel.info,
    );
    var process = await sl<ProcessRunner>().run(
      "python",
      arg,
      workingDirectory: projectDir,
      runInShell: true,
      timeout: helperToolTimeout,
    );

    if (process.exitCode != 0) {
      // ⚠️ Recorded, not merely logged. The track is an optional extra, so this
      // must not fail the run — but a project whose track silently never
      // appeared, with the reason only in the server log, is how somebody
      // spends an afternoon wondering where their UCSC link went.
      final reason = firstLineOf(process.stderr.toString());
      session.log(
        "UCSC track generation failed for project ID: ${project.id}: $reason",
        level: LogLevel.error,
      );
      project.error = project.error.isEmpty
          ? 'The MIPs were generated, but the UCSC track was not: $reason'
          : project.error;
    }
  }
}
