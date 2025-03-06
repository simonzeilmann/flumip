import 'package:serverpod/server.dart';

import '../services/file_service.dart';

class FileEndpoint extends Endpoint {
  get fileService => FileService();

  Future<void> deleteByProducts(Session session, int projectID) async {
    try {
      return fileService.deleteByProducts(session, projectID);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> showSnpMipsResult(Session session, int projectID) async {
    try {
      return fileService.showSnpMipsResult(session, projectID);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> showMipsResult(Session session, int projectID) async {
    try {
      return fileService.showMipsResult(session, projectID);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> showMipsProgress(Session session, int projectID) async {
    try {
      return fileService.showMipsProgress(session, projectID);
    } catch (e) {
      rethrow;
    }
  }
}