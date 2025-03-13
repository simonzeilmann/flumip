import 'dart:typed_data';

import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import 'dart:io';

import '../generated/protocol.dart';
import 'project_service.dart';

/// A service class for handling file-related operations.
class FileService {
  final projectService = ProjectService();
  final settingsService = SettingsService();

  FileService();

  /// Creates a gene file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \param genes The list of genes to write to the file.
  /// \throws [ArgumentError] if the project directory or project ID does not exist.
  Future<void> createGeneFile(
      Session session, int projectID, List<String> genes) async {
    session.log("Starting createGeneFile for project ID: $projectID",
        level: LogLevel.info);
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log("Project directory does not exist for project ID: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project directory does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log("Project ID does not exist: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    var settings = await settingsService.getSettings(session);

    String geneFile = "${settings.projectDir}/${project.folderName}/genes.txt";
    if (await File(geneFile).exists()) {
      session.log("Gene file exists, writing to: $geneFile",
          level: LogLevel.info);
      await _writeListToFile(session, geneFile, genes);
    } else {
      session.log("Gene file does not exist, creating: $geneFile",
          level: LogLevel.info);
      File(geneFile).create();
      await _writeListToFile(session, geneFile, genes);
    }
    session.log("Gene file created successfully for project ID: $projectID",
        level: LogLevel.info);
  }

  /// Checks if the BED file exists for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A boolean indicating whether the BED file exists and is larger than 1024 bytes.
  /// \throws [ArgumentError] if the project directory or project ID does not exist.
  Future<bool> checkBedFileExists(Session session, int projectID) async {
    session.log("Checking if BED file exists for project ID: $projectID",
        level: LogLevel.info);
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log("Project directory does not exist for project ID: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log("Project ID does not exist: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    var settings = await settingsService.getSettings(session);
    if (await File("${settings.projectDir}/${project.folderName}/genes.bed")
            .exists() &&
        await File("${settings.projectDir}/${project.folderName}/genes.bed")
                .length() >
            1024) {
      session.log(
          "BED file exists and is larger than 1024 bytes for project ID: $projectID",
          level: LogLevel.info);
      return true;
    }
    session.log(
        "BED file does not exist or is smaller than 1024 bytes for project ID: $projectID",
        level: LogLevel.info);
    return false;
  }

  /// Deletes byproduct files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \throws [FileNotFoundException] if the project directory or project ID does not exist.
  Future<void> deleteByproducts(Session session, int projectID) async {
    session.log("Starting deleteByproducts for project ID: $projectID",
        level: LogLevel.info);
    if (!await _checkProjectDirectoryExists(session, projectID)) {
      session.log("Project directory does not exist for project ID: $projectID",
          level: LogLevel.error);
      throw FileNotFoundException(message: 'The Project does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log("Project ID does not exist: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }

    List<FileSystemEntity> dir = await _getFileList(session, projectID);
    for (var d in dir) {
      if (d.path.endsWith(".sai") || d.path.endsWith(".fq")) {
        session.log("Deleting byproduct file: ${d.path}", level: LogLevel.info);
        d.delete();
      }
    }
    session.log("Byproducts deleted successfully for project ID: $projectID",
        level: LogLevel.info);
  }

  /// Deletes the gene file for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \throws [ArgumentError] if the project ID does not exist.
  Future<void> deleteGeneFile(Session session, int projectID) async {
    session.log("Starting deleteGeneFile for project ID: $projectID",
        level: LogLevel.info);
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log("Project ID does not exist: $projectID",
          level: LogLevel.error);
      throw ArgumentError('Project id does not exist');
    }
    var settings = await settingsService.getSettings(session);

    if (await File("${settings.projectDir}/${project.folderName}/genes.txt")
        .exists()) {
      session.log(
          "Deleting gene file: ${settings.projectDir}/${project.folderName}/genes.txt",
          level: LogLevel.info);
      await File("${settings.projectDir}/${project.folderName}/genes.txt")
          .delete();
    }
    session.log("Gene file deleted successfully for project ID: $projectID",
        level: LogLevel.info);
  }

  /// Shows the SNP MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the SNP MIPs result.
  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    session.log("Showing SNP MIPs result for project ID: $projectID",
        level: LogLevel.info);
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".snp_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log("SNP MIPs result found for project ID: $projectID",
            level: LogLevel.info);
        return lines;
      }
    }

    session.log("No SNP MIPs result found for project ID: $projectID",
        level: LogLevel.info);
    return List.empty();
  }

  /// Shows the MIPs result for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs result.
  Future<List<String>> showMipsResult(Session session, int projectID) async {
    session.log("Showing MIPs result for project ID: $projectID",
        level: LogLevel.info);
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".picked_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log("MIPs result found for project ID: $projectID",
            level: LogLevel.info);
        return lines;
      }
    }

    session.log("No MIPs result found for project ID: $projectID",
        level: LogLevel.warning);
    return List.empty();
  }

  /// Shows the MIPs progress for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of strings containing the MIPs progress.
  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    session.log("Showing MIPs progress for project ID: $projectID",
        level: LogLevel.info);
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".progress.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log("MIPs progress found for project ID: $projectID",
            level: LogLevel.info);
        return lines;
      }
    }

    session.log("No MIPs progress found for project ID: $projectID",
        level: LogLevel.warning);
    return List.empty();
  }

  Future<List<String>> showUSCSTrack(Session session, int projectID) async {
    session.log("Showing USCSTrack for project ID: $projectID",
        level: LogLevel.info);
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".ucsc_track.bed")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        session.log("USCS track found for project ID: $projectID",
            level: LogLevel.info);
        return lines;
      }
    }

    session.log("No USCS track found for project ID: $projectID",
        level: LogLevel.warning);
    return List.empty();
  }

  Future<ByteData> returnFile(Session session, int projectID, String fileName) async {
    session.log("Returning file $fileName for project ID: $projectID",
        level: LogLevel.info);
    List<FileSystemEntity> dir = await _getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(fileName)) {
        File f = File(d.path);
        var bytes = await f.readAsBytes();
        session.log("File $fileName found for project ID: $projectID",
            level: LogLevel.info);
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      }
    }

    session.log("No file $fileName found for project ID: $projectID",
        level: LogLevel.warning);
    return ByteData.view(Uint8List(0).buffer);
  }

  /// Checks if the project directory exists for the specified project.
  ///
  /// \param session The current session.
  /// \param id The ID of the project.
  /// \returns A boolean indicating whether the project directory exists.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<bool> _checkProjectDirectoryExists(Session session, int id) async {
    session.log("Checking if project directory exists for project ID: $id",
        level: LogLevel.info);
    var project = await Project.db.findById(session, id);
    if (project == null) {
      session.log("Project not found for project ID: $id",
          level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }

    var settings = await settingsService.getSettings(session);
    return await Directory("${settings.projectDir}/${project.folderName}")
        .exists();
  }

  /// Retrieves the list of files for the specified project.
  ///
  /// \param session The current session.
  /// \param projectID The ID of the project.
  /// \returns A list of [FileSystemEntity] objects representing the files in the project directory.
  /// \throws [FileNotFoundException] if the project is not found.
  Future<List<FileSystemEntity>> _getFileList(
      Session session, int projectID) async {
    session.log("Getting file list for project ID: $projectID",
        level: LogLevel.info);
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      session.log("Project not found for project ID: $projectID",
          level: LogLevel.error);
      throw FileNotFoundException(message: 'Project not found');
    }

    var settings = await settingsService.getSettings(session);
    var dir = await Directory("${settings.projectDir}/${project.folderName}")
        .list()
        .toList();
    session.log("File list retrieved for project ID: $projectID",
        level: LogLevel.info);
    return dir;
  }

  /// Writes a list of strings to a file.
  ///
  /// \param session The current session.
  /// \param path The path of the file to write to.
  /// \param list The list of strings to write to the file.
  Future<void> _writeListToFile(
      Session session, String path, List<String> list) async {
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
      Session session, String path, String content) async {
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
    await dir.list(recursive: true, followLinks: false).forEach((FileSystemEntity entity) async {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    });

    return totalSize;
  }
}
