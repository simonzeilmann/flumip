import 'dart:io';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/server.dart';

import 'file_service.dart';

class MipgenService {
  final projectService = ProjectService();
  final fileService = FileService();
  final settingsService = SettingsService();
  late final String refGene;
  late final String fa;
  late final String snp;

  MipgenService() {
    refGene = "/opt/mipgen/data/genes/human/hg38/refGene.txt";
    fa = "/opt/mipgen/data/genes/human/hg38/fa/hg38.fa";
    snp = "/opt/mipgen/data/genes/human/hg38/snp/00-common_all.vcf.gz";
  }

  Future<void> createBedFile(Session session, int projectID) async {
    var project = await projectService.getProject(session, projectID);
    if (project.id == null) {
      throw ArgumentError('Project id does not exist');
    }
    if (project.genes == null || project.genes!.isEmpty) {
      throw ArgumentError('No genes found in project');
    }

    var settings = await settingsService.getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    String bedFile = "${settings.projectDir}/${project.folderName}/genes.bed";
    if (await File(geneFile).exists()) {
      await fileService.deleteGeneFile(session, projectID);
    }
    await fileService.createGeneFile(session, projectID, project.genes!);
    List<String> arg = [];
    arg.add(geneFile);
    arg.add(refGene);

    var process = await Process.run(settings.exonExtractScript, arg);

    if (process.exitCode != 0 || process.stdout == "") {
      throw ArgumentError("Genes could not be extracted");
    }

    fileService.writeStringToFile(bedFile, process.stdout);

    project.bedFileCreated = true;
    await projectService.updateProject(session, project);
  }

  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    var project = await projectService.getProject(session, projectID);
    var options =
        await projectService.getProjectOptions(session, project.options);

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

    await Process.start(settings.mipgenExecutable, arg,
        workingDirectory: "${settings.projectDir}/${project.folderName}",
        runInShell: true);
    project.started = DateTime.now();
    project.active = true;
    var mipgenPID = await _getMipgenPID(session, project.name);
    project.pid = mipgenPID;
    project.cleanup = deleteExcessFiles;
    await projectService.updateProject(session, project);
  }

  Future<int> _getMipgenPID(Session session, String projectName) async {
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
        if (line.contains("-project_name $projectName")) {
          mipgenPID = int.parse(line.split(" ")[0]);
          break;
        }
      }
    }

    return mipgenPID;
  }
}
