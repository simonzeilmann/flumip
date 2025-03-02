import 'package:serverpod/server.dart';

import '../services/file_service.dart';

class FileEndpoint extends Endpoint {
  get fileService => FileService();

  Future<void> createGeneFile(
      Session session, int projectID, List<String> genes) async {
    return fileService.createGeneFile(session, projectID, genes);
  }

  Future<List<String>> getGenes(Session session, int projectID) async {
    return fileService.getGenes(session, projectID);
  }

  Future<bool> checkBedFileExists(Session session, int projectID) async {
    return fileService.checkBedFileExists(session, projectID);
  }

  Future<void> deleteByProducts(Session session, int projectID) async {
    return fileService.deleteByProducts(session, projectID);
  }

  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    return fileService.showSnpMipsResult(session, projectID);
  }

  Future<List<String>> showMipsResult(Session session, int projectID) async {
    return fileService.showMipsResult(session, projectID);
  }

  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    return fileService.showMipsProgress(session, projectID);
  }
}