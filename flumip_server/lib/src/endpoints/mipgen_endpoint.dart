import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/serverpod.dart';

class MipgenEndpoint extends Endpoint {
  get mipgenService => MipgenService();

  Future<void> createBedFile(Session session, int projectID) async {
    try {
      return mipgenService.createBedFile(session, projectID);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> generateMips(
      Session session, int projectID, bool deleteExcessFiles) async {
    try {
      return mipgenService.generateMips(session, projectID, deleteExcessFiles);
    } catch (e) {
      rethrow;
    }
  }
}
