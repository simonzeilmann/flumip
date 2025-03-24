import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/gene.dart';
import '../services/gene_service.dart';

class GeneEndpoint extends Endpoint {
  get geneService => GeneService();

  Future<Gene> getGene(Session session, int id) async {
    session.log('Retrieving gene with ID: $id', level: LogLevel.info);
    try {
      return geneService.getGene(session, id);
    } catch (e) {
      session.log('Error retrieving gene with ID: $id', level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<List<Gene>> getAllGenes(Session session) async {
    session.log('Retrieving all genes', level: LogLevel.info);
    try {
      return geneService.getAllGenes(session);
    } catch (e) {
      session.log('Error retrieving all genes', level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<void> updateGene(Session session, int id, Gene gene) async {
    session.log('Updating gene with ID: $id', level: LogLevel.info);
    try {
      return geneService.updateGene(session, id, gene);
    } catch (e) {
      session.log('Error updating gene with ID: $id', level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<void> collectGenes(Session session) async {
    session.log('Collecting genes', level: LogLevel.info);
    try {
      return geneService.collectGenes(session);
    } catch (e) {
      session.log('Error collecting genes', level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}