import 'dart:io';
import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/future_calls.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Where `bwa index` output is kept, beside the FASTA it is indexing.
const bwaIndexLogName = 'bwa-index.log';

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
    Session session,
    String category,
  ) async {
    var allGenomes = await getAllGenomes(session);
    var genomes = <Genome>[];
    for (var genome in allGenomes) {
      if (genome.category == category) {
        genomes.add(genome);
      }
    }

    session.log(
      'Genomes retrieved by category: $category',
      level: LogLevel.info,
    );
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
      throw FlumipFileNotFoundException(
        message: 'This genome no longer exists.',
      );
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
      throw FlumipFileNotFoundException(
        message: 'This genome no longer exists.',
      );
    }
    await Genome.db.updateRow(session, genome);
    session.log("Genome updated with ID: $id", level: LogLevel.info);
  }

  /// Collects genomes from the specified directory.
  ///
  /// \param session The current session.
  Future<void> collectGenomes(Session session) async {
    SettingsService settingsService = sl<SettingsService>();

    session.log("Collecting genomes", level: LogLevel.info);
    final settings = await settingsService.getSettings(session);
    var categoryFolder = Directory(settings.genomeDir);

    if (!await categoryFolder.exists()) {
      session.log(
        'Genome directory not found: ${settings.genomeDir}',
        level: LogLevel.error,
      );
      // The path stays in the log rather than the message: an ordinary user
      // sees this one too, it means nothing to them, and it is the first thing
      // the administrator will look at anyway.
      throw FlumipFileNotFoundException(
        message:
            'The genome library is not set up on this server. Ask your '
            'administrator to check the genome directory in Settings.',
      );
    }

    for (var category in categoryFolder.listSync().whereType<Directory>()) {
      for (var genomeFolder in Directory(
        category.path,
      ).listSync().whereType<Directory>()) {
        var existingGenome = await _genomeExists(session, genomeFolder.path);
        if (existingGenome != null) {
          await _processGenomeFolder(session, existingGenome, genomeFolder);
        } else {
          await _createNewGenome(session, category, genomeFolder);
        }
      }
    }

    // Custom SNPs live outside the genome tree, so the scan above cannot see
    // them. Running both from one button means "Collect" keeps meaning "notice
    // whatever is new", which is the only thing anyone using it wants.
    await sl<SnpService>().collectCustomSnps(session);

    session.log("Genome collection completed", level: LogLevel.info);
  }

  /// Processes a genome folder.
  ///
  /// \param session The current session.
  /// \param existingGenome The existing genome data.
  /// \param genomeFolder The genome folder to process.
  Future<void> _processGenomeFolder(
    Session session,
    Genome existingGenome,
    Directory genomeFolder,
  ) async {
    FileService fileService = sl<FileService>();

    session.log(
      "Processing genome folder: ${genomeFolder.path}",
      level: LogLevel.info,
    );
    for (var genomeFile in genomeFolder.listSync().whereType<Directory>()) {
      if (genomeFile.path.endsWith("fa")) {
        var faFilesString = Directory(genomeFile.path).listSync().toString();
        if (_containsFaIndexFiles(faFilesString)) {
          existingGenome.indexed = true;
        } else if (_isIndexing(faFilesString)) {
          existingGenome.indexing = true;
        }
      } else if (genomeFile.path.endsWith("snp")) {
        await _processSnpFolder(session, existingGenome, genomeFile);
      }
    }
    existingGenome.size = await fileService.getDirSize(genomeFolder.path);
    await Genome.db.updateRow(session, existingGenome);
    session.log(
      "Genome folder processed: ${genomeFolder.path}",
      level: LogLevel.info,
    );
  }

  /// Processes an SNP folder.
  ///
  /// \param session The current session.
  /// \param existingGenome The existing genome data.
  /// \param snpFolder The SNP folder to process.
  Future<void> _processSnpFolder(
    Session session,
    Genome existingGenome,
    Directory snpFolder,
  ) async {
    FileService fileService = sl<FileService>();

    session.log(
      "Processing SNP folder: ${snpFolder.path}",
      level: LogLevel.info,
    );
    for (var snpDir in snpFolder.listSync().whereType<Directory>()) {
      var found = SnpService.snpFilesIn(snpDir.listSync());
      if (found.vcf == null || found.tbi == null) continue;

      var existingSnp = await _snpExists(session, snpDir.path);
      if (existingSnp != null) {
        // Already known. Keeping its paths and size in step with the files is
        // `SnpService.collectCustomSnps`' reconcile pass, which runs at the end
        // of this scan and covers globals as well as customs.
        continue;
      }

      await Snp.db.insertRow(
        session,
        Snp(
          name: snpDir.path.split('/').last,
          vcfPath: found.vcf!.path,
          tbiPath: found.tbi!.path,
          folder: snpDir.path,
          genome: existingGenome.id,
          size: await fileService.getDirSize(snpDir.path),
          created: DateTime.now().toUtc(),
        ),
      );
    }
    session.log(
      "SNP folder processed: ${snpFolder.path}",
      level: LogLevel.info,
    );
  }

  /// Creates a new genome from a folder.
  ///
  /// \param session The current session.
  /// \param category The category directory.
  /// \param genomeFolder The genome folder to create the genome from.
  Future<void> _createNewGenome(
    Session session,
    Directory category,
    Directory genomeFolder,
  ) async {
    FileService fileService = sl<FileService>();
    session.log(
      "Creating new genome from folder: ${genomeFolder.path}",
      level: LogLevel.info,
    );
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
          genome.fastaPath = _getFilePath(
            session,
            genomeFile,
            ".fa",
            genome.name,
          );
          if (_containsFaIndexFiles(
            Directory(genomeFile.path).listSync().toString(),
          )) {
            genome.indexed = true;
          }
        } else if (genomeFile.path.endsWith("snp")) {
          genome.snpFolder = genomeFile.path;
          snps.addAll(await _createSnpsFromFolder(session, genomeFile));
        }
      }
    }
    if (genome.refPath != null && genome.fastaPath != null) {
      genome.size = await fileService.getDirSize(genomeFolder.path);
      // The genome goes in first now, because `Snp.genome` is a real foreign key
      // and there is no id to point at until the row exists. The SNP ids are then
      // written back onto it in one update.
      var inserted = await Genome.db.insertRow(session, genome);
      for (var snp in snps) {
        snp.genome = inserted.id;
        await Snp.db.insertRow(session, snp);
      }
    }
    session.log(
      "New genome created from folder: ${genomeFolder.path}",
      level: LogLevel.info,
    );
  }

  /// Creates SNPs from a folder.
  ///
  /// \param session The current session.
  /// \param snpFolder The SNP folder to create SNPs from.
  /// \returns A list of created SNPs.
  Future<List<Snp>> _createSnpsFromFolder(
    Session session,
    Directory snpFolder,
  ) async {
    FileService fileService = sl<FileService>();

    session.log(
      "Creating SNPs from folder: ${snpFolder.path}",
      level: LogLevel.info,
    );
    List<Snp> snps = [];
    for (var snpDir in snpFolder.listSync().whereType<Directory>()) {
      var found = SnpService.snpFilesIn(snpDir.listSync());
      if (found.vcf == null || found.tbi == null) continue;
      snps.add(
        Snp(
          name: snpDir.path.split('/').last,
          vcfPath: found.vcf!.path,
          tbiPath: found.tbi!.path,
          folder: snpDir.path,
          size: await fileService.getDirSize(snpDir.path),
          created: DateTime.now().toUtc(),
        ),
      );
    }
    session.log(
      "SNPs created from folder: ${snpFolder.path}",
      level: LogLevel.info,
    );
    return snps;
  }

  /// Checks if the specified files string contains FA index files.
  ///
  /// \param filesString The string containing file names.
  /// \returns A boolean indicating if the string contains FA files.
  bool _containsFaIndexFiles(String filesString) {
    return filesString.contains(".fa.amb") &&
        filesString.contains(".fa.pac") &&
        filesString.contains(".fa.sa") &&
        filesString.contains(".fa.bwt") &&
        filesString.contains(".fa.ann");
  }

  bool _isIndexing(String filesString) {
    return filesString.contains(".fa.amb") ||
        filesString.contains(".fa.pac") ||
        filesString.contains(".fa.sa") ||
        filesString.contains(".fa.bwt") ||
        filesString.contains(".fa.ann");
  }

  /// Gets the file path with the specified extension from a directory.
  ///
  /// ⚠️ The refusal names the **genome**, not [dir]. This used to report
  /// `No ".fa" file found in /opt/flumip/data/genomes/…/fa`, and a scan is
  /// started from the genome tab by anybody — so a server filesystem path went
  /// to a user who can do nothing with it. The path is logged instead, which is
  /// where the administrator who can fix it will look.
  ///
  /// \param session The current session, for the log.
  /// \param dir The directory to search in.
  /// \param extension The file extension to look for.
  /// \param genomeName The genome this directory belongs to.
  /// \returns The file path with the specified extension.
  String _getFilePath(
    Session session,
    Directory dir,
    String extension,
    String genomeName,
  ) {
    return dir
        .listSync()
        .firstWhere(
          (file) => file.path.endsWith(extension),
          orElse: () {
            session.log(
              'No "$extension" file found in ${dir.path}',
              level: LogLevel.error,
            );
            throw FlumipFileNotFoundException(
              message:
                  'The genome "$genomeName" has no "$extension" file where one '
                  'is expected. Ask your administrator to check the genome '
                  'library.',
            );
          },
        )
        .path;
  }

  /// Indexes the FASTA file for a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to index.
  Future<void> indexFasta(Session session, int id) async {
    ProcessService processService = sl<ProcessService>();

    session.log("Indexing Fasta for genome with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    // ⚠️ Four states, four sentences. These were four bare `ArgumentError()`s
    // with no message at all, which Serverpod cannot serialize — the browser got
    // "Internal Server Error" and the reason stayed in the log.
    if (genome == null) {
      session.log(
        "Invalid genome state for indexing with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'This genome no longer exists.');
    }
    if (genome.indexed) {
      session.log("Genome already indexed with ID: $id", level: LogLevel.error);
      throw ArgumentException(
        message:
            'The genome "${genome.name}" is already indexed. Remove the index '
            'first if you want to build it again.',
      );
    }
    if (genome.indexing) {
      session.log(
        "Genome already indexing with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'The genome "${genome.name}" is already being indexed.',
      );
    }
    if (genome.fastaPath == null) {
      session.log(
        "Genome has no FASTA file with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message:
            'The genome "${genome.name}" has no sequence file on this server, '
            'so there is nothing to index. Ask your administrator to re-scan '
            'the genome library.',
      );
    }

    await sl<ProcessRunner>().start(
      "bwa",
      ["index", genome.fastaPath!],
      workingDirectory: "${genome.path}/fa",
      runInShell: true,
      // ⚠️ Same reasoning as mipgen's log. An index build takes hours and can
      // fail on a truncated FASTA or a full disk; without this, bwa's
      // explanation went into a pipe nobody read and the genome simply sat at
      // `indexing` forever with nothing to look at.
      outputPath: "${genome.path}/fa/$bwaIndexLogName",
    );
    genome.indexing = true;
    genome.indexPID = await processService.getProcessPID(
      session,
      "bwa",
      genome.fastaPath!,
    );
    await Genome.db.updateRow(session, genome);
    await scheduleIndexProgressCheck(session, genome);
    session.log(
      "Indexing started for genome with ID: $id",
      level: LogLevel.info,
    );
  }

  /// Schedules a delayed future call that polls the BWA index progress for
  /// [genome]. Used both to start polling and to reschedule the next check.
  Future<void> scheduleIndexProgressCheck(
    Session session,
    Genome genome,
  ) async {
    await session.serverpod.futureCalls
        .callWithDelay(const Duration(minutes: 1))
        .checkIndexProgress
        .run(genome);
  }

  /// Marks the indexing as finished for a genome.
  ///
  /// \param session The current session.
  /// \param object The genome object.
  Future<void> indexIsFinished(Session session, Genome object) async {
    session.log(
      "Indexing finished for genome with ID: ${object.id}",
      level: LogLevel.info,
    );
    // ⚠️ This method must reach the writes below whatever it finds, because it
    // is the *only* thing that clears `indexing`. Throwing here — on a genome
    // with no path, or a directory that has since gone — would leave the row
    // reading "indexing" forever with no poller left to resolve it, which looks
    // to the user like a build that never ends. So a missing directory is
    // treated the same way as a directory without index files in it: not
    // indexed, and done.
    //
    // `path` is nullable and was previously concatenated with `+`, which threw
    // on null rather than reporting it.
    var faFilesString = '';
    final path = object.path;
    if (path == null) {
      session.log(
        "Genome ${object.id} has no path; recording it as not indexed.",
        level: LogLevel.warning,
      );
    } else {
      try {
        faFilesString = Directory('$path/fa').listSync().toString();
      } on FileSystemException catch (e) {
        session.log(
          "Could not list '$path/fa' for genome ${object.id}; recording it as "
          "not indexed.",
          level: LogLevel.warning,
          exception: e,
        );
      }
    }
    if (_containsFaIndexFiles(faFilesString)) {
      object.indexed = true;
      object.indexResults = 0;
    } else {
      object.indexed = false;
      object.indexResults = 1;
    }

    object.indexing = false;
    object.indexPID = 0;
    await Genome.db.updateRow(session, object);
    session.log(
      "Indexing marked as finished for genome with ID: ${object.id}",
      level: LogLevel.info,
    );
  }

  /// Deletes the FASTA index for a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to delete the index for.
  Future<void> deleteFastaIndex(Session session, int id) async {
    session.log("Deleting index for genome with ID: $id", level: LogLevel.info);
    var genome = await Genome.db.findById(session, id);
    // Split apart for the same reason as `indexFasta` above: one bare
    // `ArgumentError()` covering three states reached the user as
    // "Internal Server Error", and the three have different answers.
    if (genome == null) {
      session.log(
        "Genome not found for deleting index with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(message: 'This genome no longer exists.');
    }
    if (genome.indexing) {
      session.log(
        "Genome still indexing, cannot delete index with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message:
            'The genome "${genome.name}" is still being indexed. Wait for it '
            'to finish before removing the index.',
      );
    }
    if (!genome.indexed) {
      session.log(
        "Genome is not indexed, nothing to delete with ID: $id",
        level: LogLevel.error,
      );
      throw ArgumentException(
        message: 'The genome "${genome.name}" has no index to remove.',
      );
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
      throw FlumipFileNotFoundException(
        message: 'This SNP set no longer exists.',
      );
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
  /// Reads `Snp.genome`, which is the authoritative link, rather than walking
  /// `Genome.snp`. That list is a denormalised copy: it is not maintained for
  /// custom SNPs, it strands an SNP whose genome row was deleted and rediscovered,
  /// and dereferencing it used to be a `genome.snp!` that crashed outright for any
  /// genome that had never had one.
  ///
  /// Not visibility-filtered — that is the caller's job, and `SnpEndpoint`
  /// does it. Nothing here should decide policy.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of SNPs for the specified genome.
  Future<List<Snp>> getAllSnpForGenome(Session session, int genomeId) async {
    session.log(
      "Retrieving all SNPs for genome with ID: $genomeId",
      level: LogLevel.info,
    );
    var genome = await Genome.db.findById(session, genomeId);
    if (genome == null) {
      session.log("Genome not found with ID: $genomeId", level: LogLevel.error);
      throw FlumipFileNotFoundException(
        message: 'This genome no longer exists.',
      );
    }
    // ⚠️ Ordered, and this is a bug fix rather than tidiness. Without an
    // `orderBy` Postgres returns heap order, and an UPDATE rewrites the row at
    // the end of the heap — so flipping an SNP's sharing, or a download bumping
    // `bytesDownloaded`, moved that row to the bottom of the list under the
    // user's cursor. By id, so the order is the one they were added in.
    return Snp.db.find(
      session,
      where: (t) => t.genome.equals(genomeId),
      orderBy: (t) => t.id,
    );
  }

  /// Checks if a genome exists by its path.
  ///
  /// \param session The current session.
  /// \param path The path of the genome to check.
  /// \returns The genome if it exists, otherwise null.
  Future<Genome?> _genomeExists(Session session, String path) async {
    session.log(
      "Checking if genome exists with path: $path",
      level: LogLevel.info,
    );
    var genome = await Genome.db.find(
      session,
      where: (t) => t.path.equals(path),
    );
    return genome.isNotEmpty ? genome.first : null;
  }

  /// Checks if an SNP exists by its path.
  ///
  /// \param session The current session.
  /// \param path The path of the SNP to check.
  /// \returns The SNP if it exists, otherwise null.
  Future<Snp?> _snpExists(Session session, String path) async {
    session.log(
      "Checking if SNP exists with path: $path",
      level: LogLevel.info,
    );
    var snp = await Snp.db.find(session, where: (t) => t.folder.equals(path));
    return snp.isNotEmpty ? snp.first : null;
  }
}
