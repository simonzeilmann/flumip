import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../ui/dialog_body.dart';
import '../ui/status_pill.dart';
import '../ui/theme.dart';

/// Picks a genome, in one step.
///
/// ⚠️ **Replaces a two-stage ritual that did not admit it was one.** The old
/// control was a `DropdownButton` of categories whose `onChanged` fired a fetch
/// and then opened a dialog of genomes — so choosing a genome meant a dropdown
/// *and* a dialog, and the dropdown's `value` was hard-coded to `null`, so it
/// never showed what had been chosen and reset itself every rebuild.
///
/// It also silently did nothing when you tapped a genome that was mid-index: the
/// tile's `onTap` just popped the dialog. That reads as a broken click. Here
/// such a genome is visibly disabled and says why.
///
/// Pure: categories and genomes are fetched by the caller and passed in, so this
/// can be pumped in a test.
class GenomePickerDialog extends StatefulWidget {
  const GenomePickerDialog({
    super.key,
    required this.categories,
    required this.loadGenomes,
    this.initialCategory,
    this.selectedGenomeId,
  });

  final List<String> categories;

  /// Asked for one category's genomes when that category is opened.
  final Future<List<Genome>> Function(String category) loadGenomes;

  /// Opened straight away, so re-picking starts where the project already is.
  final String? initialCategory;

  final int? selectedGenomeId;

  @override
  State<GenomePickerDialog> createState() => _GenomePickerDialogState();
}

class _GenomePickerDialogState extends State<GenomePickerDialog> {
  String? _open;
  final Map<String, List<Genome>> _loaded = {};
  final Set<String> _loading = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    // With one category — the common case on a real install — there is nothing
    // to choose between, so open it rather than making the user tap it first.
    final only = widget.categories.length == 1
        ? widget.categories.single
        : null;
    final start = widget.initialCategory ?? only;
    if (start != null) {
      // Directly, not through _openCategory: setState is not allowed during
      // initState, and the first build has not happened yet anyway.
      _open = start;
      _load(start);
    }
  }

  void _openCategory(String category) {
    final next = _open == category ? null : category;
    setState(() => _open = next);
    if (next != null) _load(next);
  }

  Future<void> _load(String category) async {
    if (_loaded.containsKey(category) || _loading.contains(category)) return;
    setState(() => _loading.add(category));
    try {
      // ⚠️ Sort a copy. The list belongs to the caller: an unmodifiable one
      // throws here, and a cached one would be reordered underneath them.
      final genomes = [...await widget.loadGenomes(category)]
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      setState(() {
        _loaded[category] = genomes;
        _loading.remove(category);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading.remove(category);
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose a genome'),
      content: DialogBody(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.colours.error),
                  ),
                ),
              if (widget.categories.isEmpty)
                Text(
                  'No genomes are available. An administrator can add them from '
                  'the Genomes & SNP tab.',
                  style: TextStyle(color: context.colours.onSurfaceVariant),
                ),
              for (final category in widget.categories) ..._category(category),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<Widget> _category(String category) {
    final open = _open == category;
    return [
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(category, style: context.text.titleSmall),
        trailing: AnimatedRotation(
          turns: open ? 0.25 : 0,
          duration: const Duration(milliseconds: 150),
          child: const Icon(Icons.chevron_right, size: 20),
        ),
        onTap: () => _openCategory(category),
      ),
      if (open) ...[
        if (_loading.contains(category))
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 0, 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else
          for (final genome in _loaded[category] ?? const <Genome>[])
            if (genome.active) _genomeTile(genome),
        if (!_loading.contains(category) &&
            (_loaded[category]?.where((g) => g.active).isEmpty ?? false))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
            child: Text(
              'No genomes in this category.',
              style: TextStyle(color: context.colours.onSurfaceVariant),
            ),
          ),
      ],
    ];
  }

  Widget _genomeTile(Genome genome) {
    // ⚠️ A genome being indexed cannot be used yet, and the old dialog made that
    // look like a bug: the row was tappable and tapping it just closed the
    // dialog with nothing changed.
    final busy = genome.indexing;
    final status = context.status;

    return ListTile(
      dense: true,
      enabled: !busy,
      selected: genome.id == widget.selectedGenomeId,
      selectedTileColor: context.colours.secondaryContainer,
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      title: Text(genome.name),
      subtitle: Text(
        busy
            ? 'Being indexed — not usable yet'
            : genome.indexed
            ? formatBytes(genome.size)
            : '${formatBytes(genome.size)} · will be indexed when first used',
      ),
      trailing: busy
          ? StatusPill(
              label: 'Indexing',
              icon: Icons.build,
              colour: status.warning,
            )
          : genome.indexed
          ? null
          : StatusPill(
              label: 'Not indexed',
              icon: Icons.remove_circle_outline,
              colour: context.colours.outline,
            ),
      onTap: busy ? null : () => Navigator.of(context).pop(genome),
    );
  }
}
