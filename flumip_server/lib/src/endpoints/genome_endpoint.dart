import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/genome_service.dart';

/// Endpoint for genome-related operations.
class GenomeEndpoint extends Endpoint {
  /// Instance of the genome service.
  get genomeService => GenomeService();

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The genome with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  Future<Genome> getGenome(Session session, int id) async {
    session.log('Retrieving genome with ID: $id', level: LogLevel.info);
    try {
      return genomeService.getGenome(session, id);
    } catch (e) {
      session.log('Error retrieving genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves all genomes.
  ///
  /// \param session The current session.
  /// \returns A list of all genomes.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<Genome>> getAllGenomes(Session session) async {
    session.log('Retrieving all genomes', level: LogLevel.info);
    try {
      return genomeService.getAllGenomes(session);
    } catch (e) {
      session.log('Error retrieving all genomes',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Updates a genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to update.
  /// \param genome The updated genome data.
  /// \throws Exception if an error occurs during the update.
  Future<void> updateGenome(Session session, int id, Genome genome) async {
    session.log('Updating genome with ID: $id', level: LogLevel.info);
    try {
      return genomeService.updateGenome(session, id, genome);
    } catch (e) {
      session.log('Error updating genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Collects genomes from the genome directory.
  ///
  /// \param session The current session.
  /// \throws Exception if an error occurs during collection.
  Future<void> collectGenomes(Session session) async {
    session.log('Collecting genomes', level: LogLevel.info);
    try {
      return genomeService.collectGenomes(session);
    } catch (e) {
      session.log('Error collecting genomes',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Indexes the FA file for the specified genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to index.
  /// \throws Exception if an error occurs during indexing.
  Future<void> indexGenome(Session session, int id) async {
    session.log('Indexing genome with ID: $id', level: LogLevel.info);
    try {
      return genomeService.indexGenome(session, id);
    } catch (e) {
      session.log('Error indexing genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Deletes the index for the specified genome.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to delete the index for.
  /// \throws Exception if an error occurs during deletion.
  Future<void> deleteGenomeIndex(Session session, int id) async {
    session.log('Deleting index for genome with ID: $id', level: LogLevel.info);
    try {
      return genomeService.deleteGenomeIndex(session, id);
    } catch (e) {
      session.log('Error deleting index for genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves an SNP by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The SNP with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  Future<Snp> getSnp(Session session, int id) async {
    session.log('Retrieving SNP with ID: $id', level: LogLevel.info);
    try {
      return genomeService.getSnp(session, id);
    } catch (e) {
      session.log('Error retrieving SNP with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves all SNPs for a specific genome.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns A list of all SNPs for the specified genome.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<Snp>> getAllSnpForGenome(Session session, int genomeId) async {
    session.log('Retrieving all SNPs', level: LogLevel.info);
    try {
      return genomeService.getAllSnpForGenome(session, genomeId);
    } catch (e) {
      session.log('Error retrieving all SNPs',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Updates an SNP.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to update.
  /// \param snp The updated SNP data.
  /// \throws Exception if an error occurs during the update.
  Future<void> updateSnp(Session session, int id, Snp snp) async {
    session.log('Updating SNP with ID: $id', level: LogLevel.info);
    try {
      return genomeService.updateSnp(session, id, snp);
    } catch (e) {
      session.log('Error updating SNP with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves all genome categories.
  ///
  /// \param session The current session.
  /// \returns A list of all genome categories.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<String>> getCategories(Session session) async {
    session.log('Retrieving categories', level: LogLevel.info);
    try {
      return genomeService.getGenomeCategories(session);
    } catch (e) {
      session.log('Error retrieving categories',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  /// Retrieves genomes by category.
  ///
  /// \param session The current session.
  /// \param category The category to filter genomes by.
  /// \returns A list of genomes in the specified category.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<Genome>> getGenomeByCategory(
      Session session, String category) async {
    session.log('Retrieving genomes for category: $category',
        level: LogLevel.info);
    try {
      return genomeService.getGenomeByCategory(session, category);
    } catch (e) {
      session.log('Error retrieving genomes for category: $category',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<void> indexFasta(Session session, int id) async {
    session.log('Indexing fasta for genome with ID: $id', level: LogLevel.info);
    try {
      return genomeService.indexFasta(session, id);
    } catch (e) {
      session.log('Error indexing fasta for genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }

  Future<void> deleteFastaIndex(Session session, int id) async {
    session.log('Deleting fasta index for genome with ID: $id',
        level: LogLevel.info);
    try {
      return genomeService.deleteFastaIndex(session, id);
    } catch (e) {
      session.log('Error deleting fasta index for genome with ID: $id',
          level: LogLevel.error, exception: e);
      rethrow;
    }
  }
}
