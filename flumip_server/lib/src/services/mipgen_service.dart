import 'dart:io';

import 'package:serverpod/protocol.dart';

class MipgenService {
  Map<String, String> envVars = Platform.environment;

  late final String mipgenExe;
  late final String projectFolder;
  late final String exonExtract;
  late final String refGene;
  late final String fa;
  late final String snp;

  MipgenService() {
    projectFolder = "${envVars['HOME']}/mipgen/projects";
    mipgenExe = "${envVars['HOME']}/mipgen/MIPGEN/mipgen";
    exonExtract =
        "${envVars['HOME']}/mipgen/MIPGEN/tools/extract_coding_gene_exons.sh";
    refGene = "${envVars['HOME']}/mipgen/data/genes/human/hg38/refGene.txt";
    fa = "${envVars['HOME']}/mipgen/data/genes/human/hg38/fa/hg38.fa";
    snp =
        "${envVars['HOME']}/mipgen/data/genes/human/hg38/snp/00-common_all.vcf.gz";
  }

  Future<bool> createProject(String projectName) async {
    if (await checkProjectExists(projectName)) {
      return false;
    }
    await Directory("$projectFolder/$projectName").create();
    return true;
  }

  void deleteProject(String projectName) {
    Directory("$projectFolder/$projectName").delete(recursive: true);
  }

  Future<List<String>> getProjects() async {
    var dir = await Directory(projectFolder).list().toList();
    List<String> projects = [];
    for (var d in dir) {
      if (d is Directory) {
        projects.add(d.path.split("/").last);
      }
    }
    return projects;
  }

  Future<void> createGeneFile(String projectName, List<String> genes) async {
    if (!await checkProjectExists(projectName)) {
      throw ();
    }
    String geneFile = "$projectFolder/$projectName/genes.txt";
    if (await File(geneFile).exists()) {
      await writeListToFile(geneFile, genes);
    } else {
      File(geneFile).create();
      await writeListToFile(geneFile, genes);
    }
  }

  Future<List<String>> getGenes(String projectName) async {
    String geneFile = "$projectFolder/$projectName/genes.txt";
    if (!await File(geneFile).exists()) {
      throw FileNotFoundException(message: 'genes.txt not found');
    } else {
      return await File(geneFile).readAsLines();
    }
  }

  Future<void> createBedFile(String projectName) async {
    String geneFile = "$projectFolder/$projectName/genes.txt";
    String bedFile = "$projectFolder/$projectName/genes.bed";
    if (!await File(geneFile).exists()) {
      throw ();
    } else {
      List<String> arg = [];
      arg.add(geneFile);
      arg.add(refGene);

      var process = await Process.run(exonExtract, arg);

      await File(bedFile).create();
      var sink = File(bedFile).openWrite();
      sink.write(process.stdout);
      await sink.flush();
      await sink.close();

      if (!await File(bedFile).exists() ||
          await File(bedFile).length() < 1024) {
        throw ();
      }
    }
  }

  Future<bool> checkBedFileExists(String projectName) async {
    if (await File("$projectFolder/$projectName/genes.bed").exists() &&
        await File("$projectFolder/$projectName/genes.bed").length() > 1024) {
      return true;
    }
    return false;
  }

  Future<void> generateMips(String projectName, bool deleteExcessFiles) async {
    List<String> arg = [];
    arg.add("-regions_to_scan");
    arg.add("$projectFolder/$projectName/genes.bed");
    arg.add("-project_name");
    arg.add(projectName);
    arg.add("-min_capture_size");
    arg.add("162");
    arg.add("-max_capture_size");
    arg.add("162");
    arg.add("-bwa_genome_index");
    arg.add(fa);
    arg.add("-snp_file");
    arg.add(snp);

    var result = await Process.run(mipgenExe, arg,
        workingDirectory: "$projectFolder/$projectName", runInShell: true);
    if (result.exitCode != 0) {
      //TODO: error handling
      throw ();
    } else {
      if (deleteExcessFiles) {
        deleteByproducts(projectName);
      }
    }
  }

  Future<List<String>> showMipsResult(String projectName) async {
    var dir = await Directory("$projectFolder/$projectName").list().toList();

    for (var d in dir) {
      if (d.path.endsWith(".picked_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        return lines;
      }
    }

    return List.empty();
  }

  Future<List<String>> showMipsProgress(String projectName) async {
    var dir = await Directory("$projectFolder/$projectName").list().toList();

    for (var d in dir) {
      if (d.path.endsWith(".progress.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        return lines;
      }
    }

    return List.empty();
  }

  Future<void> deleteByproducts(String projectName) async {
    var dir = await Directory("$projectFolder/$projectName").list().toList();

    for (var d in dir) {
      if (d.path.endsWith(".sai") || d.path.endsWith(".fq")) {
        d.delete();
      }
    }
  }

  Future<void> writeListToFile(String path, List<String> list) async {
    var sink = File(path).openWrite();
    list.forEach(sink.writeln);
    await sink.flush();
    await sink.close();
  }

  Future<bool> checkProjectExists(String projectName) async {
    return await Directory("$projectFolder/$projectName").exists();
  }
}
