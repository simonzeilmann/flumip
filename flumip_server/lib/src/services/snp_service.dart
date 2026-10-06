import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/future_calls.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/file_service.dart';
import 'package:flumip_server/src/services/process_runner.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:flumip_server/src/services/snp_downloader.dart';
import 'package:serverpod/serverpod.dart';

/// Which of the two files an SNP directory may hold.
enum SnpFileKind {
  /// The bgzip'd VCF itself.
  vcf,

  /// Its tabix index.
  tbi,
}

/// Custom SNP sets: where their files live, how a scan reconciles them against
/// the database, and how one is deleted.
///
/// Global SNPs stay [GenomeService]'s business — they are **file-first**, found
/// by scanning `Settings.genomeDir`, and the filesystem is their source of truth.
/// Custom SNPs are **row-first**: an endpoint inserts the row, this service makes
/// the directory, and the bytes arrive afterwards by upload or download. A scan
/// therefore never invents a custom row; it only reconciles what is on disk with
/// what the database already says.
///
/// ## Layout under `Settings.customSnpDir`
///
/// ```
/// custom_snp/
/// ├── common/            admin drop-in, DISCOVERED by scanning
/// │   └── <genomeName>/  must match a Genome.name
/// │       └── <snpName>/{*.vcf.gz, *.vcf.gz.tbi}
/// └── user/              server-managed, RECONCILED only
///     └── <snpId>/
///         ├── .incoming/ partial uploads and in-flight downloads
///         └── {*.vcf.gz, *.vcf.gz.tbi}
/// ```
///
/// `common` and `user` name the *mechanism*, not the visibility. A shared custom
/// SNP stays in `user/<id>/`: `vcfPath` is stored absolute and mipgen holds it, so
/// files are never moved once written.
class SnpService {
  SnpService();

  /// How long a `downloading` or `indexing` row may go without a heartbeat before
  /// a reconcile pass calls it dead.
  ///
  /// Generous on purpose: the heartbeat is written every couple of seconds during
  /// a download, so anything past this is not a slow transfer but a server that
  /// restarted mid-flight.
  static const stuckImportAfter = Duration(minutes: 30);

  /// How long a partial file may sit in `.incoming/` before it is swept.
  ///
  /// A day, because a browser that vanished mid-upload leaves one behind with no
  /// error reaching the server, and the user may well come back to retry.
  static const incomingSweepAfter = Duration(hours: 24);

  /// How long `tabix` gets before it is treated as wedged.
  ///
  /// Generous: indexing dbSNP's 1.6 GB takes a few seconds on a warm disk and
  /// perhaps a minute on a cold, slow one. Anything past this is not slow, it is
  /// stuck.
  static const indexingTimeout = Duration(minutes: 20);

  /// Name of the subdirectory holding bytes that have not fully arrived.
  ///
  /// Dot-prefixed and, more importantly, a *directory*, so nothing that lists an
  /// SNP folder for files can mistake a half-written `.part` for a finished VCF.
  static const incomingDirName = '.incoming';

  SettingsService get _settings => sl<SettingsService>();
  FileService get _files => sl<FileService>();

  // ---------------------------------------------------------------- layout ---

  /// The root of the custom SNP tree.
  Future<Directory> customSnpRoot(Session session) async {
    final settings = await _settings.getSettings(session);
    return Directory(settings.customSnpDir);
  }

  /// The admin drop-in directory, whose contents a scan discovers.
  Future<Directory> commonRoot(Session session) async =>
      Directory('${(await customSnpRoot(session)).path}/common');

  /// The server-managed directory, one subdirectory per custom SNP row.
  Future<Directory> userRoot(Session session) async =>
      Directory('${(await customSnpRoot(session)).path}/user');

  /// The directory belonging to a user-added SNP, created if need be.
  ///
  /// Named after the row id rather than the SNP's name, so that renaming is a
  /// database operation and two people may use the same name. It also means the
  /// path can never be influenced by anything a user typed.
  Future<Directory> createUserDirectory(Session session, int snpId) async {
    final dir = Directory('${(await userRoot(session)).path}/$snpId');
    await dir.create(recursive: true);
    return dir;
  }

  /// The staging directory for bytes that have not fully arrived, created if need
  /// be.
  Future<Directory> createIncomingDirectory(Directory snpDir) async {
    final dir = Directory('${snpDir.path}/$incomingDirName');
    await dir.create(recursive: true);
    return dir;
  }

  // ------------------------------------------------------------------ pure ---

  /// Which kind of SNP file [name] is, or null if it is not one at all.
  ///
  /// ⚠️ **This is the upload gate, and it has to run *before* anything is
  /// created.** `FileService.resolveProjectFile` can check containment after
  /// resolving symlinks because the file it guards already exists; an upload
  /// makes the file, so the only defence is to refuse the name outright.
  ///
  /// The rules are deliberately narrower than "no traversal": an SNP directory
  /// holds exactly two shapes of file, so anything else is refused rather than
  /// sanitised. A name that survives this cannot contain a separator, cannot be
  /// `.` or `..`, cannot be absolute, cannot start with a dot or a dash, and ends
  /// in one of the two suffixes the rest of the pipeline understands.
  static SnpFileKind? snpUploadFileKind(String name) {
    if (name.isEmpty || name.length > 120) return null;
    if (name == '.' || name == '..') return null;
    if (name.contains('/') || name.contains(r'\')) return null;
    // \u0000, not a literal NUL byte. It was the byte itself, which made git
    // treat this whole 44 KB file as binary: no diff, no blame, no merge.
    if (name.contains('\u0000')) return null;
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) return null;

    final SnpFileKind kind;
    final String stem;
    if (name.endsWith('.vcf.gz.tbi')) {
      kind = SnpFileKind.tbi;
      stem = name.substring(0, name.length - '.vcf.gz.tbi'.length);
    } else if (name.endsWith('.vcf.gz')) {
      kind = SnpFileKind.vcf;
      stem = name.substring(0, name.length - '.vcf.gz'.length);
    } else {
      return null;
    }

    if (stem.isEmpty || stem.length > 100) return null;
    if (stem.contains('..')) return null;
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(stem)) return null;
    return kind;
  }

  /// The VCF and its tabix index among [entries], either of which may be absent.
  ///
  /// ⚠️ Matches **real [File] entities against real suffixes**. The scanner used
  /// to decide this by looking for `.vcf.gz` as a substring of the *stringified*
  /// directory listing, which cannot tell a file from a directory, cannot tell
  /// `panel.vcf.gz` from `notes.vcf.gz.txt`, and counts a half-written
  /// `panel.vcf.gz.part` as a finished VCF. That was tolerable when the only
  /// directories scanned were assembled by hand; `common/` is a drop-box and
  /// `user/` holds partial uploads, so it is not tolerable now.
  static ({File? vcf, File? tbi}) snpFilesIn(List<FileSystemEntity> entries) {
    File? vcf;
    File? tbi;
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      // Order matters: `.vcf.gz.tbi` does not end with `.vcf.gz`, but checking
      // the longer suffix first keeps that independent of the reader noticing.
      if (name.endsWith('.vcf.gz.tbi')) {
        tbi ??= entry;
      } else if (name.endsWith('.vcf.gz')) {
        vcf ??= entry;
      }
    }
    return (vcf: vcf, tbi: tbi);
  }

  /// The 28-byte empty BGZF block every complete bgzip file ends with.
  ///
  /// ⚠️ **This is the only reliable way to tell a complete VCF from one whose
  /// last bytes never arrived**, and the difference is not academic. A file
  /// missing *only* this block indexes without complaint: `tabix` exits 0, writes
  /// a valid-looking `.tbi`, answers queries for the records it does have, and
  /// mentions the truncation as a **warning on stderr** — which a caller checking
  /// only the exit code never sees. The SNP set is then marked ready and the
  /// first sign of trouble is mipgen dying on it some minutes later.
  static const bgzfEofMarker = [
    0x1f, 0x8b, 0x08, 0x04, 0x00, 0x00, 0x00, 0x00, //
    0x00, 0xff, 0x06, 0x00, 0x42, 0x43, 0x02, 0x00, //
    0x1b, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, //
    0x00, 0x00, 0x00, 0x00,
  ];

  /// Whether [tail] — the last [bgzfEofMarker].length bytes of a file — is the
  /// BGZF end-of-file block.
  static bool hasBgzfEofMarker(List<int> tail) {
    if (tail.length != bgzfEofMarker.length) return false;
    for (var i = 0; i < bgzfEofMarker.length; i++) {
      if (tail[i] != bgzfEofMarker[i]) return false;
    }
    return true;
  }

  /// What is wrong with [vcf], or null if it looks like a usable bgzip'd VCF.
  ///
  /// Two checks, both cheap, both reading a handful of bytes rather than the
  /// whole file: the header says bgzip rather than plain gzip, and the file ends
  /// where a complete one would.
  ///
  /// Called wherever a VCF is about to be declared usable — after an upload,
  /// after a download, and before indexing — because a truncated file is
  /// otherwise indistinguishable from a good one until something tries to read
  /// past the end of it.
  Future<String?> vcfProblem(File vcf) async {
    if (!await vcf.exists()) return 'The VCF is not on disk.';

    final length = await vcf.length();
    if (length < bgzfEofMarker.length) {
      return 'That file is too small to be a bgzip-compressed VCF.';
    }

    if (!looksLikeBgzf(await _firstBytes(vcf, 18))) {
      return 'That file is compressed with gzip, not bgzip, so tabix cannot '
          'index it. Recompress it with: bgzip -c yourfile.vcf > yourfile.vcf.gz';
    }

    final handle = await vcf.open();
    try {
      await handle.setPosition(length - bgzfEofMarker.length);
      if (!hasBgzfEofMarker(await handle.read(bgzfEofMarker.length))) {
        return 'That file is incomplete — its end-of-file marker is missing, '
            'so the upload or download did not finish. Send it again.';
      }
    } finally {
      await handle.close();
    }
    return null;
  }

  /// Whether [header] is the start of a BGZF file rather than a plain gzip one.
  ///
  /// tabix indexes BGZF — gzip with an extra `BC` field marking block boundaries —
  /// and a VCF compressed with plain `gzip` is the single commonest mistake here.
  /// tabix's own diagnostic for it is not something a biologist should have to
  /// decode, so this is sniffed first and answered in words.
  ///
  /// Checks the gzip magic, the FEXTRA flag, and the `BC` subfield identifier that
  /// starts the extra field.
  static bool looksLikeBgzf(List<int> header) {
    if (header.length < 16) return false;
    if (header[0] != 0x1f || header[1] != 0x8b) return false;
    // FEXTRA. Without it there is no room for the block-size subfield.
    if (header[3] & 0x04 == 0) return false;
    // The extra field begins at offset 12 and its first subfield must be `BC`.
    return header[12] == 0x42 && header[13] == 0x43;
  }

  // -------------------------------------------------------------- scanning ---

  /// Reconciles the custom SNP tree, and every SNP row, with what is on disk.
  ///
  /// Three idempotent passes, safe to run as often as anyone likes:
  ///
  /// 1. **Discover** `common/<genome>/<name>/` drop-ins that have no row yet.
  /// 2. **Reconcile** every SNP row, custom and global alike, against its files.
  /// 3. **Sweep** stale partial uploads, and log directories with no row.
  ///
  /// Called at the end of `GenomeService.collectGenomes` — so the existing
  /// "Collect Genomes" button covers both — and once at boot, so an import
  /// interrupted by a restart does not sit at `downloading` forever.
  Future<void> collectCustomSnps(Session session) async {
    session.log('Collecting custom SNPs', level: LogLevel.info);
    await _discoverDropIns(session);
    await _reconcileRows(session);
    await _sweep(session);
    session.log('Custom SNP collection completed', level: LogLevel.info);
  }

  /// Pass 1: create rows for `common/<genomeName>/<snpName>/` directories that do
  /// not have one.
  ///
  /// Drop-ins are shared and unowned by construction: an administrator put them
  /// there for everybody, the way the genome tree works.
  Future<void> _discoverDropIns(Session session) async {
    final root = await commonRoot(session);
    if (!await root.exists()) return;

    for (final genomeDir in root.listSync().whereType<Directory>()) {
      final genomeName = genomeDir.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .last;
      final genome = await Genome.db.findFirstRow(
        session,
        where: (t) => t.name.equals(genomeName),
      );
      if (genome == null) {
        session.log(
          'Skipping custom SNP directory "$genomeName": no genome by that '
          'name. Rename it to match a collected genome.',
          level: LogLevel.info,
        );
        continue;
      }

      for (final snpDir in genomeDir.listSync().whereType<Directory>()) {
        final existing = await Snp.db.findFirstRow(
          session,
          where: (t) => t.folder.equals(snpDir.path),
        );
        if (existing != null) continue;

        final found = snpFilesIn(snpDir.listSync());
        if (found.vcf == null || found.tbi == null) continue;

        final inserted = await Snp.db.insertRow(
          session,
          Snp(
            name: snpDir.uri.pathSegments.where((s) => s.isNotEmpty).last,
            vcfPath: found.vcf!.path,
            tbiPath: found.tbi!.path,
            folder: snpDir.path,
            private: false,
            custom: true,
            genome: genome.id,
            status: SnpImportStatus.ready,
            size: await _files.getDirSize(snpDir.path),
            created: DateTime.now().toUtc(),
            statusUpdated: DateTime.now().toUtc(),
          ),
        );
        session.log(
          'Discovered custom SNP "${inserted.name}" for ${genome.name}',
          level: LogLevel.info,
        );
      }
    }
  }

  /// Pass 2: bring every row into line with its files.
  ///
  /// Covers globals too, which fixes a long-standing gap: the scanner only ever
  /// *inserted*, so a re-downloaded or renamed VCF left `vcfPath` and `size`
  /// stale forever.
  Future<void> _reconcileRows(Session session) async {
    final all = await Snp.db.find(session, where: (t) => t.id > 0);
    for (final snp in all) {
      try {
        await _reconcileOne(session, snp);
      } catch (e, stackTrace) {
        session.log(
          'Could not reconcile SNP ${snp.id}; leaving it as it is.',
          level: LogLevel.error,
          exception: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _reconcileOne(Session session, Snp snp) async {
    // Bytes that have not arrived yet belong to whatever is fetching them, and
    // their files legitimately do not exist, so there is nothing on disk worth
    // comparing against. Everything else is decided by looking at the files.
    if (snp.status == SnpImportStatus.pending) {
      await _failIfAbandoned(session, snp);
      return;
    }
    if (snp.status == SnpImportStatus.downloading) {
      await _failIfStale(session, snp);
      return;
    }

    final dir = Directory(snp.folder);

    // ⚠️ Distinguish "somebody deleted this" from "the filesystem is not there".
    // A genome tree on an NFS mount that is briefly down would otherwise flip
    // every global SNP to failed, and with it every project that uses one.
    final parent = dir.parent;
    if (!await parent.exists()) {
      session.log(
        'Skipping SNP ${snp.id}: ${parent.path} is not there, which looks like '
        'an unmounted filesystem rather than a deletion.',
        level: LogLevel.warning,
      );
      return;
    }

    if (!await dir.exists()) {
      await _fail(
        session,
        snp,
        'The files for this SNP are no longer on disk.',
      );
      return;
    }

    final found = snpFilesIn(dir.listSync());
    if (found.vcf == null) {
      await _fail(session, snp, 'The VCF for this SNP is no longer on disk.');
      return;
    }

    if (found.tbi == null) {
      // A live `tabix` run is the one case where the index legitimately is not
      // there yet, and the heartbeat is what tells that apart from an index that
      // is simply gone. Without this check a reconcile would keep overwriting the
      // status of a job that is still working.
      if (snp.status == SnpImportStatus.indexing) {
        await _failIfStale(session, snp);
        return;
      }
      // Self-heal: the index can simply be rebuilt. Done inline, because a
      // collect is already off the request path and this only happens for an SNP
      // that has actually lost its index — not on every pass.
      snp.vcfPath = found.vcf!.path;
      snp.tbiPath = '';
      await Snp.db.updateRow(session, snp);
      session.log(
        'SNP ${snp.id} has lost its tabix index; rebuilding it.',
        level: LogLevel.warning,
      );
      await buildTabixIndex(session, snp);
      return;
    }

    final size = await _files.getDirSize(dir.path);
    final unchanged =
        snp.vcfPath == found.vcf!.path &&
        snp.tbiPath == found.tbi!.path &&
        snp.size == size &&
        snp.status == SnpImportStatus.ready;
    if (unchanged) return;

    snp
      ..vcfPath = found.vcf!.path
      ..tbiPath = found.tbi!.path
      ..size = size
      ..status = SnpImportStatus.ready
      ..statusMessage = ''
      ..statusUpdated = DateTime.now().toUtc();
    await Snp.db.updateRow(session, snp);
    session.log('Refreshed SNP ${snp.id} from disk', level: LogLevel.info);
  }

  /// Pass 3: sweep stale partials, and notice directories with no row.
  Future<void> _sweep(Session session) async {
    final root = await userRoot(session);
    if (!await root.exists()) return;

    final cutoff = DateTime.now().toUtc().subtract(incomingSweepAfter);
    for (final dir in root.listSync().whereType<Directory>()) {
      final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final id = int.tryParse(name);
      if (id == null) continue;

      if (await Snp.db.findById(session, id) == null) {
        // ⚠️ Left alone on purpose. This is what a create that crashed halfway
        // leaves behind, and a reconcile pass has no business deleting user data
        // it cannot account for. An administrator can clear it out by hand.
        session.log(
          'Orphaned custom SNP directory with no row: ${dir.path}',
          level: LogLevel.warning,
        );
        continue;
      }

      final incoming = Directory('${dir.path}/$incomingDirName');
      if (!await incoming.exists()) continue;
      for (final partial in incoming.listSync().whereType<File>()) {
        if (partial.statSync().modified.toUtc().isAfter(cutoff)) continue;
        try {
          await partial.delete();
          session.log(
            'Swept an abandoned partial upload: ${partial.path}',
            level: LogLevel.info,
          );
        } catch (_) {
          // A leftover in a staging directory is not worth failing a scan over.
        }
      }
    }
  }

  /// Fails a row whose heartbeat has stopped.
  ///
  /// The only way to notice work that died with the process that was doing it:
  /// nothing else is left to write a terminal state, so a `downloading` or
  /// `indexing` row would otherwise sit there for good.
  Future<void> _failIfStale(Session session, Snp snp) async {
    final beat = snp.statusUpdated;
    if (beat != null &&
        DateTime.now().toUtc().difference(beat) < stuckImportAfter) {
      return;
    }
    await _fail(
      session,
      snp,
      'Interrupted — the server stopped while this was being imported. '
      'Retry to start again.',
    );
  }

  /// Fails a slot whose files are never going to arrive.
  ///
  /// ⚠️ `pending` used to return early from the reconcile pass — "the bytes
  /// belong to whoever is fetching them" — which is right while something *is*
  /// fetching and wrong the moment nothing is. Closing the browser tab during a
  /// `PUT` leaves precisely that: a row reading **Queued**, an empty directory,
  /// and nothing anywhere that will ever write a terminal state. It sat there
  /// for good, and the only way out was an overflow-menu item most people never
  /// found.
  ///
  /// ⚠️ **The clock is the newest write inside the folder, not `statusUpdated`.**
  /// A browser upload is one long `PUT` that never touches the row, so a 1.5 GB
  /// transfer over a slow link looks motionless to anything measured from the
  /// database — and timing out on that would kill live uploads, which is a far
  /// worse bug than the one being fixed. The `.part` file under `incoming/` grows
  /// throughout, and is the only honest heartbeat available.
  Future<void> _failIfAbandoned(Session session, Snp snp) async {
    final beat =
        await _newestWriteIn(snp.folder) ?? snp.statusUpdated ?? snp.created;
    if (DateTime.now().toUtc().difference(beat.toUtc()) < stuckImportAfter) {
      return;
    }

    // A URL import is waiting on a future call, an upload on a browser. Both end
    // up here, and only one of them can be retried without the user doing
    // anything, so they must not read the same.
    final fromUrl = snp.sourceVcfUrl?.isNotEmpty ?? false;
    await _fail(
      session,
      snp,
      fromUrl
          ? 'Interrupted — the download never started. Retry to try again.'
          : 'No files arrived. The upload was interrupted, most likely by the '
                'browser tab closing before it finished. Upload the set again.',
    );
  }

  /// The most recent modification time of any **file** under [folder], or null
  /// when there are none.
  ///
  /// Recursive, because an upload in flight is a `.part` file one level down in
  /// `.incoming/` rather than anything in the folder itself.
  ///
  /// ⚠️ **Files only, never directories.** A directory's mtime moves when an
  /// entry is added to it, so `.incoming/` reads as *just now* from the moment it
  /// is created and then never again — which makes an abandoned upload look alive
  /// for as long as its stale `.part` sits inside. Found by the test that puts an
  /// hours-old `.part` in a freshly made `.incoming/`.
  Future<DateTime?> _newestWriteIn(String folder) async {
    if (folder.isEmpty) return null;
    final dir = Directory(folder);
    if (!await dir.exists()) return null;

    DateTime? newest;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final at = (await entity.stat()).modified.toUtc();
        if (newest == null || at.isAfter(newest)) newest = at;
      } catch (_) {
        // A file that went away between the listing and the stat — the upload
        // finishing, most likely — is not worth failing a scan over.
      }
    }
    return newest;
  }

  /// Records that an upload died before it finished.
  ///
  /// ⚠️ Called by the upload route from the socket-dropped and truncated-body
  /// paths, which is the *only* place that learns about it as it happens. The
  /// route already discards the half-written `.part` there; without this the row
  /// itself was left saying **Queued** and only the timer below would ever
  /// settle it — half an hour later, and only on the next reconcile pass.
  ///
  /// Re-reads the row rather than trusting the one the route has been holding
  /// for the length of a multi-gigabyte transfer, and refuses to touch anything
  /// that has since become `ready`: a second upload racing a settled set must not
  /// mark it broken.
  Future<void> failInterruptedUpload(
    Session session,
    int snpId,
    String message,
  ) async {
    final snp = await Snp.db.findById(session, snpId);
    if (snp == null) return;
    if (snp.status != SnpImportStatus.pending &&
        snp.status != SnpImportStatus.failed) {
      return;
    }
    await _fail(session, snp, message);
  }

  Future<void> _fail(Session session, Snp snp, String message) async {
    if (snp.status == SnpImportStatus.failed && snp.statusMessage == message) {
      return;
    }
    snp
      ..status = SnpImportStatus.failed
      ..statusMessage = message
      ..vcfPath = ''
      ..tbiPath = ''
      ..size = 0
      ..statusUpdated = DateTime.now().toUtc();
    await Snp.db.updateRow(session, snp);
    session.log(
      'SNP ${snp.id} marked failed: $message',
      level: LogLevel.warning,
    );
  }

  // ----------------------------------------------------------------- upload ---

  /// Where an uploaded file may be written, or null if it may not be.
  ///
  /// Returns the staging path and the final path. Null for every refusal — a bad
  /// name, a row that is not accepting files, a file already there, a directory
  /// that resolves outside the tree — so the route can answer one
  /// indistinguishable status and a prober cannot tell them apart.
  ///
  /// ⚠️ **The name check runs before anything is created.**
  /// `FileService.resolveProjectFile` can verify containment after resolving
  /// symlinks because the file it guards already exists; an upload makes the
  /// file, so [snpUploadFileKind] is a gate rather than a verification.
  Future<({File partial, File target})?> resolveUploadTarget(
    Session session,
    Snp snp,
    String fileName,
  ) async {
    if (snpUploadFileKind(fileName) == null) {
      session.log(
        'Refused an upload name that is not a bare .vcf.gz or .vcf.gz.tbi, '
        'for SNP ${snp.id}',
        level: LogLevel.warning,
      );
      return null;
    }

    // Only a row that is waiting for files, or one being retried after a bad
    // upload. An SNP that is already ready must not take new bytes: that would
    // swap the contents under something already indexed and possibly shared.
    if (snp.status != SnpImportStatus.pending &&
        snp.status != SnpImportStatus.failed) {
      session.log(
        'Refused an upload to SNP ${snp.id}: it is ${snp.status.name}.',
        level: LogLevel.warning,
      );
      return null;
    }

    if (snp.folder.isEmpty) return null;
    final dir = Directory(snp.folder);
    if (!await dir.exists()) return null;

    // The same containment check the download guard makes, for the same reason:
    // a symlink planted in the directory must not let a write land outside it.
    final root = await (await customSnpRoot(session)).resolveSymbolicLinks();
    final resolved = await dir.resolveSymbolicLinks();
    if (!resolved.startsWith('$root/')) {
      session.log(
        'Refused an upload resolving outside the custom SNP tree, for SNP '
        '${snp.id}',
        level: LogLevel.warning,
      );
      return null;
    }

    final target = File('${dir.path}/$fileName');
    if (await target.exists()) {
      session.log(
        'Refused an upload that would overwrite ${target.path}',
        level: LogLevel.warning,
      );
      return null;
    }

    final incoming = await createIncomingDirectory(dir);
    return (partial: File('${incoming.path}/$fileName.part'), target: target);
  }

  /// Works out what arrived in [snp]'s directory and settles its status.
  ///
  /// The client says when it has finished, but not what it managed to send, so
  /// this reads the directory. A browser that dropped the second `PUT` cannot
  /// leave a row claiming to be complete.
  Future<void> settleUpload(Session session, Snp snp) async {
    final dir = Directory(snp.folder);
    if (snp.folder.isEmpty || !await dir.exists()) {
      await _fail(session, snp, 'No files arrived.');
      return;
    }

    final entries = dir.listSync();
    final vcfs = entries
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.endsWith('.vcf.gz'))
        .toList();

    if (vcfs.isEmpty) {
      await _fail(
        session,
        snp,
        'No .vcf.gz file arrived. Upload one and try again.',
      );
      return;
    }
    if (vcfs.length > 1) {
      // Cannot happen through the route, which refuses an overwrite and only
      // accepts two names — but a hand-populated directory could do it, and
      // guessing which VCF was meant is worse than saying so.
      await _fail(
        session,
        snp,
        'More than one .vcf.gz is in this SNP set; remove all but one.',
      );
      return;
    }

    final found = snpFilesIn(entries);
    snp.vcfPath = found.vcf!.path;

    // ⚠️ Checked on *both* branches. When an index was uploaded alongside the
    // VCF, tabix never runs — so without this, nothing whatsoever would look at
    // the bytes, and a truncated VCF would be marked ready on the strength of
    // two files simply being present.
    final problem = await vcfProblem(found.vcf!);
    if (problem != null) {
      await _fail(session, snp, problem);
      return;
    }

    if (found.tbi != null) {
      snp
        ..tbiPath = found.tbi!.path
        ..size = await _files.getDirSize(dir.path)
        ..status = SnpImportStatus.ready
        ..statusMessage = ''
        ..statusUpdated = DateTime.now().toUtc();
      await Snp.db.updateRow(session, snp);
      session.log('Upload of SNP ${snp.id} finished', level: LogLevel.info);
      return;
    }

    // No index was sent, so build one.
    snp.tbiPath = '';
    await Snp.db.updateRow(session, snp);
    await buildTabixIndex(session, snp);
  }

  // ----------------------------------------------------------------- import ---

  /// The largest single file the server will fetch or accept.
  ///
  /// dbSNP's `00-common_all.vcf.gz` is about 1.6 GB, so this leaves generous room
  /// while still bounding what one paste can cost in disk and transfer.
  static const maxImportBytes = 4 * 1024 * 1024 * 1024;

  /// Schedules [snp]'s import to run.
  ///
  /// A separate method, mirroring `GenomeService.scheduleIndexProgressCheck`,
  /// precisely so a test can subclass and stub it out — the future-call scheduler
  /// needs machinery the test harness does not run.
  Future<void> scheduleSnpImport(Session session, Snp snp) async {
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero)
        .importSnp
        .run(snp);
  }

  /// Fetches [snpId]'s files and gets it to `ready`, or to `failed`.
  ///
  /// The body of [ImportSnpFutureCall]. Reloads the row rather than trusting the
  /// one handed to the future call, which was serialised when the import was
  /// scheduled and may since have been renamed, shared or deleted.
  ///
  /// Never throws: a terminal status somebody can read is the whole product here,
  /// and an escaping exception would leave the row stuck at `downloading` forever.
  Future<void> runImport(Session session, int snpId) async {
    final snp = await Snp.db.findById(session, snpId);
    if (snp == null) {
      session.log(
        'Import for SNP $snpId abandoned: the row is gone.',
        level: LogLevel.info,
      );
      return;
    }

    // Guards a double-schedule, and a retry racing the original.
    if (snp.status != SnpImportStatus.pending) {
      session.log(
        'Import for SNP $snpId skipped: it is ${snp.status.name}, not pending.',
        level: LogLevel.info,
      );
      return;
    }

    final vcfUrl = snp.sourceVcfUrl;
    if (vcfUrl == null || vcfUrl.isEmpty) {
      await _fail(session, snp, 'This SNP set has no download address.');
      return;
    }

    Directory? incoming;
    try {
      final settings = await _settings.getSettings(session);
      final allowedHosts = parseAllowedHosts(settings.snpSourceAllowedHosts);
      final dir = await createUserDirectory(session, snpId);
      incoming = await createIncomingDirectory(dir);

      await _setStatus(
        session,
        snp,
        SnpImportStatus.downloading,
        'Fetching the VCF',
      );

      final vcfName = fileNameFromUrl(vcfUrl) ?? 'snp-$snpId.vcf.gz';
      final vcf = await _fetch(
        session,
        snp,
        url: vcfUrl,
        name: vcfName,
        dir: dir,
        incoming: incoming,
        allowedHosts: allowedHosts,
      );
      snp.vcfPath = vcf.path;

      final tbiUrl = snp.sourceTbiUrl;
      if (tbiUrl != null && tbiUrl.isNotEmpty) {
        await _setStatus(
          session,
          snp,
          SnpImportStatus.downloading,
          'Fetching the tabix index',
        );
        final tbi = await _fetch(
          session,
          snp,
          url: tbiUrl,
          name: '$vcfName.tbi',
          dir: dir,
          incoming: incoming,
          allowedHosts: allowedHosts,
        );
        // Same reason as the upload path: an index that came with the file means
        // tabix never runs, so this is the only thing that looks at the bytes.
        final problem = await vcfProblem(vcf);
        if (problem != null) {
          await _fail(session, snp, problem);
          return;
        }
        snp
          ..tbiPath = tbi.path
          ..size = await _files.getDirSize(dir.path)
          ..status = SnpImportStatus.ready
          ..statusMessage = ''
          ..statusUpdated = DateTime.now().toUtc();
        await Snp.db.updateRow(session, snp);
        session.log('Imported SNP $snpId from its URLs', level: LogLevel.info);
        return;
      }

      // No index was given, so build one. Inline rather than on another future
      // call: this one is already off the request path, and splitting it would
      // only add a state in which nothing owns the work.
      await Snp.db.updateRow(session, snp);
      await buildTabixIndex(session, snp);
    } on SnpDownloadException catch (e) {
      await _fail(session, snp, e.message);
    } catch (e, stackTrace) {
      session.log(
        'Importing SNP $snpId failed.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      await _fail(session, snp, 'The import failed unexpectedly.');
    } finally {
      // Whatever happened, nothing half-written should be left where the next
      // reconcile could find it.
      if (incoming != null) {
        try {
          if (await incoming.exists()) {
            await incoming.delete(recursive: true);
          }
        } catch (_) {}
      }
    }
  }

  /// Downloads one file into `.incoming/` and renames it into place.
  ///
  /// The rename is what makes a partial file impossible to mistake for a finished
  /// one: it is atomic within a filesystem, so the SNP directory never holds a
  /// truncated file under a real name.
  Future<File> _fetch(
    Session session,
    Snp snp, {
    required String url,
    required String name,
    required Directory dir,
    required Directory incoming,
    required List<String> allowedHosts,
  }) async {
    final partial = File('${incoming.path}/$name.part');
    await sl<SnpDownloader>().download(
      Uri.parse(url),
      partial,
      maxBytes: maxImportBytes,
      allowedHosts: allowedHosts,
      onProgress: (received, total) async {
        // ⚠️ The downloader already throttles this to one call every couple of
        // seconds. Unthrottled, a 1 GB fetch at 64 kB a chunk would be sixteen
        // thousand UPDATE statements.
        snp
          ..bytesDownloaded = received
          ..totalBytes = total ?? 0
          ..statusUpdated = DateTime.now().toUtc();
        await Snp.db.updateRow(session, snp);
      },
    );

    final target = File('${dir.path}/$name');
    if (await target.exists()) await target.delete();
    return partial.rename(target.path);
  }

  /// The comma-separated allowlist, split and tidied.
  static List<String> parseAllowedHosts(String raw) =>
      raw.split(',').map((h) => h.trim()).where((h) => h.isNotEmpty).toList();

  /// The last path segment of [url] if it is a usable SNP file name, else null.
  ///
  /// ⚠️ Passed through [snpUploadFileKind], so a remote server cannot dictate a
  /// name: a URL ending in `../../etc/passwd` or `x.sh` yields null and the caller
  /// falls back to a name it made up itself.
  static String? fileNameFromUrl(String url) {
    final segments = Uri.tryParse(url)?.pathSegments;
    if (segments == null || segments.isEmpty) return null;
    final last = segments.last;
    return snpUploadFileKind(last) == SnpFileKind.vcf ? last : null;
  }

  // --------------------------------------------------------------- indexing ---

  /// Builds the missing `.vcf.gz.tbi` beside [snp]'s VCF, then marks it ready.
  ///
  /// Called from three places: after an upload that carried no index, from the
  /// import job when no `.tbi` URL was given, and from [retryIndexing].
  ///
  /// Sets `ready` on success and `failed` with something actionable on every
  /// failure. Never throws — it runs inside a future call, where an escaping
  /// exception is a log line nobody reads instead of a status somebody can see.
  Future<void> buildTabixIndex(Session session, Snp snp) async {
    try {
      final vcf = File(snp.vcfPath);
      if (snp.vcfPath.isEmpty || !await vcf.exists()) {
        await _fail(session, snp, 'The VCF to index is not on disk.');
        return;
      }

      // ⚠️ Checked before tabix is asked, and not only because a plain-gzip VCF
      // is the commonest mistake with a diagnostic no biologist should have to
      // decode. The truncation check matters more: tabix indexes a file missing
      // its EOF marker *successfully*, so asking it first would let a half-
      // arrived file through.
      final problem = await vcfProblem(vcf);
      if (problem != null) {
        await _fail(session, snp, problem);
        return;
      }

      await _setStatus(
        session,
        snp,
        SnpImportStatus.indexing,
        'Building the tabix index',
      );

      final result = await sl<ProcessRunner>().run(
        'tabix',
        ['-p', 'vcf', snp.vcfPath],
        workingDirectory: snp.folder,
        // ⚠️ `false`, unlike every other ProcessRunner call site in this
        // codebase. The path is server-generated and the argv is fixed, so there
        // is no reason whatsoever to interpose a shell — and not doing so removes
        // the question of whether it could matter.
        runInShell: false,
        // Indexing dbSNP takes seconds, not minutes. A deadline matters here
        // because this runs inside a future call: without one, a wedged tabix
        // leaves the SNP set at `indexing` until the 30-minute reconcile
        // eventually calls it dead, and the process itself never goes away.
        timeout: indexingTimeout,
      );

      if (result.exitCode != 0) {
        // An unsorted VCF is the second commonest failure and tabix says so
        // itself, so its own words are more use than anything paraphrased. Do
        // not try to sort it: that is bcftools, another tool and twice the disk.
        final reason = firstLineOf(result.stderr.toString());
        await _fail(
          session,
          snp,
          reason.isEmpty
              ? 'tabix could not index that file (exit ${result.exitCode}).'
              : 'tabix could not index that file: $reason',
        );
        return;
      }

      final tbi = File('${snp.vcfPath}.tbi');
      if (!await tbi.exists()) {
        await _fail(
          session,
          snp,
          'tabix reported success but wrote no index file.',
        );
        return;
      }

      snp
        ..tbiPath = tbi.path
        ..size = await _files.getDirSize(snp.folder)
        ..status = SnpImportStatus.ready
        ..statusMessage = ''
        ..statusUpdated = DateTime.now().toUtc();
      await Snp.db.updateRow(session, snp);
      session.log('Indexed SNP ${snp.id}', level: LogLevel.info);
    } catch (e, stackTrace) {
      session.log(
        'Indexing SNP ${snp.id} failed.',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      await _fail(session, snp, 'Indexing failed unexpectedly.');
    }
  }

  /// Moves [snp] to [status], stamping the heartbeat.
  Future<void> _setStatus(
    Session session,
    Snp snp,
    SnpImportStatus status,
    String message,
  ) async {
    snp
      ..status = status
      ..statusMessage = message
      ..statusUpdated = DateTime.now().toUtc();
    await Snp.db.updateRow(session, snp);
  }

  /// The first [count] bytes of [file], or fewer if it is shorter.
  ///
  /// Streamed rather than read whole: this is called on files up to a couple of
  /// gigabytes, and only the header matters.
  Future<List<int>> _firstBytes(File file, int count) async {
    final handle = await file.open();
    try {
      return await handle.read(count);
    } finally {
      await handle.close();
    }
  }

  // ---------------------------------------------------------------- delete ---

  /// The projects currently pointing at SNP [snpId].
  ///
  /// Shown in the delete confirmation, so nobody removes a file three running
  /// designs depend on without being told which three.
  Future<List<SnpUsageDto>> snpUsage(Session session, int snpId) async {
    final projects = await Project.db.find(
      session,
      where: (t) => t.snp.equals(snpId),
    );
    return projects
        .map((p) => SnpUsageDto(projectId: p.id!, projectName: p.name))
        .toList();
  }

  /// Deletes [snp]'s files and then its row.
  ///
  /// ⚠️ **Files first, row second, and abort if the files survive.** That
  /// ordering is the entire answer to "does a re-scan bring it back?" — the
  /// scanner only creates a row for a directory that exists and holds both files,
  /// so once the directory is gone there is nothing left to find. Deleting the row
  /// first and the files second would leave a window, and a failure in between
  /// (read-only mount, permissions, a busy NFS handle) would resurrect the SNP
  /// under a new id on the next collect. Failing here instead leaves it fully
  /// intact, which is the recoverable outcome.
  ///
  /// Deleting the row nulls `Project.snp` on every project that used it, through
  /// the foreign key.
  Future<void> deleteSnp(Session session, Snp snp) async {
    final dir = Directory(snp.folder);
    if (snp.folder.isNotEmpty) {
      await _refuseSuspiciousFolder(session, snp);
    }
    if (snp.folder.isNotEmpty && await dir.exists()) {
      await dir.delete(recursive: true);
      if (await dir.exists()) {
        session.log(
          'Refusing to delete SNP ${snp.id}: ${snp.folder} is still there.',
          level: LogLevel.error,
        );
        throw ArgumentException(
          message:
              'The files could not be removed, so the SNP was left alone. '
              'Check the permissions on ${snp.folder}.',
        );
      }
    }

    await Snp.db.deleteRow(session, snp);

    session.log(
      'Deleted SNP ${snp.id} "${snp.name}" and its files at ${snp.folder}',
      level: LogLevel.warning,
    );
  }

  /// Refuses to recursively delete anything that is not inside one of the two
  /// directories SNP files are allowed to live in.
  ///
  /// `folder` is written by this codebase and never by a user, so this should be
  /// unreachable — which is exactly why it is worth having. A corrupted or
  /// hand-edited row is otherwise a recursive delete of whatever it names.
  ///
  /// An **empty** folder is not checked here and not an error: it means the row
  /// never got as far as having files, and refusing it would leave a half-created
  /// SNP that nobody, not even an administrator, could ever clean up.
  Future<void> _refuseSuspiciousFolder(Session session, Snp snp) async {
    final settings = await _settings.getSettings(session);
    final roots = [
      settings.genomeDir,
      settings.customSnpDir,
    ].where((r) => r.isNotEmpty).map((r) => r.endsWith('/') ? r : '$r/');

    if (roots.any(snp.folder.startsWith)) return;

    session.log(
      'Refusing to delete SNP ${snp.id}: "${snp.folder}" is outside both the '
      'genome and custom SNP directories.',
      level: LogLevel.error,
    );
    throw ArgumentException(
      message:
          'This SNP records a file location that cannot be deleted safely.',
    );
  }
}
