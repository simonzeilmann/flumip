import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

import '../generated/protocol.dart';
import '../services/authorization_service.dart';
import '../services/genome_service.dart';
import 'flumip_endpoint.dart';

/// Why a guest on a public instance cannot manage genomes. Scanning, indexing
/// and editing act on the whole server, for every visitor at once.
const _guestGenomeRefusal =
    'Managing genomes is reserved for administrators on this public server.';

/// Why a signed-in user cannot take something away from everybody else.
///
/// The line between the two refusals: a signed-in user may *add* to the shared
/// library — scan for genomes that were put on the disk, build a missing index —
/// and only an administrator may *remove* from it. Removing an index stops every
/// design on that genome until somebody spends hours rebuilding it; switching a
/// genome off takes it out of everybody's list.
const _adminGenomeRefusal =
    'Removing an index and switching a genome on or off are reserved for '
    'administrators.';

/// Endpoint for genome-related operations.
class GenomeEndpoint extends FlumipEndpoint {
  /// Instance of the genome service.
  GenomeService get genomeService => GenomeService();

  /// Retrieves a genome by its ID.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to retrieve.
  /// \returns The genome with the specified ID.
  /// \throws Exception if an error occurs during retrieval.
  Future<Genome> getGenome(Session session, int id) async {
    session.log('Retrieving genome with ID: $id', level: LogLevel.info);
    try {
      return await genomeService.getGenome(session, id);
    } catch (e) {
      session.log(
        'Error retrieving genome with ID: $id',
        level: LogLevel.error,
        exception: e,
      );
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
      return await genomeService.getAllGenomes(session);
    } catch (e) {
      session.log(
        'Error retrieving all genomes',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Updates a genome: switches it on or off, or changes its description.
  ///
  /// **Administrators only** on an install with sign-in or public mode.
  ///
  /// \param session The current session.
  /// \param id The ID of the genome to update.
  /// \param genome The updated genome data.
  /// \throws Exception if an error occurs during the update.
  Future<void> updateGenome(Session session, int id, Genome genome) async {
    session.log('Updating genome with ID: $id', level: LogLevel.info);
    try {
      await authz.refuseNonAdmin(session, message: _adminGenomeRefusal);
      return await genomeService.updateGenome(session, id, genome);
    } catch (e) {
      session.log(
        'Error updating genome with ID: $id',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Collects genomes from the genome directory.
  ///
  /// Open to every signed-in user, not only administrators: it adds what
  /// somebody already put on the server's disk and removes nothing that is
  /// still there.
  ///
  /// \param session The current session.
  /// \throws Exception if an error occurs during collection.
  Future<void> collectGenomes(Session session) async {
    session.log('Collecting genomes', level: LogLevel.info);
    try {
      await authz.refuseGuest(session, message: _guestGenomeRefusal);
      return await genomeService.collectGenomes(session);
    } catch (e) {
      session.log(
        'Error collecting genomes',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Retrieves an SNP by its ID.
  ///
  /// ⚠️ Filtered by [AuthorizationService.readableSnp]. This used to return any
  /// row to anybody, which made every private SNP set — its name, owner and
  /// server paths — one counted id away. What the project tile still needs, the
  /// name of the set a project it can open runs with, is what that method
  /// keeps.
  ///
  /// \param session The current session.
  /// \param id The ID of the SNP to retrieve.
  /// \returns The SNP with the specified ID.
  /// \throws [ProjectAccessDeniedException] if the caller may not see it.
  Future<Snp> getSnp(Session session, int id) async {
    session.log('Retrieving SNP with ID: $id', level: LogLevel.info);
    try {
      final snp = await genomeService.getSnp(session, id);
      return await authz.readableSnp(session, snp);
    } catch (e) {
      session.log(
        'Error retrieving SNP with ID: $id',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Retrieves the SNPs for a specific genome that the caller may be offered.
  ///
  /// ⚠️ The same answer as `SnpEndpoint.listSnpsForGenome`, through the same
  /// [AuthorizationService.listableSnps]. It used to return every row,
  /// everybody's private sets included, to anybody. Nothing in the app calls
  /// it any more; it stays because removing it would be a protocol change.
  ///
  /// \param session The current session.
  /// \param genomeId The ID of the genome to retrieve SNPs for.
  /// \returns The SNPs for the specified genome the caller may see.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<Snp>> getAllSnpForGenome(Session session, int genomeId) async {
    session.log('Retrieving all SNPs', level: LogLevel.info);
    try {
      final all = await genomeService.getAllSnpForGenome(session, genomeId);
      return await authz.listableSnps(session, all);
    } catch (e) {
      session.log(
        'Error retrieving all SNPs',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  // `updateSnp` used to live here. It took a whole client-supplied `Snp` row and
  // handed it straight to `Snp.db.updateRow` with no check of any kind, which was
  // survivable only because an SNP had nothing worth rewriting and nothing in the
  // app ever called it. It now would: `owner`, `private`, `status` and `vcfPath`
  // are all on the row, so the same method would let anyone take over, unshare or
  // repoint anybody's SNP. Replaced by `SnpEndpoint.renameSnp` and
  // `SnpEndpoint.setShared`, which change one thing each and are guarded.

  /// Retrieves all genome categories.
  ///
  /// \param session The current session.
  /// \returns A list of all genome categories.
  /// \throws Exception if an error occurs during retrieval.
  Future<List<String>> getCategories(Session session) async {
    session.log('Retrieving categories', level: LogLevel.info);
    try {
      return await genomeService.getGenomeCategories(session);
    } catch (e) {
      session.log(
        'Error retrieving categories',
        level: LogLevel.error,
        exception: e,
      );
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
    Session session,
    String category,
  ) async {
    session.log(
      'Retrieving genomes for category: $category',
      level: LogLevel.info,
    );
    try {
      return await genomeService.getGenomeByCategory(session, category);
    } catch (e) {
      session.log(
        'Error retrieving genomes for category: $category',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Builds the index a genome needs before it can be designed against.
  ///
  /// Open to every signed-in user, like [collectGenomes]: a genome found by a
  /// scan is no use until this has run. It cannot be repeated — an indexed
  /// genome refuses — and undoing it is [deleteFastaIndex], which is not open.
  Future<void> indexFasta(Session session, int id) async {
    session.log('Indexing fasta for genome with ID: $id', level: LogLevel.info);
    try {
      await authz.refuseGuest(session, message: _guestGenomeRefusal);
      return await genomeService.indexFasta(session, id);
    } catch (e) {
      session.log(
        'Error indexing fasta for genome with ID: $id',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Removes a genome's index.
  ///
  /// **Administrators only** on an install with sign-in or public mode.
  Future<void> deleteFastaIndex(Session session, int id) async {
    session.log(
      'Deleting fasta index for genome with ID: $id',
      level: LogLevel.info,
    );
    try {
      await authz.refuseNonAdmin(session, message: _adminGenomeRefusal);
      return await genomeService.deleteFastaIndex(session, id);
    } catch (e) {
      session.log(
        'Error deleting fasta index for genome with ID: $id',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }
}
