import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/project.dart';
import 'file_service.dart';
import 'options_service.dart';

/// Service class for handling MIP generation related operations.
class MipgenService {
  late final String refGene;
  late final String fa;
  late final String snp;

  /// Constructor to initialize file paths for reference gene, fasta file, and SNP file.
  MipgenService() {
    refGene = "/opt/flumip/data/genes/human/hg38/refGene.txt";
    fa = "/opt/flumip/data/genes/human/hg38/fa/hg38.fa";
    snp = "/opt/flumip/data/genes/human/hg38/snp/00-common_all.vcf.gz";
  }

  /// Creates a BED file for the specified project.
  ///
  /// Throws an [ArgumentError] if the project ID does not exist or if no genes are found in the project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project for which to create the BED file.
  Future<void> createBedFile(Session session, int projectID) async {
    session.log("Starting createBedFile for project ID: $projectID",
        level: LogLevel.info);
    var project = await sl<ProjectService>().getProject(session, projectID);
    if (project.id == null) {
      session.log("Project ID does not exist: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }
    if (project.genes == null || project.genes!.isEmpty) {
      session.log("No genes found in project ID: $projectID",
          level: LogLevel.error);
      throw ArgumentError('No genes found in project');
    }

    var settings = await sl<SettingsService>().getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    String bedFile = "${settings.projectDir}/${project.folderName}/genes.bed";
    if (await File(geneFile).exists()) {
      session.log("Gene file exists, deleting: $geneFile",
          level: LogLevel.warning);
      await sl<FileService>().deleteGeneFile(session, projectID);
    }
    session.log("Creating gene file: $geneFile", level: LogLevel.info);
    await sl<FileService>().createGeneFile(session, projectID, project.genes!);
    List<String> arg = [];
    arg.add(geneFile);
    arg.add(refGene);

    session.log("Running exon extract script with arguments: $arg",
        level: LogLevel.info);
    var process = await Process.run(settings.exonExtractScript, arg);

    if (process.exitCode != 0 || process.stdout == "") {
      session.log("Failed to extract genes for project ID: $projectID",
          level: LogLevel.error);
      throw ArgumentError("Genes could not be extracted");
    }

    session.log("Writing BED file: $bedFile", level: LogLevel.info);
    sl<FileService>().writeStringToFile(session, bedFile, process.stdout);

    project.bedFileCreated = true;
    await sl<ProjectService>().updateProject(session, project);
    session.log("BED file created successfully for project ID: $projectID",
        level: LogLevel.info);
  }

  /// Generates MIPs for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project for which to generate MIPs.
  /// \param deleteExcessFiles Whether to delete excess files after MIP generation.
  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    session.log("Starting generateMips for project ID: $projectID",
        level: LogLevel.info);
    var project = await sl<ProjectService>().getProject(session, projectID);
    var options =
        await sl<OptionsService>().getProjectOptions(session, project.options);

    var settings = await sl<SettingsService>().getSettings(session);

    List<String> arg = [
      "-regions_to_scan",
      "${settings.projectDir}/${project.folderName}/genes.bed",
      "-project_name",
      project.name,
      "-bwa_genome_index",
      fa,
      "-snp_file",
      snp,
      "-min_capture_size",
      options.minCaptureSize.toString(),
      "-max_capture_size",
      options.maxCaptureSize.toString(),
      if (options.armLengths!.isNotEmpty) ...[
        "-arm_lengths",
        options.armLengths!
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
      options.bwaThreads.toString()
    ];

    session.log("Starting MIP generation process with arguments: $arg",
        level: LogLevel.info);
    await Process.start(settings.mipgenExecutable, arg,
        workingDirectory: "${settings.projectDir}/${project.folderName}",
        runInShell: true);
    project.started = DateTime.now();
    project.active = true;
    var mipgenPID = await sl<ProcessService>()
        .getProcessPID(session, "mipgen", "-project_name ${project.name}");
    project.pid = mipgenPID;
    project.cleanup = deleteExcessFiles;
    await sl<ProjectService>().updateProject(session, project);
    session.log(
        "MIP generation started with PID: $mipgenPID for project ID: $projectID",
        level: LogLevel.info);

    await session.serverpod.futureCallWithDelay(
        'checkMipgenProgress', project, const Duration(seconds: 15));
  }

  /// Marks the MIP generation process as finished for the specified project.
  ///
  /// \param session The current session.
  /// \param projectModel The project model to update.
  Future<void> mipgenIsFinished(Session session, Project projectModel) async {
    final settings = await sl<SettingsService>().getSettings(session);
    session.log("Finishing MIP generation for project ID: ${projectModel.id}",
        level: LogLevel.info);
    var project =
        await sl<ProjectService>().getProject(session, projectModel.id!);
    if (project.id == null) {
      session.log("Project ID does not exist: ${projectModel.id}",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    if (project.cleanup) {
      session.log("Deleting byproducts for project ID: ${project.id}",
          level: LogLevel.info);
      await sl<FileService>().deleteByproducts(session, project.id!);
    }

    //TODO: better errors handling
    var progress =
        await sl<FileService>().showMipsProgress(session, project.id!);
    if (progress.isEmpty) {
      session.log("MIP generation failed for project ID: ${project.id}",
          level: LogLevel.warning);
      project.error = "MIP generation failed";
    } else {
      project.size = await sl<FileService>()
          .getDirSize("${settings.projectDir}/${project.folderName!}");
      project.pid = 0;
      project.completedIn = DateTime.now().difference(project.started!);
      await _generateUCSCTrack(session, project);
      session.log("MIP generation finished for project ID: ${project.id}",
          level: LogLevel.info);
    }
    project.active = false;
    await sl<ProjectService>().updateProject(session, project);
  }

  /// Generates a UCSC track for the specified project.
  ///
  /// \param session The current session.
  /// \param project The project for which to generate the UCSC track.
  /// \returns A future that completes when the UCSC track generation process is finished.
  Future<void> _generateUCSCTrack(Session session, Project project) async {
    var settings = await sl<SettingsService>().getSettings(session);
    var projectDir = "${settings.projectDir}/${project.folderName}";

    List<String> arg = [];
    arg.add(settings.ucscTrackGenerator);
    arg.add("$projectDir/${project.name}.picked_mips.txt");
    arg.add("${project.name}_ucsc_track");

    session.log("Starting UCSC track generation process with arguments: $arg",
        level: LogLevel.info);
    var process = await Process.run("python", arg,
        workingDirectory: projectDir, runInShell: true);

    if (process.exitCode != 0) {
      session.log("UCSC track generation failed for project ID: ${project.id}",
          level: LogLevel.error);
    }
  }
}
