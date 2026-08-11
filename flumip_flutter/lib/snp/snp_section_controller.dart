import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import '../error_text.dart';
import 'picked_file.dart';
import 'snp_status.dart';
import 'snp_upload_controller.dart';

/// The SNP sets for one genome, and everything that can be done to them.
///
/// Every piece of I/O is a constructor parameter, so this runs on the Dart VM
/// with no server. What it does *not* own is anything needing a `BuildContext`:
/// the four dialogs stay in `SnpSection`, which calls in here with whatever they
/// returned.
///
/// ⚠️ [uploads] is a whole controller rather than a set of closures, because it
/// is already injectable — `SnpUploadController` takes its transport as a
/// parameter and has its own tests. Passing it through keeps one owner for a
/// transfer that has to outlive this widget.
class SnpSectionController extends ChangeNotifier {
  SnpSectionController({
    required int genomeId,
    required Future<List<Snp>> Function(int genomeId) loadSnps,
    required Future<List<Snp>> Function() loadMySnps,
    required Future<void> Function(int snpId, bool shared) setShared,
    required Future<void> Function(int snpId, String name, String description)
    rename,
    required Future<void> Function(int snpId) retryImport,
    required Future<void> Function(int snpId) cancelUpload,
    required Future<void> Function(int snpId) deleteSnp,
    required Future<void> Function(
      int snpId,
      String? password, {
      required bool force,
    })
    deleteAsAdmin,
    required Future<List<SnpUsageDto>> Function(int snpId) loadUsage,
    required Future<void> Function(CustomSnpRequestDto request) importFromUrls,
    required Future<Snp> Function(CustomSnpRequestDto request) createUpload,
    required SnpUploadController uploads,
    required bool Function() isAdmin,
    Listenable? auth,
    Listenable? access,
  }) : _genomeId = genomeId,
       _loadSnps = loadSnps,
       _loadMySnps = loadMySnps,
       _setShared = setShared,
       _rename = rename,
       _retryImport = retryImport,
       _cancelUpload = cancelUpload,
       _deleteSnp = deleteSnp,
       _deleteAsAdmin = deleteAsAdmin,
       _loadUsage = loadUsage,
       _importFromUrls = importFromUrls,
       _createUpload = createUpload,
       uploads = uploads,
       _isAdmin = isAdmin,
       _auth = auth,
       _access = access {
    _auth?.addListener(_onAuthChanged);
    _access?.addListener(_notify);
    // An upload's progress is only known in this browser — the server cannot see
    // how far a PUT has got until it lands — so the bar is driven from here.
    uploads.addListener(_notify);
  }

  int _genomeId;
  final Future<List<Snp>> Function(int genomeId) _loadSnps;
  final Future<List<Snp>> Function() _loadMySnps;
  final Future<void> Function(int snpId, bool shared) _setShared;
  final Future<void> Function(int snpId, String name, String description)
  _rename;
  final Future<void> Function(int snpId) _retryImport;
  final Future<void> Function(int snpId) _cancelUpload;
  final Future<void> Function(int snpId) _deleteSnp;
  final Future<void> Function(
    int snpId,
    String? password, {
    required bool force,
  })
  _deleteAsAdmin;
  final Future<List<SnpUsageDto>> Function(int snpId) _loadUsage;
  final Future<void> Function(CustomSnpRequestDto request) _importFromUrls;
  final Future<Snp> Function(CustomSnpRequestDto request) _createUpload;
  final bool Function() _isAdmin;
  final Listenable? _auth;
  final Listenable? _access;

  /// Browser uploads in flight. Read by the tiles for their progress bars.
  final SnpUploadController uploads;

  List<Snp>? _snps;

  /// The ids this caller added.
  ///
  /// ⚠️ Derived from `listMySnps` rather than compared against the session,
  /// because the session carries no user id — `SessionTokenResponse` has email,
  /// display name and the admin flag, and nothing to match `Snp.owner` against.
  Set<int> _mine = {};

  String? _errorMessage;
  Timer? _timer;
  int _failures = 0;
  bool _disposed = false;

  final _messages = StreamController<String>.broadcast();

  List<Snp>? get snps => _snps;
  String? get errorMessage => _errorMessage;

  /// Whether the server considers this caller an administrator, which decides
  /// which menu items exist and whether the admin delete asks for a password.
  bool get isAdmin => _isAdmin();

  /// One-off reports — the section turns these into snack bars.
  Stream<String> get messages => _messages.stream;

  bool isMine(Snp snp) => _mine.contains(snp.id);

  /// Whether a tick is actually pending. For tests.
  @visibleForTesting
  bool get polling => _timer?.isActive ?? false;

  /// Points the section at a different genome.
  ///
  /// Clears the list first: the previous genome's sets must not sit under the
  /// new one's heading while the fetch is in flight.
  Future<void> showGenome(int genomeId) {
    if (genomeId == _genomeId) return Future.value();
    _genomeId = genomeId;
    _snps = null;
    _notify();
    return load();
  }

  Future<void> load() async {
    try {
      final snps = await _loadSnps(_genomeId);
      final mine = await _loadMySnps();
      // ⚠️ Ordered here as well as on the server, and on our own copy. Without a
      // stable order the list reshuffles under the cursor every time a row is
      // written — a download bumping its byte count, or sharing being flipped —
      // because an unordered Postgres query returns heap order and an UPDATE
      // moves the row to the end of the heap. By id, so it stays the order the
      // sets were added in.
      _snps = [...snps]..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      _mine = mine.map((s) => s.id).nonNulls.toSet();
      _errorMessage = null;
      _failures = 0;
      _notify();
    } catch (e) {
      // A revoked session would otherwise re-report the same refusal every
      // couple of seconds, for as long as the tab is open.
      if (isAccessDenied(e)) {
        _timer?.cancel();
        _timer = null;
        _snps = const [];
        _notify();
        return;
      }
      _failures++;
      _errorMessage = 'Could not load SNP sets: ${describeError(e)}';
      _notify();
    }
    _rearm();
  }

  void _rearm() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;

    final anyLive =
        (_snps ?? const <Snp>[]).any((s) => !isTerminal(s.status)) ||
        uploads.anyLive;
    _timer = Timer(
      pollInterval(anyLive: anyLive, consecutiveFailures: _failures),
      load,
    );
  }

  /// The whole list depends on who is asking, so a change of identity has to
  /// throw the answer away rather than keep showing the previous caller's.
  void _onAuthChanged() {
    _snps = null;
    _mine = {};
    _notify();
    load();
  }

  // ------------------------------------------------------------- actions ---

  /// Turns sharing on or off.
  ///
  /// ⚠️ Optimistic, *with a rollback*. Setting the flag and never reverting it
  /// leaves the interface asserting something the server refused.
  Future<void> setShared(Snp snp, bool shared) async {
    snp.private = !shared;
    _notify();
    try {
      await _setShared(snp.id!, shared);
      await load();
    } catch (e) {
      snp.private = shared;
      _notify();
      _say('Could not change sharing: ${describeError(e)}');
    }
  }

  Future<void> rename(Snp snp, String name, String description) => _run(
    () => _rename(snp.id!, name, description),
    failure: 'Could not rename the SNP set',
  );

  Future<void> retry(Snp snp) =>
      _run(() => _retryImport(snp.id!), failure: 'Could not retry the import');

  Future<void> cancelUpload(Snp snp) => _run(
    () => _cancelUpload(snp.id!),
    failure: 'Could not cancel',
    success: 'Removed "${snp.name}".',
  );

  Future<void> delete(Snp snp) => _run(
    () => _deleteSnp(snp.id!),
    failure: 'Could not delete the SNP set',
    success: 'Deleted "${snp.name}" and its files.',
  );

  /// ⚠️ [password] is null for a signed-in administrator, who needs none — the
  /// settings password is only the administrative credential on an install that
  /// is not enforcing sign-in.
  Future<void> deleteAsAdmin(
    Snp snp,
    String? password, {
    required bool force,
  }) => _run(
    () => _deleteAsAdmin(snp.id!, password, force: force),
    failure: 'Could not delete the SNP set',
    success: 'Deleted "${snp.name}" and its files.',
  );

  /// The projects using this SNP, or null when the lookup itself failed.
  ///
  /// Read *before* the dialog opens so the confirmation can name them, rather
  /// than spinning inside it. ⚠️ Null and empty are kept apart: the dialog has to
  /// be able to say "could not check" instead of implying "nothing is using it".
  Future<List<SnpUsageDto>?> usage(Snp snp) async {
    try {
      return await _loadUsage(snp.id!);
    } catch (_) {
      return null;
    }
  }

  Future<void> importFromUrls(CustomSnpRequestDto request, String name) => _run(
    () => _importFromUrls(request),
    failure: 'Could not start the import',
    success: 'Downloading "$name" — watch its progress in the list.',
  );

  /// Creates the row, then hands the transfer to the long-lived upload
  /// controller and returns.
  ///
  /// ⚠️ The upload must not be owned by anything that can be closed: it takes
  /// minutes, and this section is rebuilt every time the genome selection
  /// changes.
  Future<void> startUpload(
    CustomSnpRequestDto request, {
    required PickedFile vcf,
    PickedFile? tbi,
  }) async {
    final Snp created;
    try {
      created = await _createUpload(request);
    } catch (e) {
      _say('Could not start the upload: ${describeError(e)}');
      return;
    }
    await load();
    uploads.start(snpId: created.id!, vcf: vcf, tbi: tbi);
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failure,
    String? success,
  }) async {
    try {
      await action();
      await load();
      if (success != null) _say(success);
    } catch (e) {
      _say('$failure: ${describeError(e)}');
    }
  }

  void dismissError() {
    _errorMessage = null;
    _notify();
  }

  void _say(String message) {
    if (_disposed) return;
    _messages.add(message);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _auth?.removeListener(_onAuthChanged);
    _access?.removeListener(_notify);
    uploads.removeListener(_notify);
    _messages.close();
    super.dispose();
  }
}
