import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../ui/error_banner.dart';
import '../ui/status_pill.dart';
import '../ui/theme.dart';

/// Which of the three index states a genome is in.
///
/// A named thing, rather than two booleans read at the point of display, because
/// the display used to interpolate them directly: `'Indexing: ${genome.indexing}
/// ...'` and `'Indexed: ${genome.indexed}'` rendered on screen as **"Indexing:
/// true..."** and **"Indexed: false"**. Raw Dart booleans, shown to biologists.
enum IndexState {
  none,
  building,
  built;

  static IndexState of(Genome genome) {
    if (genome.indexing) return IndexState.building;
    return genome.indexed ? IndexState.built : IndexState.none;
  }

  String get label => switch (this) {
    IndexState.none => 'Not indexed',
    IndexState.building => 'Indexing…',
    IndexState.built => 'Indexed',
  };

  IconData get icon => switch (this) {
    IndexState.none => Icons.remove_circle_outline,
    IndexState.building => Icons.build,
    IndexState.built => Icons.check_circle,
  };
}

/// Everything about the selected genome, and its SNP sets.
///
/// Was `GenomeDetailsCard`, an elevated white `Card` inside the narrowest of
/// three equal columns. It is not a card any more: at full pane width a raised
/// slab on a slab is just noise, and the divider between the rail and this
/// already separates the two regions.
///
/// ⚠️ **The header is fixed and only the SNP list scrolls**, deliberately. If the
/// whole pane scrolled, `SnpSection`'s `ListView` would need `shrinkWrap: true`
/// inside a `SingleChildScrollView`, which destroys virtualisation — and this
/// subtree rebuilds on every upload progress callback, so a genome with forty
/// SNP sets would rebuild all forty on each one. The 'SNP sets (n) / Add' bar
/// also has to stay reachable, especially in the empty state where it holds the
/// only useful control.
class GenomeDetailPane extends StatelessWidget {
  const GenomeDetailPane({
    super.key,
    required this.genome,
    required this.snpSection,
    required this.onDeleteIndex,
    required this.onIndexGenome,
    required this.onToggleGenomeActive,
    this.onBack,
    this.error,
    this.onDismissError,
  });

  final Genome genome;

  /// Injected rather than constructed here, so this pane can be pumped in a test
  /// without dragging in the SNP list — and with it the top-level `client`.
  final Widget snpSection;

  final VoidCallback onDeleteIndex;
  final VoidCallback onIndexGenome;
  final void Function(bool) onToggleGenomeActive;

  /// Only set on a narrow window, where this pane replaces the rail entirely.
  final VoidCallback? onBack;

  final String? error;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null) ...[
                ErrorBanner(error!, onDismiss: onDismissError),
                const SizedBox(height: 12),
              ],
              _title(context),
              const SizedBox(height: 2),
              _metadata(context),
              if (genome.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  genome.description,
                  style: context.text.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              _actions(context),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: snpSection),
      ],
    );
  }

  Widget _title(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to the genome list',
              onPressed: onBack,
            ),
          ),
        // ⚠️ Expanded, which the original was not: a long genome name in a Row
        // with no flex overflows, and the old layout gave this a third of the
        // window to overflow in.
        Expanded(
          child: Tooltip(
            message: genome.name,
            child: Text(
              genome.name,
              style: context.text.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  /// Category, size and id on one subdued line.
  ///
  /// Not a key/value table: there are three short fields, and a table would
  /// reintroduce exactly the one-field-per-row stacking this replaced — where
  /// `ID: 3` took a full line with a fingerprint icon beside it. Where a value
  /// would be ambiguous alone the key is a word, never a glyph.
  ///
  /// `size` was previously shown only in the list, never here.
  Widget _metadata(BuildContext context) {
    final category = genome.category;
    final parts = [
      // Nullable on the model, and empty for a genome sitting outside any
      // category directory.
      if (category != null && category.isNotEmpty) category,
      formatBytes(genome.size),
      'ID ${genome.id}',
    ];
    return Text(
      parts.join(' · '),
      style: context.text.bodySmall?.copyWith(
        color: context.colours.onSurfaceVariant,
      ),
    );
  }

  /// The index state and everything that can be done to this genome.
  ///
  /// One `Wrap` is what makes the pane work at any width: on a wide window the
  /// pill, the button and the switch sit on one line; narrow, they wrap. No
  /// `LayoutBuilder` and no second code path.
  Widget _actions(BuildContext context) {
    final state = IndexState.of(genome);
    final status = context.status;
    final colour = switch (state) {
      IndexState.none => context.colours.outline,
      IndexState.building => status.warning,
      IndexState.built => status.success,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusPill(label: state.label, icon: state.icon, colour: colour),
        if (state == IndexState.none)
          FilledButton.icon(
            onPressed: onIndexGenome,
            icon: const Icon(Icons.build, size: 18),
            label: const Text('Build index'),
          ),
        if (state == IndexState.built)
          // Outlined rather than a filled redAccent button. It is already behind
          // a confirmation dialog, and a destructive action should not be the
          // loudest thing on the screen.
          OutlinedButton.icon(
            onPressed: onDeleteIndex,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete index'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colours.error,
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Active', style: context.text.bodyMedium),
            const SizedBox(width: 4),
            Switch(value: genome.active, onChanged: onToggleGenomeActive),
          ],
        ),
      ],
    );
  }
}
