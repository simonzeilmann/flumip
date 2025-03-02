import 'dart:io';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import 'file_service.dart';

class MipgenService {
  final projectService = ProjectService();
  final fileService = FileService();
  late final String mipgenExe;
  late final String projectFolder;
  late final String exonExtract;
  late final String refGene;
  late final String fa;
  late final String snp;

  MipgenService() {
    projectFolder = "/opt/mipgen/projects";
    mipgenExe = "/opt/mipgen/MIPGEN/mipgen";
    exonExtract = "/opt/mipgen/MIPGEN/tools/extract_coding_gene_exons.sh";
    refGene = "/opt/mipgen/data/genes/human/hg38/refGene.txt";
    fa = "/opt/mipgen/data/genes/human/hg38/fa/hg38.fa";
    snp = "/opt/mipgen/data/genes/human/hg38/snp/00-common_all.vcf.gz";
  }

  Future<void> createBedFile(Session session, int projectID) async {
    var project = await projectService.getProject(session, projectID);
    if (project.id == null) {
      throw ArgumentError('Project id does not exist');
    }
    if (project.geneFileCreated == false) {
      throw ArgumentError('Gene file does not exist');
    }

    String geneFile = "$projectFolder/${project.id}/genes.txt";
    String bedFile = "$projectFolder/${project.id}/genes.bed";
    if (!await File(geneFile).exists()) {
      throw FileNotFoundException(message: 'Gene file does not exist');
    } else {
      List<String> arg = [];
      arg.add(geneFile);
      arg.add(refGene);

      var process = await Process.run(exonExtract, arg);

      if (process.exitCode != 0 || process.stdout == "") {
        //TODO: error handling
        throw ();
      }

      fileService.writeStringToFile(bedFile, process.stdout);

      project.bedFileCreated = true;
      await projectService.updateProject(session, project);
    }
  }

  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    var project = await projectService.getProject(session, projectID);

    List<String> arg = [];
    arg.add("-regions_to_scan");
    arg.add("$projectFolder/${project.id}/genes.bed");
    arg.add("-project_name");
    arg.add(project.name);
    arg.add("-min_capture_size");
    arg.add("162");
    arg.add("-max_capture_size");
    arg.add("162");
    arg.add("-bwa_genome_index");
    arg.add(fa);
    arg.add("-snp_file");
    arg.add(snp);

    await Process.start(mipgenExe, arg,
        workingDirectory: "$projectFolder/${project.id}", runInShell: true);
    project.started = DateTime.now();
    project.active = true;
    var mipgenPID = await getMipgenPID(session, project.name);
    project.pid = mipgenPID;
    project.cleanup = deleteExcessFiles;
    await projectService.updateProject(session, project);
  }

  Future<int> getMipgenPID(Session session, String projectName) async {
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
