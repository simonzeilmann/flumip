import 'dart:io';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../../service_locator.dart';
import '../generated/protocol.dart';

class GenomeService {
  GenomeService();

  Future<List<String>> getGenomeCategories(Session session) async {
    var allGenomes = await getAllGenomes(session);
    var categories = <String>{};
    for (var genome in allGenomes) {
      categories.add(genome.category!);
    }

    session.log('Gene categories retrieved', level: LogLevel.info);
    return categories.toList();
  }

  Future<List<Genome>> getGenomeByCategory(
      Session session, String category) async {
    var allGenomes = await getAllGenomes(session);
    var genomes = <Genome>[];
    for (var genome in allGenomes) {
      if (genome.category == category) {
        genomes.add(genome);
      }
    }

    session.log('Genes retrieved by category: $category', level: LogLevel.info);
    return genomes;
  }

  Future<Genome> getGenome(Session session, int id) async {
    session.log("Retrieving gene with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null) {
      session.log("Gene not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene not found');
    }
    session.log("Gene retrieved with ID: $id", level: LogLevel.info);
    return genome;
  }

  Future<List<Genome>> getAllGenomes(Session session) {
    session.log("Retrieving all genes", level: LogLevel.info);
    return Genome.db.find(session, where: (t) => t.id > 0);
  }

  Future<void> updateGenome(Session session, int id, Genome gene) async {
    session.log("Updating gene with ID: $id", level: LogLevel.info);
    var genomeToUpdate = await Genome.db.findById(session, id);
    if (genomeToUpdate == null) {
      session.log("Gene not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene not found');
    }
    await Genome.db.updateRow(session, gene);
    session.log("Gene updated with ID: $id", level: LogLevel.info);
  }

  Future<void> collectGenomes(Session session) async {
    session.log("Collecting genes", level: LogLevel.info);
    final settings = await sl.get<SettingsService>().getSettings(session);
    var categoryFolder = Directory(settings.genomeDir);

    if (!await categoryFolder.exists()) {
      session.log('Gene folder not found', level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene folder not found');
    }

    for (var category in categoryFolder.listSync().whereType<Directory>()) {
      for (var genomeFolder
          in Directory(category.path).listSync().whereType<Directory>()) {
        var existingGenome = await _genomeExists(session, genomeFolder.path);
        if (existingGenome != null) {
          await _processGenomeFolder(session, existingGenome, genomeFolder);
        } else {
          await _createNewGenome(session, category, genomeFolder);
        }
      }
    }
    session.log("Gene collection completed", level: LogLevel.info);
  }

  Future<void> _processGenomeFolder(
      Session session, Genome existingGenome, Directory genomeFolder) async {
    session.log("Processing gene folder: ${genomeFolder.path}",
        level: LogLevel.info);
    for (var genomeFile in genomeFolder.listSync().whereType<Directory>()) {
      if (genomeFile.path.endsWith("fa")) {
        var faFilesString = Directory(genomeFile.path).listSync().toString();
        if (_containsFaFiles(faFilesString)) {
          existingGenome.indexed = true;
        }
      } else if (genomeFile.path.endsWith("snp")) {
        await _processSnpFolder(session, existingGenome, genomeFile);
      }
    }
    await Genome.db.updateRow(session, existingGenome);
    session.log("Gene folder processed: ${genomeFolder.path}",
        level: LogLevel.info);
  }

  Future<void> _processSnpFolder(
      Session session, Genome existingGenome, Directory snpFolder) async {
    session.log("Processing SNP folder: ${snpFolder.path}",
        level: LogLevel.info);
    for (var snpDir in snpFolder.listSync().whereType<Directory>()) {
      var snpFilesString = Directory(snpDir.path).listSync().toString();
      if (_containsSnpFiles(snpFilesString)) {
        var snp = Snp(
          name: snpDir.path.split('/').last,
          vcfPath: _getFilePath(snpDir, ".vcf.gz"),
          tbiPath: _getFilePath(snpDir, ".vcf.gz.tbi"),
          folder: snpDir.path,
          active: true,
        );
        var existingSnp = await _snpExists(session, snpDir.path);
        if (existingSnp == null) {
          var snpRet = await Snp.db.insertRow(session, snp);
          existingGenome.snp ??= <int>[];
          existingGenome.snp?.add(snpRet.id!);
        }
      }
    }
    session.log("SNP folder processed: ${snpFolder.path}",
        level: LogLevel.info);
  }

  Future<void> _createNewGenome(
      Session session, Directory category, Directory genomeFolder) async {
    session.log("Creating new gene from folder: ${genomeFolder.path}",
        level: LogLevel.info);
    var genome = Genome(
      name: genomeFolder.path.split('/').last,
      category: category.path.split('/').last,
      path: genomeFolder.path,
    );
    List<Snp> snps = [];
    for (var genomeFile in genomeFolder.listSync()) {
      if (genomeFile is File && genomeFile.path.endsWith("refGene.txt")) {
        genome.refPath = genomeFile.path;
      } else if (genomeFile is Directory) {
        if (genomeFile.path.endsWith("fa")) {
          genome.fastaPath = _getFilePath(genomeFile, ".fa");
          if (_containsFaFiles(
              Directory(genomeFile.path).listSync().toString())) {
            genome.indexed = true;
          }
        } else if (genomeFile.path.endsWith("snp")) {
          genome.snpFolder = genomeFile.path;
          snps.addAll(await _createSnpsFromFolder(session, genomeFile));
        }
      }
    }
    if (genome.refPath != null && genome.fastaPath != null) {
      for (var snp in snps) {
        var snpRet = await Snp.db.insertRow(session, snp);
        genome.snp ??= <int>[];
        genome.snp?.add(snpRet.id!);
      }
      await Genome.db.insertRow(session, genome);
    }
    session.log("New gene created from folder: ${genomeFolder.path}",
        level: LogLevel.info);
  }

  Future<List<Snp>> _createSnpsFromFolder(
      Session session, Directory snpFolder) async {
    session.log("Creating SNPs from folder: ${snpFolder.path}",
        level: LogLevel.info);
    List<Snp> snps = [];
    for (var snpDir in snpFolder.listSync().whereType<Directory>()) {
      var snpFilesString = Directory(snpDir.path).listSync().toString();
      if (_containsSnpFiles(snpFilesString)) {
        snps.add(Snp(
          name: snpDir.path.split('/').last,
          vcfPath: _getFilePath(snpDir, ".vcf.gz"),
          tbiPath: _getFilePath(snpDir, ".vcf.gz.tbi"),
          folder: snpDir.path,
          active: true,
        ));
      }
    }
    session.log("SNPs created from folder: ${snpFolder.path}",
        level: LogLevel.info);
    return snps;
  }

  bool _containsFaFiles(String filesString) {
    return filesString.contains(".fa.amb") &&
        filesString.contains(".fa.pac") &&
        filesString.contains(".fa.sa") &&
        filesString.contains(".fa.bwt") &&
        filesString.contains(".fa.ann");
  }

  bool _containsSnpFiles(String filesString) {
    return filesString.contains(".vcf.gz") &&
        filesString.contains(".vcf.gz.tbi");
  }

  String _getFilePath(Directory dir, String extension) {
    return dir
        .listSync()
        .firstWhere((file) => file.path.endsWith(extension))
        .path;
  }

  Future<void> indexFasta(Session session, int id) async {
    session.log("Indexing Fasta for gene with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null ||
        genome.indexed ||
        genome.fastaPath == null ||
        genome.indexing) {
      session.log("Invalid gene state for indexing with ID: $id",
          level: LogLevel.error);
      throw ArgumentError();
    }

    Process.start("bwa", [genome.fastaPath!], runInShell: true);
    genome.indexing = true;
    genome.indexPID = await sl<ProcessService>()
        .getProcessPID(session, "bwa", genome.fastaPath!);
    await Genome.db.updateRow(session, genome);
    await session.serverpod.futureCallWithDelay(
        'checkIndexProgress', genome, const Duration(seconds: 30));
    session.log("Indexing started for gene with ID: $id", level: LogLevel.info);
  }

  Future<void> indexIsFinished(Session session, object) async {
    session.log("Indexing finished for gene with ID: ${object.id}",
        level: LogLevel.info);
    var faFilesString =
        Directory(object.fastaPath + "/fa").listSync().toString();
    if (_containsFaFiles(faFilesString)) {
      object.indexed = true;
    }
    object.indexing = false;
    object.indexPID = 0;
    await Genome.db.updateRow(session, object);
    session.log("Indexing marked as finished for gene with ID: ${object.id}",
        level: LogLevel.info);
  }

  Future<void> deleteFastaIndex(Session session, int id) async {
    session.log("Deleting index for gene with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null || !genome.indexed || genome.indexing) {
      session.log("Invalid gene state for deleting index with ID: $id",
          level: LogLevel.error);
      throw ArgumentError();
    }

    var faFiles = Directory("${genome.path!}/fa");
    for (var faFile in faFiles.listSync()) {
      if (faFile.path.endsWith(".fa.amb") ||
          faFile.path.endsWith(".fa.pac") ||
          faFile.path.endsWith(".fa.sa") ||
          faFile.path.endsWith(".fa.bwt") ||
          faFile.path.endsWith(".fa.ann")) {
        faFile.deleteSync();
      }
    }
    genome.indexed = false;
    await Genome.db.updateRow(session, genome);
    session.log("Index deleted for gene with ID: $id", level: LogLevel.info);
  }

  Future<Snp> getSnp(Session session, int id) async {
    session.log("Retrieving SNP with ID: $id", level: LogLevel.info);
    var snp = await Snp.db.findById(session, id);
    if (snp == null) {
      session.log("SNP not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'SNP not found');
    }
    session.log("SNP retrieved with ID: $id", level: LogLevel.info);
    return snp;
  }

  Future<List<Snp>> getAllSnps(Session session) {
    session.log("Retrieving all SNPs", level: LogLevel.info);
    return Snp.db.find(session, where: (t) => t.id > 0);
  }

  Future<List<Snp>> getAllSnpForGenome(Session session, int genomeId) async {
    session.log("Retrieving all SNPs for gene with ID: $genomeId",
        level: LogLevel.info);
    var genome = await Genome.db.findById(session, genomeId);
    if (genome == null) {
      session.log("Gene not found with ID: $genomeId", level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene not found');
    }
    List<Snp> snps = [];
    for (var snpId in genome.snp!) {
      var snp = await Snp.db.findById(session, snpId);
      if (snp != null) {
        snps.add(snp);
      }
    }
    return snps;
  }

  Future<void> updateSnp(Session session, int id, Snp snp) async {
    session.log("Updating SNP with ID: $id", level: LogLevel.info);
    var snpToUpdate = await Snp.db.findById(session, id);
    if (snpToUpdate == null) {
      session.log("SNP not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'SNP not found');
    }
    await Snp.db.updateRow(session, snp);
    session.log("SNP updated with ID: $id", level: LogLevel.info);
  }

  Future<Genome?> _genomeExists(Session session, String path) async {
    session.log("Checking if gene exists with path: $path",
        level: LogLevel.info);
    var genome =
        await Genome.db.find(session, where: (t) => t.path.equals(path));
    return genome.isNotEmpty ? genome.first : null;
  }

  Future<Snp?> _snpExists(Session session, String path) async {
    session.log("Checking if SNP exists with path: $path",
        level: LogLevel.info);
    var snp = await Snp.db.find(session, where: (t) => t.folder.equals(path));
    return snp.isNotEmpty ? snp.first : null;
  }
}
