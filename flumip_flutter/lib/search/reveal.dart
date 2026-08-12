import 'package:flutter/foundation.dart';

/// A genome to show, and the rail category to open on the way to it.
@immutable
class GenomeReveal {
  const GenomeReveal({required this.genomeId, this.category});

  final int genomeId;

  /// The category the genome is filed under, or null when it has none — in which
  /// case the rail is left alone and only the detail pane opens.
  final String? category;

  @override
  bool operator ==(Object other) =>
      other is GenomeReveal &&
      other.genomeId == genomeId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(genomeId, category);

  @override
  String toString() => 'GenomeReveal($genomeId, $category)';
}

/// One-shot requests to show a genome, for whoever currently owns the genome tab.
///
/// ⚠️ This exists because [ProjectsController] is app-wide and `GenomeController`
/// deliberately is not: the genome controller holds a poll for the genome on
/// screen, so `services.dart` hands out a factory and `GenomeTab` owns the
/// instance. Nothing outside that tab can hold one, so nothing outside it can call
/// `selectGenome` — and a search result in the app bar is very much outside it.
/// This is the smallest thing that crosses the boundary.
///
/// Consumed with [take] rather than read, so a reveal cannot fire again on the
/// next rebuild — the same reason `GenomeController.messages` is a stream rather
/// than a field.
class GenomeReveals extends ChangeNotifier {
  GenomeReveal? _pending;

  /// Asks the genome tab to show [target]. Replaces any request not yet taken:
  /// two clicks in a row mean the second one wins.
  void request(GenomeReveal target) {
    _pending = target;
    notifyListeners();
  }

  /// The outstanding request, clearing it. Null when there is none.
  GenomeReveal? take() {
    final target = _pending;
    _pending = null;
    return target;
  }

  /// Whether a request is waiting to be taken. For tests.
  @visibleForTesting
  bool get hasPending => _pending != null;
}
