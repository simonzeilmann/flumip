import 'dart:io';

import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../../service_locator.dart';
import '../generated/protocol.dart';

class GeneService {
  GeneService();

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

  Future<void> updateGene(Session session, int id, Gene gene) async {
    var geneToUpdate = await Gene.db.findById(session, id);
    if (geneToUpdate == null) {
      throw FileNotFoundException(message: 'Gene not found');
    }
    await Gene.db.updateRow(session, gene);
  }

  Future<bool> _geneExists(Session session, String path) async {
    var gene = await Gene.db.find(session, where: (t) => t.path.equals(path));
    if(gene.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> collectGenes(Session session) async {
    final settings = await sl.get<SettingsService>().getSettings(session);

    var categoryFolder = Directory(settings.geneDir);

    if (!await Directory(settings.geneDir).exists()) {
      session.log('Gene folder not found', level: LogLevel.error);
      throw FileNotFoundException(message: 'Gene folder not found');
    }

    for (var category in categoryFolder.listSync()) {
      if (category is Directory) {
        var geneFolders = Directory(category.path);
        for (var geneFolder in geneFolders.listSync()) {
          if(await _geneExists(session, geneFolder.path)) {
            continue;
          }
          if (geneFolder is Directory) {
            var gene = Gene(
                name: geneFolder.path.split('/').last,
                category: category.path.split('/').last,
                path: geneFolder.path);
            List<Snp> snps = [];
            var geneFiles = Directory(geneFolder.path);
            for (var geneFile in geneFiles.listSync()) {
              if (geneFile is File) {
                if (geneFile.path.endsWith("refGene.txt")) {
                  gene.refPath = geneFile.path;
                }
              }
              if (geneFile is Directory) {
                if (geneFile.path.endsWith("fa")) {
                  var faFiles = Directory(geneFile.path);
                  for (var faFile in faFiles.listSync()) {
                    if (faFile is File) {
                      if (faFile.path.endsWith(".fa")) {
                        gene.fastaPath = faFile.path;
                        continue;
                      }
                    }
                  }
                  if (faFiles.listSync().contains(".amb") &&
                      faFiles.listSync().contains(".gnn") &&
                      faFiles.listSync().contains(".pac") &&
                      faFiles.listSync().contains(".sa") &&
                      faFiles.listSync().contains(".bwt") &&
                      faFiles.listSync().contains(".ann")) {
                    gene.indexed = true;
                  }
                }
                if (geneFile.path.endsWith("snp")) {
                  var snpDirectories = Directory(geneFile.path);
                  gene.snpFolder = geneFile.path;
                  for (var snpDir in snpDirectories.listSync()) {
                    if (snpDir is Directory) {
                      var snpFiles = Directory(snpDir.path);
                      if (snpFiles.listSync().contains(".vcf.gz") &&
                          snpFiles.listSync().contains(".vcf.gz.tbi")) {
                        var snp = Snp(
                            name: snpDir.path.split('/').last,
                            vcfPath: '',
                            tbiPath: '',
                            folder: snpDir.path,
                            active: true);
                        for (var snpFile in snpFiles.listSync()) {
                          if (snpFile is File) {
                            if (snpFile.path.endsWith(".vcf.gz")) {
                              snp.vcfPath = snpFile.path;
                            }
                            if (snpFile.path.endsWith(".vcf.gz.tbi")) {
                              snp.tbiPath = snpFile.path;
                            }
                          }
                        }
                        snps.add(snp);
                      }
                    }
                  }
                }
              }
            }
            if(gene.refPath != null && gene.fastaPath != null) {
              for (var snp in snps) {
                var snpRet = await Snp.db.insertRow(session, snp);
                gene.snp ??= <int>[];
                gene.snp?.add(snpRet.id!);
              }
              await Gene.db.insertRow(session, gene);
            }
          }
        }
      }
    }
  }
}
