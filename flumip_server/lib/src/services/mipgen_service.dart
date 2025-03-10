import 'dart:io';
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
  final projectService = ProjectService();
  final fileService = FileService();
  final settingsService = SettingsService();
  final optionsService = OptionsService();
  final processService = ProcessService();
  late final String refGene;
  late final String fa;
  late final String snp;

  /// Constructor to initialize file paths for reference gene, fasta file, and SNP file.
  MipgenService() {
    refGene = "/opt/mipgen/data/genes/human/hg38/refGene.txt";
    fa = "/opt/mipgen/data/genes/human/hg38/fa/hg38.fa";
    snp = "/opt/mipgen/data/genes/human/hg38/snp/00-common_all.vcf.gz";
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
    var project = await projectService.getProject(session, projectID);
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

    var settings = await settingsService.getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    String bedFile = "${settings.projectDir}/${project.folderName}/genes.bed";
    if (await File(geneFile).exists()) {
      session.log("Gene file exists, deleting: $geneFile",
          level: LogLevel.warning);
      await fileService.deleteGeneFile(session, projectID);
    }
    session.log("Creating gene file: $geneFile", level: LogLevel.info);
    await fileService.createGeneFile(session, projectID, project.genes!);
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
    fileService.writeStringToFile(session, bedFile, process.stdout);

    project.bedFileCreated = true;
    await projectService.updateProject(session, project);
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
    var project = await projectService.getProject(session, projectID);
    var options = await optionsService.getProjectOptions(session, project.id!);

    var settings = await settingsService.getSettings(session);

    List<String> arg = [];
    arg.add("-regions_to_scan");
    arg.add("${settings.projectDir}/${project.folderName}/genes.bed");
    arg.add("-project_name");
    arg.add(project.name);
    arg.add("-bwa_genome_index");
    arg.add(fa);
    arg.add("-snp_file");
    arg.add(snp);
    arg.add("-min_capture_size");
    arg.add(options.minCaptureSize.toString());
    arg.add("-max_capture_size");
    arg.add(options.maxCaptureSize.toString());
    if (options.armLengths != null) {
      arg.add("-arm_lengths");
      arg.add(options.armLengths!);
    }
    arg.add("-arm_length_sums");
    arg.add(options.armLengthSums.toString());
    arg.add("-ext_min_length");
    arg.add(options.extMinLength.toString());
    arg.add("-lig_min_length");
    arg.add(options.ligMinLength.toString());
    arg.add("-tag_sizes");
    arg.add(options.tagSizes.toString());
    arg.add("-masked_arm_threshold");
    arg.add(options.maskedArmThreshold.toString());
    arg.add("-target_arm_copy");
    arg.add(options.targetArmCopy.toString());
    arg.add("-max_arm_copy_product");
    arg.add(options.maxArmCopyProduct.toString());
    arg.add("-trf");
    if (options.trf == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    if (options.genomeDir != null) {
      arg.add("-genome_dir");
      arg.add(options.genomeDir!);
    }
    arg.add("-feature_flank");
    arg.add(options.featureFlank.toString());
    arg.add("-capture_increment");
    arg.add(options.captureIncrement.toString());
    arg.add("-logistic_heuristic");
    if (options.logisticHeuristic == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-max_mip_overlap");
    arg.add(options.maxMipOverlap.toString());
    arg.add("-starting_mip_overlap");
    arg.add(options.startingMipOverlap.toString());
    arg.add("-check_copy_number");
    if (options.checkCopyNumber == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-seal_both_strands");
    if (options.sealBothStrands == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-half_seal_both_strands");
    if (options.halfSealBothStrands == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-double_tile_strand_unaware");
    if (options.doubleTileStrandUnaware == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-double_tile_strands_separately");
    if (options.doubleTileStrandsSeparately == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-score_method");
    arg.add(options.scoreMethod.name);
    arg.add("-logistic_optimal_score");
    arg.add(options.logisticOptimalScore.toString());
    arg.add("-svr_optimal_score");
    arg.add(options.svrOptimalScore.toString());
    arg.add("-logistic_priority_score");
    arg.add(options.logisticPriorityScore.toString());
    arg.add("-svr_priority_score");
    arg.add(options.svrPriorityScore.toString());
    arg.add("-silent_mode");
    if (options.silentMode == true) {
      arg.add("on");
    } else {
      arg.add("off");
    }
    arg.add("-bwa_threads");
    arg.add(options.bwaThreads.toString());

    session.log("Starting MIP generation process with arguments: $arg",
        level: LogLevel.info);
    await Process.start(settings.mipgenExecutable, arg,
        workingDirectory: "${settings.projectDir}/${project.folderName}",
        runInShell: true);
    project.started = DateTime.now();
    project.active = true;
    var mipgenPID = await processService.getProcessPID(session, project.name);
    project.pid = mipgenPID;
    project.cleanup = deleteExcessFiles;
    await projectService.updateProject(session, project);
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
    session.log("Finishing MIP generation for project ID: ${projectModel.id}",
        level: LogLevel.info);
    var project = await projectService.getProject(session, projectModel.id!);
    if (project.id == null) {
      session.log("Project ID does not exist: ${projectModel.id}",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    if (project.cleanup) {
      session.log("Deleting byproducts for project ID: ${project.id}",
          level: LogLevel.info);
      await fileService.deleteByproducts(session, project.id!);
    }
    //TODO: check for errors

    project.active = false;
    project.pid = 0;
    project.completedIn = project.started?.difference(DateTime.now());
    await projectService.updateProject(session, project);
    session.log("MIP generation finished for project ID: ${project.id}",
        level: LogLevel.info);
  }
}
