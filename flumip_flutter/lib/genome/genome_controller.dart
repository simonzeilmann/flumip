import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import '../error_text.dart';
import '../poll.dart';

/// The genome tab: the category rail, the selected genome, and the poll that
/// watches an index being built.
///
/// Every piece of I/O is a constructor parameter, so this runs on the Dart VM
/// with no server — same shape as `ProjectsController`. What it adds over that
/// one is a timer, a failure backoff and a mutation guard, which are the three
/// things in this tab that were subtle and untested.
class GenomeController extends ChangeNotifier {
  GenomeController({
    required this._loadCategories,
    required this._loadGenomes,
    required this._loadGenome,
    required this._indexGenome,
    required this._deleteIndex,
    required this._updateGenome,
    required this._scanForGenomes,
    required this._recheckSnpSets,
  });

  final Future<List<String>> Function() _loadCategories;
  final Future<List<Genome>> Function(String category) _loadGenomes;
  final Future<Genome> Function(int genomeId) _loadGenome;
  final Future<void> Function(int genomeId) _indexGenome;
  final Future<void> Function(int genomeId) _deleteIndex;
  final Future<void> Function(int genomeId, Genome genome) _updateGenome;
  final Future<void> Function() _scanForGenomes;
  final Future<void> Function() _recheckSnpSets;

  List<String> _categories = const [];
  List<Genome> _genomes = const [];
  Genome? _selectedGenome;
  String? _expandedCategory;
  String? _loadingCategory;

  /// Split by cause, so a message appears next to the thing it explains.
  ///
  /// There used to be one error, rendered below a full-height `Expanded` at the
  /// very bottom of the tab — about as far from whatever caused it as the layout
  /// allowed.
  String? _railError;
  String? _detailError;

  Timer? _timer;
  int _failures = 0;
  bool _disposed = false;

  /// True while a change of ours is in flight.
  ///
  /// ⚠️ Guards against the poll landing mid-update and putting the Active switch
  /// back. The old code had a `ValueNotifier` for the switch that the poll wrote
  /// to on every tick, which is precisely how a toggle got stomped.
  bool _mutating = false;

  final _messages = StreamController<String>.broadcast();

  List<String> get categories => _categories;
  List<Genome> get genomes => _genomes;
  Genome? get selectedGenome => _selectedGenome;
  String? get expandedCategory => _expandedCategory;
  String? get loadingCategory => _loadingCategory;
  String? get railError => _railError;
  String? get detailError => _detailError;

  /// One-off reports of something the user just did — the tab turns these into
  /// snack bars.
  ///
  /// A stream rather than a field because they are events, not state: two
  /// identical messages in a row are two messages, and nothing should re-show
  /// one on the next rebuild. Broadcast, so nothing accumulates when the tab is
  /// not listening.
  Stream<String> get messages => _messages.stream;

  /// Whether a tick is actually pending. For tests.
  ///
  /// ⚠️ `isActive`, not `_timer != null`. A one-shot `Timer` stays referenced
  /// after it has fired, so the field alone reports "there was a poll" rather
  /// than "there is one".
  @visibleForTesting
  bool get polling => _timer?.isActive ?? false;

  Future<void> load() => refreshCategories();

  Future<void> refreshCategories() async {
    try {
      final categories = await _loadCategories();
      // Sorted on our own copy: the list belongs to the caller, and an
      // unmodifiable one would throw.
      _categories = [...categories]..sort();
      _railError = null;
    } catch (e) {
      _railError = describeError(e);
    }
    _notify();
  }

  void toggleCategory(String? category) {
    _expandedCategory = category;
    _genomes = const [];
    _loadingCategory = category;
    _notify();
    if (category != null) _refreshGenomes(category);
  }

  Future<void> _refreshGenomes(String category) async {
    try {
      final genomes = await _loadGenomes(category);
      // ⚠️ A late answer for a category that has since been closed, or swapped
      // for another, must not land. Without this the rail can end up listing one
      // category's genomes under another's heading.
      if (_expandedCategory != category) return;
      _genomes = [...genomes]..sort((a, b) => a.name.compareTo(b.name));
      _loadingCategory = null;
      _railError = null;
    } catch (e) {
      _loadingCategory = null;
      _railError = describeError(e);
    }
    _notify();
  }

  void selectGenome(Genome genome) {
    _selectedGenome = genome;
    _detailError = null;
    _failures = 0;
    _notify();
    refreshSelected();
  }

  /// Shows [genomeId], opening [category] in the rail on the way. A search result.
  ///
  /// Selects by id rather than by row, so it works for a genome in a category
  /// nobody has opened yet — which is most of them, and the reason searching for a
  /// genome is worth anything.
  ///
  /// The two halves land independently: [toggleCategory] kicks off its own fetch
  /// for the rail while this one fetches the genome for the detail pane. A null
  /// [category] is skipped rather than passed on, because `toggleCategory(null)`
  /// *closes* the rail — the opposite of what revealing wants.
  Future<void> revealGenome(int genomeId, String? category) async {
    if (category != null && _expandedCategory != category) {
      toggleCategory(category);
    }
    try {
      _selectedGenome = await _loadGenome(genomeId);
      _detailError = null;
      _failures = 0;
      _notify();
      _rearm();
    } catch (e) {
      _detailError = describeError(e);
      _notify();
    }
  }

  /// Drops the selection and stops the poll. The narrow layout's back button.
  void clearSelection() {
    _selectedGenome = null;
    _timer?.cancel();
    _timer = null;
    _notify();
  }

  /// Re-reads the selected genome.
  ///
  /// [quiet] is for the poll: a failed background refresh should back the poll
  /// off, not put an error banner over a pane the user is reading.
  Future<void> refreshSelected({bool quiet = false}) async {
    final id = _selectedGenome?.id;
    if (id == null) return;
    try {
      final genome = await _loadGenome(id);
      // The user started a change while this was in flight; theirs wins.
      if (_mutating) return;
      _detailError = null;
      _failures = 0;
      _selectedGenome = genome;
      _notify();
      _rearm();
    } catch (e) {
      _failures++;
      if (!quiet) _detailError = describeError(e);
      _notify();
      // Nothing will change while access is refused, so stop asking.
      //
      // ⚠️ Cancel, rather than merely declining to schedule another. The old
      // code just skipped the re-arm, which leaves whatever was already
      // scheduled to fire once more — so a revoked session still got one further
      // refusal, and a refusal arriving while a tick was pending got a tick
      // after it. Found by the test.
      if (isAccessDenied(e)) {
        _timer?.cancel();
        _timer = null;
      } else {
        _rearm();
      }
    }
  }

  /// Schedules the next read of the selected genome, or stops.
  ///
  /// ⚠️ Was `Timer.periodic(5s)`, firing for as long as a genome was selected
  /// and rebuilding the whole tab twelve times a minute — for data that cannot
  /// change on its own. A genome's `active` flag is toggled here and indexing is
  /// started here; the one thing that progresses without us is an index being
  /// built. See [genomePollInterval].
  void _rearm() {
    _timer?.cancel();
    _timer = null;

    final genome = _selectedGenome;
    if (genome == null) return;

    final wait = genomePollInterval(
      indexing: genome.indexing,
      consecutiveFailures: _failures,
    );
    if (wait == null) return;

    _timer = Timer(wait, () {
      if (_disposed || _mutating) return;
      refreshSelected(quiet: true);
    });
  }

  Future<void> indexGenome() =>
      _mutate((id) => _indexGenome(id), 'Could not start indexing');

  Future<void> deleteIndex() =>
      _mutate((id) => _deleteIndex(id), 'Could not delete the index');

  /// Runs a change against the selected genome, then re-reads it.
  ///
  /// Failures are reported through [messages] rather than the pane's banner: an
  /// action the user just took reports where they are looking, whereas a banner
  /// explains the state of something on screen.
  Future<void> _mutate(
    Future<void> Function(int genomeId) action,
    String whatFailed,
  ) async {
    final id = _selectedGenome?.id;
    if (id == null) return;
    _mutating = true;
    try {
      await action(id);
      _mutating = false;
      await refreshSelected();
    } catch (e) {
      _mutating = false;
      _say('$whatFailed: ${describeError(e)}');
    }
  }

  /// Turns the genome on or off for new projects.
  ///
  /// ⚠️ Optimistic, with a rollback. Without the rollback the switch stayed where
  /// the user left it even though the server had refused, so the interface
  /// asserted something untrue until the next poll happened to correct it.
  Future<void> toggleActive(bool value) async {
    final genome = _selectedGenome;
    if (genome == null) return;
    final previous = genome.active;

    genome.active = value;
    _notify();
    _mutating = true;
    try {
      await _updateGenome(genome.id!, genome);
      _mutating = false;
    } catch (e) {
      _mutating = false;
      genome.active = previous;
      _detailError = 'Could not change the genome: ${describeError(e)}';
      _notify();
    }
  }

  Future<void> scanForGenomes() async {
    try {
      await _scanForGenomes();
      await refreshCategories();
      final open = _expandedCategory;
      if (open != null) await _refreshGenomes(open);
      _say('Scanned for new genomes.');
    } catch (e) {
      _say('Could not scan for genomes: ${describeError(e)}');
    }
  }

  Future<void> recheckSnpSets() async {
    try {
      await _recheckSnpSets();
      await refreshSelected();
      _say('Rechecked the custom SNP sets.');
    } catch (e) {
      _say('Could not recheck the SNP sets: ${describeError(e)}');
    }
  }

  void dismissRailError() {
    _railError = null;
    _notify();
  }

  void dismissDetailError() {
    _detailError = null;
    _notify();
  }

  void _say(String message) {
    if (_disposed) return;
    _messages.add(message);
  }

  /// ⚠️ Guarded, because every method here awaits at least one round trip and
  /// the tab can be disposed while one is in flight — notifying a disposed
  /// `ChangeNotifier` throws, and Flutter paints that over the whole tab.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _messages.close();
    super.dispose();
  }
}
