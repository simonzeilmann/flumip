import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/url_guard.dart';
import 'package:flumip_server/src/endpoints/flumip_endpoint.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/authorization_service.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/serverpod.dart';

/// Everything to do with SNP sets that a user, rather than the server's
/// administrator, brought along.
///
/// Reading and listing live here too, because they have to be visibility-filtered
/// and `GenomeEndpoint` has no notion of who owns what.
class SnpEndpoint extends FlumipEndpoint {
  SnpService get snpService => sl<SnpService>();
  GenomeService get genomeService => sl<GenomeService>();

  /// Every SNP for a genome that this caller may see.
  ///
  /// Filtered twice over — once for visibility, and again to hide somebody else's
  /// half-finished import — by [AuthorizationService.listableSnps], which is
  /// where both passes live now that search needs the same pair.
  ///
  /// \param session The current session.
  /// \param genomeId The genome whose SNP sets to list.
  Future<List<Snp>> listSnpsForGenome(Session session, int genomeId) async {
    session.log('Listing SNPs for genome $genomeId', level: LogLevel.info);
    try {
      final all = await genomeService.getAllSnpForGenome(session, genomeId);
      return await authz.listableSnps(session, all);
    } catch (e) {
      session.log(
        'Error listing SNPs for genome $genomeId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Every custom SNP this caller added, whatever state it is in.
  ///
  /// Unlike [listSnpsForGenome] this shows failed and in-flight imports, because
  /// this is the list somebody goes to in order to fix or remove one. An
  /// administrator gets every custom SNP on the server, which is what makes
  /// cleaning up after a departed colleague possible.
  ///
  /// Doubles as the app's answer to "which of these are mine?" — the session
  /// carries no user id, so the client works it out from the ids in this list.
  Future<List<Snp>> listMySnps(Session session) async {
    session.log('Listing the caller\'s custom SNPs', level: LogLevel.info);
    try {
      // Ordered for the same reason as `getAllSnpForGenome`: an unordered find
      // returns Postgres heap order, which moves whenever a row is updated.
      final custom = await Snp.db.find(
        session,
        where: (t) => t.custom.equals(true),
        orderBy: (t) => t.id,
      );
      if (!authz.isEnforcing) return custom;

      final who = await authz.principal(session);
      if (who.isAdmin) return custom;
      return custom
          .where((s) => s.owner != null && s.owner == who.userId)
          .toList();
    } catch (e) {
      session.log(
        'Error listing custom SNPs',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Announces a custom SNP set whose files the browser is about to send.
  ///
  /// Step one of three. Returns a `pending` row with its directory made, so the
  /// browser knows where to `PUT` — the path is derived from the row id and can
  /// therefore never be influenced by anything a user typed.
  ///
  /// ```
  /// 1. createUpload(dto)                       -> Snp (pending)
  /// 2. PUT /snp_upload/<id>/<fileName>         x1 or x2, raw bytes
  /// 3. finishUpload(id)                        -> Snp (ready | indexing | failed)
  /// ```
  Future<Snp> createUpload(Session session, CustomSnpRequestDto request) async {
    session.log(
      'Creating an upload slot for a custom SNP',
      level: LogLevel.info,
    );
    try {
      final name = request.name.trim();
      if (name.isEmpty) {
        throw ArgumentException(message: 'An SNP set needs a name.');
      }
      final genome = await Genome.db.findById(session, request.genomeId);
      if (genome == null) {
        throw FlumipFileNotFoundException(
          message: 'This genome no longer exists.',
        );
      }

      final snp = await Snp.db.insertRow(
        session,
        Snp(
          name: name,
          description: request.description.trim(),
          vcfPath: '',
          tbiPath: '',
          folder: '',
          private: request.private,
          custom: true,
          genome: genome.id,
          owner: await authz.ownerForNewSnp(session),
          status: SnpImportStatus.pending,
          statusMessage: 'Waiting for the files',
          created: DateTime.now().toUtc(),
          statusUpdated: DateTime.now().toUtc(),
        ),
      );

      final dir = await snpService.createUserDirectory(session, snp.id!);
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);
      return snp;
    } catch (e) {
      session.log(
        'Error creating an upload slot',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Step three: works out what actually arrived and settles the row.
  ///
  /// Reads the directory rather than trusting the client's account of what it
  /// sent, so a browser that dropped the second `PUT` cannot leave a row claiming
  /// to be complete.
  Future<Snp> finishUpload(Session session, int snpId) async {
    session.log('Finishing the upload of SNP $snpId', level: LogLevel.info);
    try {
      final snp = await _writableCustom(session, snpId);
      await snpService.settleUpload(session, snp);
      return (await Snp.db.findById(session, snpId))!;
    } catch (e) {
      session.log(
        'Error finishing the upload of SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Removes a custom SNP set whose upload never completed.
  ///
  /// Distinct from [deleteCustomSnp] only in intent: this is the "cancel" the app
  /// offers on a `pending` row, and refusing anything further along stops it
  /// double-serving as a delete without confirmation.
  Future<void> cancelUpload(Session session, int snpId) async {
    session.log('Cancelling the upload of SNP $snpId', level: LogLevel.info);
    try {
      final snp = await _writableCustom(session, snpId);
      if (snp.status != SnpImportStatus.pending &&
          snp.status != SnpImportStatus.failed) {
        throw ArgumentException(
          message: 'This SNP set is no longer waiting for files.',
        );
      }
      await snpService.deleteSnp(session, snp);
    } catch (e) {
      session.log(
        'Error cancelling the upload of SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Adds a custom SNP set whose files the server fetches for itself.
  ///
  /// `request.urls` is the `.vcf.gz` address and optionally its `.vcf.gz.tbi`.
  /// Returns immediately with a `pending` row; the bytes arrive on a future call
  /// and the app watches `status` and `bytesDownloaded`.
  ///
  /// ⚠️ **Every URL is validated synchronously, before the row is inserted.** A
  /// rejected address comes back as an error on this call rather than as a
  /// `failed` row the user has to go and find — and, more to the point, the
  /// address check is what stops this endpoint being a request proxy into the
  /// deployment's own network. See `snpSourceUrlRejection`.
  Future<Snp> importFromUrls(
    Session session,
    CustomSnpRequestDto request,
  ) async {
    session.log('Importing an SNP set from URLs', level: LogLevel.info);
    try {
      final name = request.name.trim();
      if (name.isEmpty) {
        throw ArgumentException(message: 'An SNP set needs a name.');
      }

      final genome = await Genome.db.findById(session, request.genomeId);
      if (genome == null) {
        throw FlumipFileNotFoundException(
          message: 'This genome no longer exists.',
        );
      }

      final (vcfUrl, tbiUrl) = await _validateSourceUrls(
        session,
        request.urls ?? const [],
      );

      final snp = await Snp.db.insertRow(
        session,
        Snp(
          name: name,
          description: request.description.trim(),
          // Filled in by the import; a pending row has no files yet.
          vcfPath: '',
          tbiPath: '',
          folder: '',
          private: request.private,
          custom: true,
          genome: genome.id,
          owner: await authz.ownerForNewSnp(session),
          status: SnpImportStatus.pending,
          statusMessage: 'Queued for download',
          sourceVcfUrl: vcfUrl,
          sourceTbiUrl: tbiUrl,
          created: DateTime.now().toUtc(),
          statusUpdated: DateTime.now().toUtc(),
        ),
      );

      // The folder is derived from the row id, so it can only be set now.
      final dir = await snpService.createUserDirectory(session, snp.id!);
      snp.folder = dir.path;
      await Snp.db.updateRow(session, snp);

      await snpService.scheduleSnpImport(session, snp);
      return snp;
    } catch (e) {
      session.log(
        'Error importing an SNP set from URLs',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Puts a failed import back in the queue and reschedules it.
  ///
  /// Starts over rather than resuming: a half-download that silently continued
  /// against a *changed* remote file would produce a corrupt archive, which is a
  /// worse outcome than fetching a gigabyte twice.
  Future<Snp> retryImport(Session session, int snpId) async {
    session.log('Retrying the import of SNP $snpId', level: LogLevel.info);
    try {
      final snp = await _writableCustom(session, snpId);
      if (snp.status == SnpImportStatus.downloading ||
          snp.status == SnpImportStatus.indexing) {
        throw ArgumentException(message: 'This import is already running.');
      }

      // Re-validate: the allowlist may have been tightened, or the host may now
      // resolve somewhere it did not before.
      final vcfUrl = snp.sourceVcfUrl;
      if (vcfUrl == null || vcfUrl.isEmpty) {
        // An upload rather than a URL import. Rebuilding the index is the only
        // thing that can be retried without the bytes being re-sent.
        if (snp.vcfPath.isNotEmpty && await File(snp.vcfPath).exists()) {
          await snpService.buildTabixIndex(session, snp);
          return (await Snp.db.findById(session, snpId))!;
        }
        throw ArgumentException(
          message: 'There is nothing to retry — upload the files again.',
        );
      }
      await _validateSourceUrls(session, [
        vcfUrl,
        if (snp.sourceTbiUrl?.isNotEmpty ?? false) snp.sourceTbiUrl!,
      ]);

      snp
        ..status = SnpImportStatus.pending
        ..statusMessage = 'Queued for download'
        ..bytesDownloaded = 0
        ..totalBytes = 0
        ..statusUpdated = DateTime.now().toUtc();
      await Snp.db.updateRow(session, snp);

      await snpService.scheduleSnpImport(session, snp);
      return snp;
    } catch (e) {
      session.log(
        'Error retrying the import of SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Checks the supplied addresses and returns them as `(vcf, tbi)`.
  ///
  /// Throws [ArgumentException] with the reason for anything refused, so the app
  /// can render the server's own words rather than a generic failure.
  Future<(String, String?)> _validateSourceUrls(
    Session session,
    List<String> urls,
  ) async {
    final cleaned = urls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      throw ArgumentException(message: 'Give the address of a .vcf.gz file.');
    }
    if (cleaned.length > 2) {
      throw ArgumentException(
        message: 'Give one .vcf.gz address, and optionally its .vcf.gz.tbi.',
      );
    }

    final vcfUrl = cleaned.first;
    final tbiUrl = cleaned.length > 1 ? cleaned[1] : null;

    if (SnpService.fileNameFromUrl(vcfUrl) == null) {
      throw ArgumentException(
        message: 'The first address must end in .vcf.gz.',
      );
    }
    if (tbiUrl != null && !tbiUrl.split('?').first.endsWith('.vcf.gz.tbi')) {
      throw ArgumentException(
        message: 'The second address must end in .vcf.gz.tbi.',
      );
    }

    final settings = await sl<SettingsService>().getSettings(session);
    final allowedHosts = SnpService.parseAllowedHosts(
      settings.snpSourceAllowedHosts,
    );

    for (final url in [vcfUrl, ?tbiUrl]) {
      final parsed = Uri.tryParse(url);
      if (parsed == null) {
        throw ArgumentException(message: 'This is not a valid web address.');
      }
      final refusal = snpSourceUrlRejection(
        parsed,
        resolved: await resolveHost(parsed.host),
        allowedHosts: allowedHosts,
      );
      if (refusal != null) {
        session.log(
          'Refused an SNP source address: $refusal',
          level: LogLevel.warning,
        );
        throw ArgumentException(message: refusal);
      }
    }

    return (vcfUrl, tbiUrl);
  }

  /// Shares an SNP with everyone on this server, or takes it back.
  ///
  /// Only its owner — or an administrator — may do this, even once it is shared.
  /// Ownership survives sharing.
  ///
  /// \param session The current session.
  /// \param snpId The SNP to change.
  /// \param shared True to make it visible to everybody.
  Future<Snp> setShared(Session session, int snpId, bool shared) async {
    session.log('Setting SNP $snpId shared=$shared', level: LogLevel.info);
    try {
      final snp = await _writableCustom(session, snpId);
      snp.private = !shared;
      await Snp.db.updateRow(session, snp);
      return snp;
    } catch (e) {
      session.log(
        'Error sharing SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Renames an SNP and rewrites its description.
  ///
  /// Cosmetic only: the files on disk are named after the row id, never after
  /// this, so nothing has to move and no path changes.
  Future<Snp> renameSnp(
    Session session,
    int snpId,
    String name,
    String description,
  ) async {
    session.log('Renaming SNP $snpId', level: LogLevel.info);
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw ArgumentException(message: 'An SNP set needs a name.');
      }
      final snp = await _writableCustom(session, snpId);
      snp
        ..name = trimmed
        ..description = description.trim();
      await Snp.db.updateRow(session, snp);
      return snp;
    } catch (e) {
      session.log(
        'Error renaming SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// The projects currently using this SNP.
  ///
  /// Read before a delete is confirmed, so the dialog can name them rather than
  /// warning in the abstract.
  Future<List<SnpUsageDto>> snpUsage(Session session, int snpId) async {
    try {
      final snp = await _requireSnp(session, snpId);
      await authz.requireSnpAccess(session, snp);
      return await snpService.snpUsage(session, snpId);
    } catch (e) {
      session.log(
        'Error reading usage of SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Deletes a custom SNP and its files. Its owner, or an administrator.
  ///
  /// Refuses a global SNP outright. Removing one of those deletes files out of
  /// the shared genome tree, which is a different decision needing a different
  /// gate — see [deleteSnpAsAdmin]. Keeping them as separate methods is what stops
  /// an ordinary user's delete button from ever being able to reach one.
  Future<void> deleteCustomSnp(Session session, int snpId) async {
    session.log('Deleting custom SNP $snpId', level: LogLevel.info);
    try {
      final snp = await _writableCustom(session, snpId);
      await snpService.deleteSnp(session, snp);
    } catch (e) {
      session.log(
        'Error deleting custom SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Deletes **any** SNP, including a global one, along with its files.
  ///
  /// ⚠️ **Irreversible, and it reaches outside this application's own data.** A
  /// global SNP's files are part of the hand-assembled genome tree; dbSNP is
  /// tens of gigabytes and hours of transfer, quite possibly on a shared mount.
  /// There is no undo and no tombstone — restoring means putting the files back
  /// and collecting again, which produces a new row with a new id.
  ///
  /// Gated by [SettingsService.requireAdmin] rather than
  /// `AuthorizationService.requireAdmin`, and the difference matters. The latter
  /// deliberately *throws* while single sign-on is off, on the grounds that
  /// reassigning ownership is meaningless without identities. That reasoning does
  /// not carry here: a no-auth install can perfectly well have a broken global SNP
  /// that needs removing, and it has an established administrative credential in
  /// the settings password. [SettingsService.requireAdmin] already implements
  /// exactly that dual gate — an admin session, or the password while sign-in is
  /// not enforced.
  ///
  /// \param settingsPassword Ignored when the caller is a signed-in admin.
  /// \param force Required when projects are still using it. Without it the call
  ///   refuses and names them, so nobody removes a file three running designs
  ///   depend on by accident.
  Future<void> deleteSnpAsAdmin(
    Session session,
    int snpId,
    String? settingsPassword, {
    bool force = false,
  }) async {
    session.log(
      'Administrative delete requested for SNP $snpId (force: $force)',
      level: LogLevel.warning,
    );
    try {
      await sl<SettingsService>().requireAdmin(session, settingsPassword);
      final snp = await _requireSnp(session, snpId);

      if (!force) {
        final usage = await snpService.snpUsage(session, snpId);
        if (usage.isNotEmpty) {
          final names = usage.map((u) => u.projectName).join(', ');
          throw ArgumentException(
            message:
                '${usage.length} project(s) still use this SNP set: $names. '
                'Confirm again to delete it anyway.',
          );
        }
      }

      await snpService.deleteSnp(session, snp);
    } catch (e) {
      session.log(
        'Error on administrative delete of SNP $snpId',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  /// Rescans the custom SNP directory.
  ///
  /// Ungated, matching `GenomeEndpoint.collectGenomes`, which has always been.
  /// It creates nothing a user did not already put on the server's disk, and
  /// gating both is a defensible hardening for another day.
  Future<void> collectCustomSnps(Session session) async {
    try {
      await snpService.collectCustomSnps(session);
    } catch (e) {
      session.log(
        'Error collecting custom SNPs',
        level: LogLevel.error,
        exception: e,
      );
      rethrow;
    }
  }

  Future<Snp> _requireSnp(Session session, int snpId) async {
    final snp = await Snp.db.findById(session, snpId);
    if (snp == null) {
      throw FlumipFileNotFoundException(
        message: 'This SNP set no longer exists.',
      );
    }
    return snp;
  }

  /// The SNP, having established that the caller may change it and that it is
  /// not one of the global scanned ones.
  Future<Snp> _writableCustom(Session session, int snpId) async {
    final snp = await _requireSnp(session, snpId);
    if (!snp.custom) {
      session.log(
        'Refused a change to global SNP $snpId through the ordinary path',
        level: LogLevel.warning,
      );
      throw ProjectAccessDeniedException(
        message:
            'This SNP set came with the server\'s reference data. Only an '
            'administrator can change or remove it.',
      );
    }
    await authz.requireSnpWrite(session, snp);
    return snp;
  }
}
