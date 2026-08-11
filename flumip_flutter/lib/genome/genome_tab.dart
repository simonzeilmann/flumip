import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../snp/snp_section.dart';
import '../ui/layout.dart';
import 'genome_controller.dart';
import 'genome_detail_pane.dart';
import 'genome_rail.dart';

/// Genomes and their SNP sets, as a two-pane master–detail.
///
/// The rail on the left holds both levels of the hierarchy — categories, and the
/// genomes inside the open one — and the detail pane takes everything else. That
/// replaces three equal columns whose first two contained fixed-width lists
/// floating in empty thirds.
///
/// Everything that fetches or changes anything is in [GenomeController]; this
/// file is layout plus the two things that genuinely need a `BuildContext`: the
/// confirm dialog and the snack bars.
class GenomeTab extends StatefulWidget {
  const GenomeTab({super.key, this.controller});

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Unlike the projects tab, this one **owns** its controller. The controller
  /// holds a poll timer for the genome on screen, and one app-wide instance would
  /// go on polling an index being built while somebody is reading another tab. A
  /// controller passed in belongs to the caller and is not disposed here.
  final GenomeController? controller;

  @override
  State<GenomeTab> createState() => _GenomeTabState();
}

class _GenomeTabState extends State<GenomeTab> {
  late final bool _ownsController = widget.controller == null;
  late final GenomeController _controller =
      widget.controller ?? createGenomeController();
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _messages = _controller.messages.listen(_say);
    _controller.load();
  }

  @override
  void dispose() {
    _messages?.cancel();
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDeleteIndex() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete index for ${_controller.selectedGenome!.name}?'),
        content: const Text(
          'The genome stays; only its index is removed. Building it again takes '
          'a while.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.deleteIndex();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genome = _controller.selectedGenome;

    final rail = GenomeRail(
      categories: _controller.categories,
      genomes: _controller.genomes,
      expandedCategory: _controller.expandedCategory,
      selectedGenomeId: genome?.id,
      loadingCategory: _controller.loadingCategory,
      onCategoryToggled: _controller.toggleCategory,
      onGenomeSelected: _controller.selectGenome,
      onCollectGenomes: _controller.scanForGenomes,
      onCollectCustomSnps: _controller.recheckSnpSets,
      error: _controller.railError,
      onDismissError: _controller.dismissRailError,
    );

    return ContentWidth(
      maxWidth: ContentWidth.wide,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= kSplitWidth;

          if (!wide) {
            // One pane at a time. A plain conditional rather than an
            // IndexedStack: an offscreen SnpSection would go on polling.
            return genome == null
                ? rail
                : _detail(genome, onBack: _controller.clearSelection);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 320, child: rail),
              const VerticalDivider(width: 1),
              Expanded(
                child: genome == null ? _placeholder(context) : _detail(genome),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detail(Genome genome, {VoidCallback? onBack}) => GenomeDetailPane(
    genome: genome,
    snpSection: SnpSection(genome: genome),
    onDeleteIndex: _confirmDeleteIndex,
    onIndexGenome: _controller.indexGenome,
    onToggleGenomeActive: _controller.toggleActive,
    onBack: onBack,
    error: _controller.detailError,
    onDismissError: _controller.dismissDetailError,
  );

  Widget _placeholder(BuildContext context) => Center(
    child: Text(
      'Select a genome.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
