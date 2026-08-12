import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import '../debounce.dart';
import '../error_text.dart';

/// The search box: what has been typed, what came back, and how little it asks.
///
/// Named `UnifiedSearchController` rather than `SearchController` because Material
/// has one of its own and the dialog file has both in scope.
///
/// Every piece of I/O is a constructor parameter, for the reason
/// [ProjectsController] documents: the generated Serverpod `Client` cannot be
/// faked, so dependencies arrive as functions.
///
/// ## What keeps this cheap
///
/// One request per settled query, and often none:
///
/// * queries under [minQueryLength] are not sent at all — below two characters
///   everything matches and the answer is useless;
/// * a [searchDebounce] collapses a typed word into one request;
/// * every answer is memoised by query, so backspacing and retyping are free.
///
/// Held for the life of the dialog and disposed with it — a factory in
/// `services.dart`, not an app-wide singleton, for the same reason
/// `createGenomeController` is: it owns a timer, and nothing should retain a cache
/// or an in-flight request between one search and the next.
class UnifiedSearchController extends ChangeNotifier {
  UnifiedSearchController({
    required Future<List<SearchHitDto>> Function(String query) search,
    Duration debounce = searchDebounce,
  }) : _search = search,
       _debouncer = Debouncer(debounce);

  final Future<List<SearchHitDto>> Function(String query) _search;
  final Debouncer _debouncer;

  /// Answers by the query that produced them.
  ///
  /// Cleared wholesale rather than evicted one at a time: a hard reset is fewer
  /// moving parts than an LRU, and the whole cache dies with the dialog anyway.
  final Map<String, List<SearchHitDto>> _cache = {};
  static const int _cacheLimit = 64;

  /// Shorter than this and the server would refuse anyway — it enforces the same
  /// floor, because the app is not the only possible caller.
  static const int minQueryLength = 2;

  String _query = '';
  List<SearchHitDto>? _hits;
  String? _errorMessage;
  String? _inFlight;
  bool _disposed = false;

  /// What is in the field, exactly as typed.
  String get query => _query;

  /// Whether the query is still too short to ask about.
  ///
  /// The dialog shows a hint in this state rather than an empty result list —
  /// "nothing matched" would be a lie about a question nobody has asked yet.
  bool get idle => _query.trim().length < minQueryLength;

  /// The hits, or null until the first answer for the current query arrives.
  ///
  /// ⚠️ Null and empty mean different things, as everywhere else in this app: null
  /// is "no answer yet", empty is "nothing matched".
  List<SearchHitDto>? get hits => _hits;

  String? get errorMessage => _errorMessage;

  /// True before the first answer for the current query and while nothing has
  /// gone wrong. Nothing at all can be shown in this state.
  bool get loading => !idle && _hits == null && _errorMessage == null;

  /// Whether a request is actually out on the wire.
  ///
  /// ⚠️ Not the same as [loading], and the dialog needs this one. Once an answer
  /// has landed [hits] stays non-null while the *next* query is in flight — that
  /// is the deliberate "keep the previous results up" behaviour, and it makes
  /// [loading] false for every query after the first. Driving a progress bar off
  /// [loading] therefore showed it exactly once per dialog.
  bool get busy => _inFlight != null;

  List<SearchHitDto> get projects => _ofKind(SearchHitKind.project);
  List<SearchHitDto> get genomes => _ofKind(SearchHitKind.genome);
  List<SearchHitDto> get snpSets => _ofKind(SearchHitKind.snpSet);

  /// The hit `Enter` opens, or null when there is nothing to open.
  SearchHitDto? get firstHit =>
      (_hits == null || _hits!.isEmpty) ? null : _hits!.first;

  List<SearchHitDto> _ofKind(SearchHitKind kind) =>
      _hits?.where((h) => h.kind == kind).toList() ?? const [];

  /// Records what was typed and decides whether to ask the server about it.
  void queryChanged(String value) {
    _query = value;
    final key = value.trim();

    if (key.length < minQueryLength) {
      _debouncer.cancel();
      _hits = null;
      _errorMessage = null;
      // An answer for the query that has just been deleted is no longer wanted,
      // so nothing should still look busy on its behalf.
      _inFlight = null;
      _notify();
      return;
    }

    final cached = _cache[key];
    if (cached != null) {
      // Answered without a round trip, and the pending one is dropped — this is
      // what makes deleting a character and retyping it free.
      _debouncer.cancel();
      _hits = cached;
      _errorMessage = null;
      _notify();
      return;
    }

    _debouncer.run(() => _run(key));
  }

  Future<void> _run(String key) async {
    _inFlight = key;
    _notify();
    try {
      final hits = await _search(key);
      // ⚠️ A late answer for a query the user has moved on from must not land —
      // the same guard, in the same shape, as `GenomeController._refreshGenomes`.
      // Without it a slow answer for "br" can overwrite the results for "brca".
      if (_query.trim() != key) return;
      if (_cache.length >= _cacheLimit) _cache.clear();
      _cache[key] = hits;
      _hits = hits;
      _errorMessage = null;
    } catch (e) {
      if (_query.trim() != key) return;
      _errorMessage = describeError(e);
    } finally {
      // Only the newest request owns the flag: a superseded one finishing must
      // not clear a flag that a newer one has already set.
      if (_inFlight == key) _inFlight = null;
    }
    _notify();
  }

  /// Empties the field. The clear button, and `Escape` where it does not dismiss.
  void clear() {
    _debouncer.cancel();
    _query = '';
    _hits = null;
    _errorMessage = null;
    _inFlight = null;
    _notify();
  }

  /// ⚠️ Guarded, because a request can be in flight when the dialog is dismissed
  /// — notifying a disposed `ChangeNotifier` throws, and Flutter paints that over
  /// whatever is behind the dialog.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debouncer.cancel();
    super.dispose();
  }
}
