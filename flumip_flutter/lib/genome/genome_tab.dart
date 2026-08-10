import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../error_text.dart';
import '../main.dart';
import '../poll.dart';
import '../snp/snp_section.dart';
import '../ui/layout.dart';
import 'genome_detail_pane.dart';
import 'genome_rail.dart';

/// Genomes and their SNP sets, as a two-pane master–detail.
///
/// The rail on the left holds both levels of the hierarchy — categories, and the
/// genomes inside the open one — and the detail pane takes everything else. That
/// replaces three equal columns whose first two contained fixed-width lists
/// floating in empty thirds.
class GenomeTab extends StatefulWidget {
  const GenomeTab({super.key});

  @override
  State<GenomeTab> createState() => _GenomeTabState();
}

class _GenomeTabState extends State<GenomeTab> {
  List<String> categories = [];
  List<Genome> genomes = [];
  Genome? selectedGenome;
  String? expandedCategory;
  String? _loadingCategory;

  /// Split by cause, so a message appears next to the thing it explains.
  ///
  /// There used to be one `_errorMessage`, rendered below a full-height
  /// `Expanded` at the very bottom of the tab — about as far from whatever
  /// caused it as the layout allowed.
  String? _railError;
  String? _detailError;

  Timer? _timer;
  int _failures = 0;

  /// True while a change of ours is in flight.
  ///
  /// ⚠️ Guards against the poll landing mid-update and putting the Active switch
  /// back. The old code had a `ValueNotifier` for the switch that `_fetchGenome`
  /// wrote to on every tick, which is precisely how a toggle got stomped.
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Schedules the next read of the selected genome, or stops.
  ///
  /// ⚠️ Was `Timer.periodic(5s)`, firing for as long as a genome was selected and
  /// rebuilding the whole tab twelve times a minute — for data that cannot
  /// change on its own. A genome's `active` flag is toggled here and indexing is
  /// started here; the one thing that progresses without us is an index being
  /// built. See [genomePollInterval].
  void _rearm() {
    _timer?.cancel();
    _timer = null;

    final genome = selectedGenome;
    if (genome == null) return;

    final wait = genomePollInterval(
      indexing: genome.indexing,
      consecutiveFailures: _failures,
    );
    if (wait == null) return;

    _timer = Timer(wait, () {
      if (!mounted || _mutating) return;
      _fetchGenome(genome.id!, quiet: true);
    });
  }

  void _fetchCategories() async {
    try {
      final categories = await client.genome.getCategories();
      categories.sort((a, b) => a.compareTo(b));
      if (!mounted) return;
      setState(() {
        _railError = null;
        this.categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _railError = describeError(e));
    }
  }

  void _toggleCategory(String? category) {
    setState(() {
      expandedCategory = category;
      genomes = [];
      _loadingCategory = category;
    });
    if (category != null) _fetchGenomes(category);
  }

  void _fetchGenomes(String category) async {
    try {
      final genomes = await client.genome.getGenomeByCategory(category);
      genomes.sort((a, b) => a.name.compareTo(b.name));
      if (!mounted || expandedCategory != category) return;
      setState(() {
        _railError = null;
        this.genomes = genomes;
        _loadingCategory = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCategory = null;
        _railError = describeError(e);
      });
    }
  }

  /// Reads one genome.
  ///
  /// [quiet] is for the poll: a failed background refresh should back the poll
  /// off, not put an error banner over a pane the user is reading.
  void _fetchGenome(int genomeID, {bool quiet = false}) async {
    try {
      final genome = await client.genome.getGenome(genomeID);
      if (!mounted || _mutating) return;
      setState(() {
        _detailError = null;
        _failures = 0;
        selectedGenome = genome;
      });
      _rearm();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _failures++;
        if (!quiet) _detailError = describeError(e);
      });
      // Nothing will change while access is refused, so stop asking.
      if (!isAccessDenied(e)) _rearm();
    }
  }

  void _selectGenome(Genome genome) {
    setState(() {
      selectedGenome = genome;
      _detailError = null;
      _failures = 0;
    });
    _fetchGenome(genome.id!);
  }

  void _indexGenome() async {
    await _mutate(
      () => client.genome.indexFasta(selectedGenome!.id!),
      'Could not start indexing',
    );
  }

  void _deleteIndex() async {
    await _mutate(
      () => client.genome.deleteFastaIndex(selectedGenome!.id!),
      'Could not delete the index',
    );
  }

  /// Runs a change against the selected genome, then re-reads it.
  ///
  /// Failures go to a snack bar rather than the pane's banner: an action the
  /// user just took reports where they are looking, whereas a banner explains
  /// the state of something on screen.
  Future<void> _mutate(
    Future<void> Function() action,
    String whatFailed,
  ) async {
    final id = selectedGenome?.id;
    if (id == null) return;
    _mutating = true;
    try {
      await action();
      _mutating = false;
      _fetchGenome(id);
    } catch (e) {
      _mutating = false;
      _say('$whatFailed: ${describeError(e)}');
    }
  }

  void _collectGenomes() async {
    try {
      await client.genome.collectGenomes();
      _fetchCategories();
      if (expandedCategory != null) _fetchGenomes(expandedCategory!);
      _say('Scanned for new genomes.');
    } catch (e) {
      _say('Could not scan for genomes: ${describeError(e)}');
    }
  }

  void _collectCustomSnps() async {
    try {
      await client.snp.collectCustomSnps();
      if (selectedGenome != null) _fetchGenome(selectedGenome!.id!);
      _say('Rechecked the custom SNP sets.');
    } catch (e) {
      _say('Could not recheck the SNP sets: ${describeError(e)}');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showIndexDeleteDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete index for ${selectedGenome!.name}?'),
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
              _deleteIndex();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleGenomeActive(bool value) async {
    final genome = selectedGenome;
    if (genome == null) return;
    final previous = genome.active;

    setState(() => genome.active = value);
    _mutating = true;
    try {
      await client.genome.updateGenome(genome.id!, genome);
      _mutating = false;
    } catch (e) {
      _mutating = false;
      // ⚠️ Put back. Without the rollback the switch stayed where the user left
      // it even though the server had refused, so the interface asserted
      // something untrue until the next poll happened to correct it.
      if (!mounted) return;
      setState(() {
        genome.active = previous;
        _detailError = 'Could not change the genome: ${describeError(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final genome = selectedGenome;

    final rail = GenomeRail(
      categories: categories,
      genomes: genomes,
      expandedCategory: expandedCategory,
      selectedGenomeId: genome?.id,
      loadingCategory: _loadingCategory,
      onCategoryToggled: _toggleCategory,
      onGenomeSelected: _selectGenome,
      onCollectGenomes: _collectGenomes,
      onCollectCustomSnps: _collectCustomSnps,
      error: _railError,
      onDismissError: () => setState(() => _railError = null),
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
                : _detail(
                    genome,
                    onBack: () => setState(() {
                      selectedGenome = null;
                      _timer?.cancel();
                    }),
                  );
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
    onDeleteIndex: _showIndexDeleteDialog,
    onIndexGenome: _indexGenome,
    onToggleGenomeActive: _toggleGenomeActive,
    onBack: onBack,
    error: _detailError,
    onDismissError: () => setState(() => _detailError = null),
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
