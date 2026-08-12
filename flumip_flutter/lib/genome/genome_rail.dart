import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../ui/error_banner.dart';
import '../ui/theme.dart';

/// The navigation half of the genome tab: pick a category, then a genome.
///
/// Replaces two panes that between them wasted most of the window. The old
/// layout gave categories and genomes an `Expanded` third each, then put a
/// `SizedBox(width: 220)` and a `SizedBox(width: 260)` inside them, centred — so
/// on a 1920px window roughly 770px was blank while the details pane, the only
/// one with substantial content, was squeezed into the remaining third.
///
/// ⚠️ **Pure by construction.** It takes its data and its callbacks and never
/// touches the top-level `client`, which is what makes it testable — every other
/// widget in this tab transitively imports `main.dart`, which builds a Serverpod
/// client and reads `web.window` at import time.
///
/// The accordion is flattened into a single `ListView` rather than built from
/// `ExpansionTile`. `ExpansionTile` owns its own expanded state, which would
/// fight the parent's — and it would nest a scroll view inside a scroll view.
/// One flat list keeps virtualisation and makes the row order obvious.
class GenomeRail extends StatelessWidget {
  const GenomeRail({
    super.key,
    required this.categories,
    required this.genomes,
    required this.expandedCategory,
    required this.selectedGenomeId,
    required this.onCategoryToggled,
    required this.onGenomeSelected,
    required this.onCollectGenomes,
    required this.onCollectCustomSnps,
    this.loadingCategory,
    this.error,
    this.onDismissError,
  });

  final List<String> categories;

  /// The genomes of [expandedCategory] only — the server is asked per category,
  /// so there is nothing else to hold.
  final List<Genome> genomes;

  final String? expandedCategory;
  final int? selectedGenomeId;

  /// Called with the category to open, or null to close the open one.
  final void Function(String?) onCategoryToggled;
  final void Function(Genome) onGenomeSelected;

  final VoidCallback onCollectGenomes;
  final VoidCallback onCollectCustomSnps;

  /// Set while a category's genomes are on their way.
  final String? loadingCategory;

  /// Shown under the header, where it explains the list below it rather than
  /// sitting at the bottom of the window as it used to.
  final String? error;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: ErrorBanner(error!, onDismiss: onDismissError),
          ),
        const Divider(height: 1),
        Expanded(child: _list(context)),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(child: Text('Genomes', style: context.text.titleMedium)),
          // Both actions are library-wide maintenance rather than anything to do
          // with the selected genome, so they belong here rather than as buttons
          // over the whole tab. A menu also suits what they cost: collecting
          // genomes walks the entire genome tree with a recursive size count,
          // which is hundreds of gigabytes of stat calls on a real install.
          PopupMenuButton<_LibraryAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Library actions',
            onSelected: (action) => switch (action) {
              _LibraryAction.collectGenomes => onCollectGenomes(),
              _LibraryAction.collectSnps => onCollectCustomSnps(),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _LibraryAction.collectGenomes,
                child: Text('Scan for new genomes'),
              ),
              PopupMenuItem(
                value: _LibraryAction.collectSnps,
                child: Text('Recheck custom SNP sets'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No genomes yet. Use "Scan for new genomes" once the files are in '
          'place.',
          style: context.text.bodySmall?.copyWith(
            color: context.colours.onSurfaceVariant,
          ),
        ),
      );
    }

    final rows = _rows();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i].build(context, this),
    );
  }

  /// Flattens categories and the open category's genomes into one list.
  List<_Row> _rows() {
    final rows = <_Row>[];
    for (final category in categories) {
      rows.add(_CategoryRow(category));
      if (category != expandedCategory) continue;

      if (loadingCategory == category) {
        rows.add(const _LoadingRow());
      } else if (genomes.isEmpty) {
        rows.add(const _EmptyRow());
      } else {
        rows.addAll(genomes.map(_GenomeRow.new));
      }
    }
    return rows;
  }
}

enum _LibraryAction { collectGenomes, collectSnps }

sealed class _Row {
  const _Row();

  Widget build(BuildContext context, GenomeRail rail);
}

class _CategoryRow extends _Row {
  const _CategoryRow(this.category);

  final String category;

  @override
  Widget build(BuildContext context, GenomeRail rail) {
    final open = rail.expandedCategory == category;
    return ListTile(
      dense: true,
      title: Text(category, style: context.text.titleSmall),
      // The chevron is the only affordance here, so it stays where the
      // decorative per-row icons went.
      trailing: AnimatedRotation(
        turns: open ? 0.25 : 0,
        duration: const Duration(milliseconds: 150),
        child: const Icon(Icons.chevron_right, size: 20),
      ),
      onTap: () => rail.onCategoryToggled(open ? null : category),
    );
  }
}

class _LoadingRow extends _Row {
  const _LoadingRow();

  @override
  Widget build(BuildContext context, GenomeRail rail) => const Padding(
    padding: EdgeInsets.fromLTRB(32, 8, 16, 8),
    child: LinearProgressIndicator(minHeight: 2),
  );
}

class _EmptyRow extends _Row {
  const _EmptyRow();

  @override
  Widget build(BuildContext context, GenomeRail rail) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 8, 16, 12),
    child: Text(
      'No genomes in this category.',
      style: context.text.bodySmall?.copyWith(
        color: context.colours.onSurfaceVariant,
      ),
    ),
  );
}

class _GenomeRow extends _Row {
  const _GenomeRow(this.genome);

  final Genome genome;

  @override
  Widget build(BuildContext context, GenomeRail rail) {
    final selected = genome.id == rail.selectedGenomeId;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 12),
      title: Text(
        genome.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodyMedium,
      ),
      // The description used to be here, ellipsised inside a 260px column where
      // it was truncated to nothing useful. It belongs in the detail pane, which
      // now has room for it.
      subtitle: Text(
        formatBytes(genome.size),
        style: context.text.bodySmall?.copyWith(
          color: context.colours.onSurfaceVariant,
        ),
      ),
      selected: selected,
      selectedTileColor: context.colours.secondaryContainer,
      selectedColor: context.colours.onSecondaryContainer,
      onTap: () => rail.onGenomeSelected(genome),
    );
  }
}
