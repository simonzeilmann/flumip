import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/gene.dart';

class GeneService {
  GeneService();

  final settingsService = SettingsService();

  Future<Gene> getGene(Session session, int id) async {
    var gene = await Gene.db.findById(session, id);
    if (gene == null) {
      session.log("Gene not found with ID: $id", level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene not found');
    }
    session.log("Gene retrieved with ID: $id", level: LogLevel.info);
    return gene;
  }

  Future<List<Gene>> getAllGenes(Session session) {
    return Gene.db.find(session, where: (t) => t.id > 0);
  }
}
