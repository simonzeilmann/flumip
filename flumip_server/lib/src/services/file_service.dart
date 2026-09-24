import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import 'dart:io';

import 'package:archive/archive_io.dart';

/// A service class for handling file-related operations.
class FileService {
  FileService();

  /// Creates a gene file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \param genes The list of genes to write to the file.
  /// \throws [FlumipFileNotFoundException] if the project directory or project ID does not exist.
  Future<void> createGeneFile(
    Session session,
    int projectID,
    List<String> genes,
  ) async {
    SettingsService settingsService = sl<SettingsService>();

    session.log(
      "Starting createGeneFile for project ID: $projectID",
      level: LogLevel.info,
    );
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log(
        "Project directory does not exist for project ID: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message:
            'This project has no files on the server. It may never have been '
            'run, or its folder may have been removed.',
      );
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project ID does not exist: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    var settings = await settingsService.getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    if (await File(geneFile).exists()) {
      session.log(
        "Gene file exists, writing to: $geneFile",
        level: LogLevel.info,
      );
      await _writeListToFile(session, geneFile, genes);
    } else {
      session.log(
        "Gene file does not exist, creating: $geneFile",
        level: LogLevel.info,
      );
      await _writeListToFile(session, geneFile, genes);
    }
    session.log(
      "Gene file created successfully for project ID: $projectID",
      level: LogLevel.info,
    );
  }

  /// Checks if the BED file exists for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A boolean indicating whether the BED file exists and is larger than 1024 bytes.
  /// \throws [FlumipFileNotFoundException] if the project directory or project ID does not exist.
  Future<bool> checkBedFileExists(Session session, int projectID) async {
    SettingsService settingsService = sl<SettingsService>();

    session.log(
      "Checking if BED file exists for project ID: $projectID",
      level: LogLevel.info,
    );
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log(
        "Project directory does not exist for project ID: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project ID does not exist: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    var settings = await settingsService.getSettings(session);
    if (await File(
          "${settings.projectDir}/${project.folderName}/genes.bed",
        ).exists() &&
        await File(
              "${settings.projectDir}/${project.folderName}/genes.bed",
            ).length() >
            1024) {
      session.log(
        "BED file exists and is larger than 1024 bytes for project ID: $projectID",
        level: LogLevel.info,
      );
      return true;
    }
    session.log(
      "BED file does not exist or is smaller than 1024 bytes for project ID: $projectID",
      level: LogLevel.info,
    );
    return false;
  }

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// ⚠️ **[FlumipFileNotFoundException], not Serverpod's own
  /// `FileNotFoundException`** — and every throw in this file is the same, for a
  /// reason that is invisible from the server. `serverpod_client` does not ship
  /// `FileNotFoundException`, so the app cannot deserialize it: the sentence
  /// written here was thrown away and the user was shown
  /// *"FormatException: No deserialization found for type named
  /// serverpod.FileNotFoundException"* instead. Measured, not guessed.
  ///
  /// \throws [FlumipFileNotFoundException] if the project directory or project ID does not exist.
  Future<void> deleteByproducts(Session session, int projectID) async {
    session.log(
      "Starting deleteByproducts for project ID: $projectID",
      level: LogLevel.info,
    );
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log(
        "Project directory does not exist for project ID: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project ID does not exist: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    List<FileSystemEntity> dir = await _getFileList(session, projectID);
    for (var d in dir) {
      if (d.path.endsWith(".sai") || d.path.endsWith(".fq")) {
        session.log("Deleting byproduct file: ${d.path}", level: LogLevel.info);
        // ⚠️ Awaited. Without it this reported "byproducts deleted
        // successfully" before they were, and a delete that failed — a
        // permission problem, a file still held open — surfaced as an unhandled
        // async error rather than as this method failing.
        await d.delete();
      }
    }
    session.log(
      "Byproducts deleted successfully for project ID: $projectID",
      level: LogLevel.info,
    );
  }

  /// Deletes the gene file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \throws [FlumipFileNotFoundException] if the project ID does not exist.
  Future<void> deleteGeneFile(Session session, int projectID) async {
    SettingsService settingsService = sl<SettingsService>();

    session.log(
      "Starting deleteGeneFile for project ID: $projectID",
      level: LogLevel.info,
    );
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project ID does not exist: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    var settings = await settingsService.getSettings(session);

    if (await File(
      "${settings.projectDir}/${project.folderName}/genes.txt",
    ).exists()) {
      session.log(
        "Deleting gene file: ${settings.projectDir}/${project.folderName}/genes.txt",
        level: LogLevel.info,
      );
      await File(
        "${settings.projectDir}/${project.folderName}/genes.txt",
      ).delete();
    }
    session.log(
      "Gene file deleted successfully for project ID: $projectID",
      level: LogLevel.info,
    );
  }

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    session.log(
      "Showing SNP MIPs result for project ID: $projectID",
      level: LogLevel.info,
    );
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".snp_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log(
          "SNP MIPs result found for project ID: $projectID",
          level: LogLevel.info,
        );
        return lines;
      }
    }

    session.log(
      "No SNP MIPs result found for project ID: $projectID",
      level: LogLevel.info,
    );
    return List.empty();
  }

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  Future<List<String>> showMipsResult(Session session, int projectID) async {
    session.log(
      "Showing MIPs result for project ID: $projectID",
      level: LogLevel.info,
    );
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".picked_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log(
          "MIPs result found for project ID: $projectID",
          level: LogLevel.info,
        );
        return lines;
      }
    }

    session.log(
      "No MIPs result found for project ID: $projectID",
      level: LogLevel.warning,
    );
    return List.empty();
  }

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    session.log(
      "Showing MIPs progress for project ID: $projectID",
      level: LogLevel.info,
    );
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".progress.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log(
          "MIPs progress found for project ID: $projectID",
          level: LogLevel.info,
        );
        return lines;
      }
    }

    session.log(
      "No MIPs progress found for project ID: $projectID",
      level: LogLevel.warning,
    );
    return List.empty();
  }

  Future<List<String>> showUSCSTrack(Session session, int projectID) async {
    session.log(
      "Showing USCSTrack for project ID: $projectID",
      level: LogLevel.info,
    );
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".ucsc_track.bed")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log(
          "USCS track found for project ID: $projectID",
          level: LogLevel.info,
        );
        return lines;
      }
    }

    session.log(
      "No USCS track found for project ID: $projectID",
      level: LogLevel.warning,
    );
    return List.empty();
  }

  // `returnFile` used to live here: a suffix-matching reader that streamed any
  // project file whose path merely *ended* with the requested name, with no
  // traversal guard of any kind. It was superseded by `resolveProjectFile` plus
  // the `/download/...` route, and nothing has called it since — but leaving a
  // guardless reader lying about invites somebody to reach for it believing it
  // is the safe one. Use `resolveProjectFile`.

  Future<String> readFileAsString(
    Session session,
    int projectID,
    String fileName,
  ) async {
    session.log(
      "Reading file $fileName as string for project ID: $projectID",
      level: LogLevel.info,
    );
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(fileName)) {
        File f = File(d.path);
        String content = await f.readAsString();
        session.log(
          "File $fileName read as string for project ID: $projectID",
          level: LogLevel.info,
        );
        return content;
      }
    }

    session.log(
      "No file $fileName found for project ID: $projectID",
      level: LogLevel.warning,
    );
    return '';
  }

  /// Checks if the project directory exists for the specified project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \returns A boolean indicating whether the project directory exists.
  /// \throws [FlumipFileNotFoundException] if the project is not found.
  Future<bool> _checkProjectDirectoryExists(Session session, int id) async {
    SettingsService settingsService = sl<SettingsService>();

    session.log(
      "Checking if project directory exists for project ID: $id",
      level: LogLevel.info,
    );
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log(
        "Project not found for project ID: $id",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    var settings = await settingsService.getSettings(session);
    return await Directory(
      "${settings.projectDir}/${project.folderName}",
    ).exists();
  }

  /// Retrieves the list of files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of [FileSystemEntity] objects representing the files in the project directory.
  /// \throws [FlumipFileNotFoundException] if the project is not found.
  Future<List<FileSystemEntity>> _getFileList(
    Session session,
    int projectID,
  ) async {
    SettingsService settingsService = sl<SettingsService>();
    session.log(
      "Getting file list for project ID: $projectID",
      level: LogLevel.info,
    );
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project not found for project ID: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }

    var settings = await settingsService.getSettings(session);
    var dir = await Directory(
      "${settings.projectDir}/${project.folderName}",
    ).list().toList();
    session.log(
      "File list retrieved for project ID: $projectID",
      level: LogLevel.info,
    );
    return dir;
  }

  /// Writes a list of strings to a file.
  ///
  /// \param session The current session.
  /// \param path The path of the file to write to.
  /// \param list The list of strings to write to the file.
  Future<void> _writeListToFile(
    Session session,
    String path,
    List<String> list,
  ) async {
    session.log("Writing list to file: $path", level: LogLevel.info);
    var sink = File(path).openWrite();
    list.forEach(sink.writeln);
    await sink.flush();
    await sink.close();
    session.log("List written to file: $path", level: LogLevel.info);
  }

  /// Writes a string to a file.
  ///
  /// \param session The current session.
  /// \param path The path of the file to write to.
  /// \param content The string content to write to the file.
  Future<void> writeStringToFile(
    Session session,
    String path,
    String content,
  ) async {
    session.log("Writing string to file: $path", level: LogLevel.info);
    var sink = File(path).openWrite();
    sink.write(content);
    await sink.flush();
    await sink.close();
    session.log("String written to file: $path", level: LogLevel.info);
  }

  /// Retrieves the size of a directory.
  ///
  /// \param dirPath The path of the directory.
  /// \returns The size of the directory in bytes.
  Future<int> getDirSize(String dirPath) async {
    var dir = Directory(dirPath);
    bool exists = await dir.exists();
    if (!exists) {
      return 0;
    }

    int totalSize = 0;
    // `await for`, not `forEach` with an async callback. The callback version
    // returned as soon as the stream was drained, before its bodies had all run,
    // so the total was whatever happened to have been added by then — a different
    // number on every call for a large tree. Latent while this only fed a display
    // figure; it now decides a per-SNP size.
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// The directory holding a project's files.
  ///
  /// Throws [FlumipFileNotFoundException] for an unknown project, matching what the
  /// rest of this service does for a bad id.
  Future<Directory> projectDirectory(Session session, int projectID) async {
    final project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log(
        "Project not found for project ID: $projectID",
        level: LogLevel.error,
      );
      throw FlumipFileNotFoundException(
        message: 'This project no longer exists.',
      );
    }
    final settings = await sl<SettingsService>().getSettings(session);
    return Directory('${settings.projectDir}/${project.folderName}');
  }

  /// Every file a project has produced, newest-looking name order, with sizes.
  ///
  /// Flat rather than recursive: mipgen writes into the project directory
  /// itself, and a recursive walk would invite a download URL that escapes it.
  /// Directories are skipped rather than descended for the same reason.
  ///
  /// An absent directory yields an empty list, not an error — a project whose
  /// generation never ran simply has nothing to download.
  Future<List<({String name, int sizeBytes})>> listProjectFiles(
    Session session,
    int projectID,
  ) async {
    final dir = await projectDirectory(session, projectID);
    if (!await dir.exists()) return const [];

    final files = <({String name, int sizeBytes})>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      files.add((name: name, sizeBytes: await entity.length()));
    }
    files.sort((a, b) => a.name.compareTo(b.name));
    return files;
  }

  /// Resolves [fileName] inside the project directory, or null.
  ///
  /// ⚠️ **The traversal guard.** [fileName] arrives from a URL, so it is
  /// rejected outright unless it is a bare name: anything containing a path
  /// separator, or `..`, or an absolute path, cannot be resolved. The resolved
  /// path is then checked to be inside the project directory, so a symlink
  /// planted in the directory cannot point out of it either.
  ///
  /// Returns null rather than throwing for anything not found, so the caller can
  /// answer one indistinguishable 404 — a probe must not be able to tell a
  /// rejected name from a missing file.
  Future<File?> resolveProjectFile(
    Session session,
    int projectID,
    String fileName,
  ) async {
    if (fileName.isEmpty ||
        fileName == '.' ||
        fileName == '..' ||
        fileName.contains('/') ||
        fileName.contains(r'\')) {
      session.log(
        'Refused a download name that is not a bare file name, for project '
        '$projectID',
        level: LogLevel.warning,
      );
      return null;
    }

    final dir = await projectDirectory(session, projectID);
    if (!await dir.exists()) return null;

    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) return null;

    // Resolve symlinks on both sides before comparing, so the containment check
    // is about where the bytes actually are.
    final resolved = await file.resolveSymbolicLinks();
    final root = await dir.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      session.log(
        'Refused a download resolving outside project $projectID',
        level: LogLevel.warning,
      );
      return null;
    }
    return file;
  }

  /// Zips every file of a project into a temp file and returns it.
  ///
  /// The caller owns the result and must delete it once streamed. Written to
  /// disk rather than built in memory: a project directory can be gigabytes, and
  /// an in-memory archive would need it twice over.
  ///
  /// Null when the project has no files, so the caller can 404 rather than hand
  /// back an empty archive that looks like a broken download.
  Future<File?> zipProjectFiles(Session session, int projectID) async {
    final files = await listProjectFiles(session, projectID);
    if (files.isEmpty) return null;

    final dir = await projectDirectory(session, projectID);
    final target = File(
      '${Directory.systemTemp.path}/flumip-project-$projectID-'
      '${DateTime.now().microsecondsSinceEpoch}.zip',
    );

    final encoder = ZipFileEncoder();
    encoder.create(target.path);
    try {
      for (final entry in files) {
        await encoder.addFile(File('${dir.path}/${entry.name}'));
      }
    } finally {
      await encoder.close();
    }

    session.log(
      'Zipped ${files.length} file(s) for project $projectID',
      level: LogLevel.info,
    );
    return target;
  }
}
