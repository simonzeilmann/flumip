import 'dart:io';

import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/serverpod.dart';

class MipgenEndpoint extends Endpoint {
  get mipgenService => MipgenService();

  // You create methods in your endpoint which are accessible from the client by
  // creating a public method with `Session` as its first parameter.
  // `bool`, `int`, `double`, `String`, `UuidValue`, `Duration`, `DateTime`, `ByteData`,
  // and other serializable classes, exceptions and enums from your from your `protocol` directory.
  // The methods should return a typed future; the same types as for the parameters are
  // supported. The `session` object provides access to the database, logging,
  // passwords, and information about the request being made to the server.
  Future<bool> createProject(Session session, String name) async {
    return mipgenService.createProject(name);
  }

  Future<void> deleteProject(Session session, String name) async {
    mipgenService.deleteProject(name);
  }

  Future<List<String>> getProjects(Session session) async {
    return mipgenService.getProjects();
  }

  Future<void> createGeneFile(
      Session session, String projectName, List<String> genes) async {
    return mipgenService.createGeneFile(projectName, genes);
  }

  Future<List<String>> getGenes(Session session, String projectName) async {
    try {
      return await mipgenService.getGenes(projectName);
    } on FileNotFoundException {
      rethrow;
    }
  }

  Future<void> createBedFile(Session session, int projectID) async {
    try {
      return mipgenService.createBedFile(session, projectID);
    } on FileNotFoundException catch (e) {
      throw IOException;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkBedFileExists(Session session, String projectName) async {
    return mipgenService.checkBedFileExists(projectName);
  }

  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    return mipgenService.generateMips(session, projectID, deleteExcessFiles);
  }

  Future<List<String>> showMipsProgress(
      Session session, String projectName) async {
    return mipgenService.showMipsProgress(projectName);
  }

  Future<List<String>> showMipsResult(
      Session session, String projectName) async {
    return mipgenService.showMipsResult(projectName);
  }
}
