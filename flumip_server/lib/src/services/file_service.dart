import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';
import 'dart:io';

import '../generated/protocol.dart';
import 'project_service.dart';

class FileService {
  late final String _path;
  final projectService = ProjectService();

  FileService() {
    _path = "/opt/mipgen";
  }

  Future<void> createGeneFile(
      Session session, int projectID, List<String> genes) async {
    if (!await checkProjectDirectoryExists(session, projectID)) {
      throw ArgumentError('Project directory does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      throw ArgumentError('Project id does not exist');
    }
    String geneFile = "$_path/projects/${project.folderName}/genes.txt";
    if (await File(geneFile).exists()) {
      await writeListToFile(geneFile, genes);
    } else {
      File(geneFile).create();
      await writeListToFile(geneFile, genes);
    }
  }

  Future<bool> checkBedFileExists(Session session, int projectID) async {
    if (!await checkProjectDirectoryExists(session, projectID)) {
      throw ArgumentError('Project id does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      throw ArgumentError('Project id does not exist');
    }
    if (await File("$_path/projects/${project.folderName}/genes.bed")
            .exists() &&
        await File("$_path/projects/${project.folderName}/genes.bed").length() >
            1024) {
      return true;
    }
    return false;
  }

  Future<void> deleteByproducts(Session session, int projectID) async {
    if (!await checkProjectDirectoryExists(session, projectID)) {
      throw FileNotFoundException(message: 'The Project does not exist');
    }
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      throw ArgumentError('Project id does not exist');
    }

    List<FileSystemEntity> dir = await getFileList(session, projectID);
    for (var d in dir) {
      if (d.path.endsWith(".sai") || d.path.endsWith(".fq")) {
        d.delete();
      }
    }
  }

  Future<void> deleteGeneFile(Session session, int projectID) async {
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      throw ArgumentError('Project id does not exist');
    }
    if (await File("$_path/projects/${project.folderName}/genes.txt")
        .exists()) {
      await File("$_path/projects/${project.folderName}/genes.txt").delete();
    }
  }

  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    List<FileSystemEntity> dir = await getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".snp_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        return lines;
      }
    }

    return List.empty();
  }

  Future<List<String>> showMipsResult(Session session, int projectID) async {
    List<FileSystemEntity> dir = await getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".picked_mips.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        return lines;
      }
    }

    return List.empty();
  }

  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    List<FileSystemEntity> dir = await getFileList(session, projectID);

    for (var d in dir) {
      if (d.path.endsWith(".progress.txt")) {
        File f = File(d.path);
        var lines = await f.readAsLines();
        return lines;
      }
    }

    return List.empty();
  }

  Future<bool> checkProjectDirectoryExists(Session session, int id) async {
    var project = await Project.db.findById(session, id);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    }
    return await Directory("$_path/projects/${project.folderName}").exists();
  }

  Future<List<FileSystemEntity>> getFileList(
      Session session, int projectID) async {
    var project = await Project.db.findById(session, projectID);
    if (project == null) {
      throw FileNotFoundException(message: 'Project not found');
    }
    var dir = await Directory("$_path/projects/${project.folderName}")
        .list()
        .toList();
    return dir;
  }

  Future<void> writeListToFile(String path, List<String> list) async {
    var sink = File(path).openWrite();
    list.forEach(sink.writeln);
    await sink.flush();
    await sink.close();
  }

  Future<void> writeStringToFile(String path, String content) async {
    var sink = File(path).openWrite();
    sink.write(content);
    await sink.flush();
    await sink.close();
  }
}
