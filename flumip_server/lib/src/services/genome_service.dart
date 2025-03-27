import 'dart:io';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import '../../service_locator.dart';
import '../generated/protocol.dart';

class GenomeService {
  GenomeService();

  /// Retrieves the list of genome categories.
  ///
  /// \param session The current session.
  /// \returns A list of genome categories.
  Future<List<String>> getGenomeCategories(Session session) async {
    var allGenomes = await getAllGenomes(session);
    var categories = <String>{};
    for (var genome in allGenomes) {
      categories.add(genome.category!);
    }

    session.log('Genome categories retrieved', level: LogLevel.info);
    return categories.toList();
  }

  /// Retrieves genomes by category.
  ///
  /// \param session The current session.
  /// \param category The category to filter genomes by.
  /// \returns A list of genomes in the specified category.
  Future<List<Genome>> getGenomeByCategory(
      Session session, String category) async {
    var allGenomes = await getAllGenomes(session);
    var genomes = <Genome>[];
    for (var genome in allGenomes) {
      if (genome.category == category) {
        genomes.add(genome);
      }
    }

    session.log('Genomes retrieved by category: $category',
        level: LogLevel.info);
    return genomes;
  }

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The retrieved genome.
  Future<Genome> getGenome(Session session, int id) async {
    session.log("Retrieving genome with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null) {
      session.log("Genome not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Genome not found');
    }
    session.log("Genome retrieved with ID: $id", level: LogLevel.info);
    return genome;
  }

  /// Retrieves all genomes.
  ///
  /// \param session The current session.
  /// \returns A list of all genomes.
  Future<List<Genome>> getAllGenomes(Session session) {
    session.log("Retrieving all genomes", level: LogLevel.info);
    return Genome.db.find(session, where: (t) => t.id > 0);
  }

  /// Updates a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to update.
  /// \param genome The updated genome data.
  Future<void> updateGenome(Session session, int id, Genome genome) async {
    session.log("Updating genome with ID: $id", level: LogLevel.info);
    var genomeToUpdate = await Genome.db.findById(session, id);
    if (genomeToUpdate == null) {
      session.log("Genome not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Genome not found');
    }
    await Genome.db.updateRow(session, genome);
    session.log("Genome updated with ID: $id", level: LogLevel.info);
  }

  /// Collects genomes from the specified directory.
  ///
  /// \param session The current session.
  Future<void> collectGenomes(Session session) async {
    session.log("Collecting genomes", level: LogLevel.info);
    final settings = await sl.get<SettingsService>().getSettings(session);
    var categoryFolder = Directory(settings.genomeDir);

    if (!await categoryFolder.exists()) {
      session.log('Genome folder not found', level: LogLevel.error);
      throw FileNotFoundException(message: 'Genome folder not found');
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
    session.log("Genome collection completed", level: LogLevel.info);
  }

  /// Processes a genome folder.
  ///
  /// \param session The current session.
  /// \param existingGenome The existing genome data.
  /// \param genomeFolder The genome folder to process.
  Future<void> _processGenomeFolder(
      Session session, Genome existingGenome, Directory genomeFolder) async {
    session.log("Processing genome folder: ${genomeFolder.path}",
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
    session.log("Genome folder processed: ${genomeFolder.path}",
        level: LogLevel.info);
  }

  /// Processes an SNP folder.
  ///
  /// \param session The current session.
  /// \param existingGenome The existing genome data.
  /// \param snpFolder The SNP folder to process.
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

  /// Creates a new genome from a folder.
  ///
  /// \param session The current session.
  /// \param category The category directory.
  /// \param genomeFolder The genome folder to create the genome from.
  Future<void> _createNewGenome(
      Session session, Directory category, Directory genomeFolder) async {
    session.log("Creating new genome from folder: ${genomeFolder.path}",
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
    session.log("New genome created from folder: ${genomeFolder.path}",
        level: LogLevel.info);
  }

  /// Creates SNPs from a folder.
  ///
  /// \param session The current session.
  /// \param snpFolder The SNP folder to create SNPs from.
  /// \returns A list of created SNPs.
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

  /// Checks if the specified files string contains FA files.
  ///
  /// \param filesString The string containing file names.
  /// \returns A boolean indicating if the string contains FA files.
  bool _containsFaFiles(String filesString) {
    return filesString.contains(".fa.amb") &&
        filesString.contains(".fa.pac") &&
        filesString.contains(".fa.sa") &&
        filesString.contains(".fa.bwt") &&
        filesString.contains(".fa.ann");
  }

  /// Checks if the specified files string contains SNP files.
  ///
  /// \param filesString The string containing file names.
  /// \returns A boolean indicating if the string contains SNP files.
  bool _containsSnpFiles(String filesString) {
    return filesString.contains(".vcf.gz") &&
        filesString.contains(".vcf.gz.tbi");
  }

  /// Gets the file path with the specified extension from a directory.
  ///
  /// \param dir The directory to search in.
  /// \param extension The file extension to look for.
  /// \returns The file path with the specified extension.
  String _getFilePath(Directory dir, String extension) {
    return dir
        .listSync()
        .firstWhere((file) => file.path.endsWith(extension))
        .path;
  }

  /// Indexes the FASTA file for a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to index.
  Future<void> indexFasta(Session session, int id) async {
    session.log("Indexing Fasta for genome with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null) {
      session.log("Invalid genome state for indexing with ID: $id",
          level: LogLevel.error);
      throw ArgumentError();
    }
    if (genome.indexed) {
      session.log("Genome already indexed with ID: $id", level: LogLevel.error);
      throw ArgumentError();
    }
    if (genome.indexing) {
      session.log("Genome already indexing with ID: $id",
          level: LogLevel.error);
      throw ArgumentError();
    }
    if (genome.fastaPath == null) {
      session.log("Genome has no FASTA file with ID: $id",
          level: LogLevel.error);
      throw ArgumentError();
    }

    await Process.start("bwa",["index", genome.fastaPath!],
        workingDirectory: "${genome.path}/fa", runInShell: true);
    genome.indexing = true;
    genome.indexPID = await sl<ProcessService>()
        .getProcessPID(session, "bwa", genome.fastaPath!);
    await Genome.db.updateRow(session, genome);
    await session.serverpod.futureCallWithDelay(
        'checkIndexProgress', genome, const Duration(seconds: 30));
    session.log("Indexing started for genome with ID: $id",
        level: LogLevel.info);
  }

  /// Marks the indexing as finished for a genome.
  ///
  /// \param session The current session.
  /// \param object The genome object.
  Future<void> indexIsFinished(Session session, object) async {
    session.log("Indexing finished for genome with ID: ${object.id}",
        level: LogLevel.info);
    var faFilesString =
        Directory(object.fastaPath + "/fa").listSync().toString();
    if (_containsFaFiles(faFilesString)) {
      object.indexed = true;
    }
    object.indexing = false;
    object.indexPID = 0;
    await Genome.db.updateRow(session, object);
    session.log("Indexing marked as finished for genome with ID: ${object.id}",
        level: LogLevel.info);
  }

  /// Deletes the FASTA index for a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to delete the index for.
  Future<void> deleteFastaIndex(Session session, int id) async {
    session.log("Deleting index for genome with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    if (genome == null || !genome.indexed || genome.indexing) {
      session.log("Invalid genome state for deleting index with ID: $id",
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
    session.log("Index deleted for genome with ID: $id", level: LogLevel.info);
  }

  /// Retrieves an SNP by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The retrieved SNP.
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

  /// Retrieves all SNPs.
  ///
  /// \param session The current session.
  /// \returns A list of all SNPs.
  Future<List<Snp>> getAllSnps(Session session) {
    session.log("Retrieving all SNPs", level: LogLevel.info);
    return Snp.db.find(session, where: (t) => t.id > 0);
  }

  /// Retrieves all SNPs for a genome.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of SNPs for the specified genome.
  Future<List<Snp>> getAllSnpForGenome(Session session, int genomeId) async {
    session.log("Retrieving all SNPs for genome with ID: $genomeId",
        level: LogLevel.info);
    var genome = await Genome.db.findById(session, genomeId);
    if (genome == null) {
      session.log("Genome not found with ID: $genomeId", level: LogLevel.error);
      throw FileNotFoundException(message: 'Genome not found');
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

  /// Updates an SNP.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to update.
  /// \param snp The updated SNP data.
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

  /// Checks if a genome exists by its path.
  ///
  /// \param session The current session.
  /// \param path The path of the genome to check.
  /// \returns The genome if it exists, otherwise null.
  Future<Genome?> _genomeExists(Session session, String path) async {
    session.log("Checking if genome exists with path: $path",
        level: LogLevel.info);
    var genome =
        await Genome.db.find(session, where: (t) => t.path.equals(path));
    return genome.isNotEmpty ? genome.first : null;
  }

  /// Checks if an SNP exists by its path.
  ///
  /// \param session The current session.
  /// \param path The path of the SNP to check.
  /// \returns The SNP if it exists, otherwise null.
  Future<Snp?> _snpExists(Session session, String path) async {
    session.log("Checking if SNP exists with path: $path",
        level: LogLevel.info);
    var snp = await Snp.db.find(session, where: (t) => t.folder.equals(path));
    return snp.isNotEmpty ? snp.first : null;
  }
}
