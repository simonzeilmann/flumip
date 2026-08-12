import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/dialog_body.dart';
import '../ui/error_banner.dart';
import '../ui/theme.dart';
import 'search_controller.dart';

/// Opens the search dialog and closes it on the first hit chosen.
///
/// [onOpen] is called *after* the dialog has popped, so the tab animation is not
/// running behind a modal barrier.
Future<void> showSearchDialog(
  BuildContext context, {
  required void Function(SearchHitDto hit) onOpen,
  UnifiedSearchController? controller,
}) => showDialog<void>(
  context: context,
  builder: (_) => SearchDialog(controller: controller, onOpen: onOpen),
);

/// Type two characters, get projects, genomes and SNP sets that match.
///
/// The only surface in the app that reaches all three, which is the point: a
/// genome is otherwise behind whichever category somebody filed it under, and an
/// SNP set is unreachable until its genome is selected.
class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key, this.controller, required this.onOpen});

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Owned by this widget when it builds its own: it holds a debounce timer
  /// and a cache of answers, neither of which should outlive the dialog.
  final UnifiedSearchController? controller;

  /// Called with the chosen hit once the dialog has closed.
  final void Function(SearchHitDto hit) onOpen;

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late final bool _ownsController = widget.controller == null;
  late final UnifiedSearchController _controller =
      widget.controller ?? createSearchController();
  final TextEditingController _field = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _field.dispose();
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _open(SearchHitDto hit) {
    // Popped first, then handed over: `onOpen` switches tab, and animating a tab
    // behind a modal barrier that is still up looks like a stuck dialog.
    Navigator.of(context).pop();
    widget.onOpen(hit);
  }

  void _clear() {
    _field.clear();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: DialogBody(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _field,
              autofocus: true,
              // The dialog is a search box; there is nothing to move on to.
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search projects, genomes and SNP sets',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                        onPressed: _clear,
                      ),
              ),
              onChanged: _controller.queryChanged,
              onSubmitted: (_) {
                final first = _controller.firstHit;
                if (first != null) _open(first);
              },
            ),
            // ⚠️ A 2px bar under the field rather than a spinner in place of the
            // list, and the previous results stay up while the next answer is in
            // flight. Replacing the list on every keystroke makes a fast search
            // feel like a slow one.
            SizedBox(
              height: 2,
              child: _controller.busy
                  ? const LinearProgressIndicator(minHeight: 2)
                  : null,
            ),
            const SizedBox(height: 12),
            if (_controller.errorMessage != null) ...[
              ErrorBanner(_controller.errorMessage!),
              const SizedBox(height: 12),
            ],
            Flexible(child: _results()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _results() {
    // Three states worth telling apart, and the hint is the one that matters:
    // "nothing matched" would be a lie about a question nobody has asked yet.
    if (_controller.idle) {
      const minimum = UnifiedSearchController.minQueryLength;
      return _note('Type at least $minimum characters.');
    }
    final hits = _controller.hits;
    if (hits == null) return const SizedBox(height: 48);
    if (hits.isEmpty) return _note('Nothing matched "${_controller.query}".');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView(
        shrinkWrap: true,
        children: [
          ..._group('Projects', Icons.folder, _controller.projects),
          ..._group('Genomes', Icons.dns, _controller.genomes),
          ..._group('SNP sets', Icons.science, _controller.snpSets),
        ],
      ),
    );
  }

  /// A heading and its rows, or nothing at all when the kind had no hits.
  ///
  /// The heading is what says which kind a row is, which is why the rows carry no
  /// `StatusPill` — one on every row would be the noise that widget warns about.
  List<Widget> _group(String title, IconData icon, List<SearchHitDto> hits) {
    if (hits.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          title.toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            color: context.colours.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ),
      for (final hit in hits)
        ListTile(
          dense: true,
          leading: Icon(icon, size: 20),
          title: Text(hit.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: _subtitleOf(hit) == null
              ? null
              : Text(
                  _subtitleOf(hit)!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: () => _open(hit),
        ),
    ];
  }

  /// The description if it has one, otherwise whatever context the hit carries —
  /// a genome's name for an SNP set, a category for a genome.
  String? _subtitleOf(SearchHitDto hit) {
    if (hit.subtitle.isNotEmpty) return hit.subtitle;
    if (hit.context.isNotEmpty) return hit.context;
    return null;
  }

  Widget _note(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      message,
      style: context.text.bodySmall?.copyWith(
        color: context.colours.onSurfaceVariant,
      ),
    ),
  );
}
