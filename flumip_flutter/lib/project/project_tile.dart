import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/format.dart';
import 'package:flumip_flutter/main.dart';
import 'package:flumip_flutter/ui/responsive_row.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../error_text.dart';
import 'genome_picker_dialog.dart';
import 'mipgen_progress.dart';
import 'owner_picker.dart';
import 'project_inputs.dart';
import 'project_options_view.dart';
import 'project_result_actions.dart';
import 'project_run_panel.dart';
import 'project_state.dart';
import 'project_state_pill.dart';

/// One project in the list: a row that says what it is doing, and — when opened —
/// its inputs, its design parameters and its results.
///
/// ⚠️ This file is deliberately about *lifecycle*: loading a project, polling it
/// while a design runs, and calling the endpoints that change it. Everything it
/// draws lives in a sibling file that takes data and callbacks and touches no
/// client, because this one imports `main.dart` and therefore cannot be reached
/// from a test at all. The split is what makes the pieces testable:
///
///  * `project_inputs.dart` — genome, SNP set, genes
///  * `project_options_view.dart` — the design parameters
///  * `project_run_panel.dart` — the BED step, the run, the results
///  * `project_state_pill.dart` — the collapsed row's badge
///  * `project_result_actions.dart` — opening result files and downloads
///  * `ucsc_track.dart` — building the UCSC links
//ignore: must_be_immutable
class ProjectTile extends StatefulWidget {
  Project project;
  final VoidCallback onDelete;

  /// Whether an administrator has mail switched on for this install.
  ///
  /// Only controls whether the notification switch is offered — the server
  /// decides what is actually sent.
  final bool notificationsAvailable;

  /// The users this project can be handed to, or null when the viewer is not an
  /// administrator and the picker should not appear at all.
  final List<FlumipUserDto>? assignableOwners;

  /// Called with the new owner's id, or null to release the project to unowned.
  final void Function(int? ownerId)? onOwnerChanged;

  /// Opens without a click, for a project that has just been created.
  final bool initiallyExpanded;

  ProjectTile({
    super.key,
    required this.project,
    required this.onDelete,
    this.notificationsAvailable = false,
    this.assignableOwners,
    this.onOwnerChanged,
    this.initiallyExpanded = false,
  });

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  late bool _isExpanded = widget.initiallyExpanded;
  bool _deleteExcessFiles = false;
  ProjectOptions projectOptions = ProjectOptions();

  /// The project's genome, or null while it is still being fetched.
  ///
  /// ⚠️ Was a `Genome(name: 'default')` sentinel, which read as a loaded genome
  /// with no id — so the SNP query below did `genome.id!` on it and threw during
  /// the frame between opening a tile and its genome arriving. A thrown build is
  /// the red error screen over the whole tab.
  Genome? genome;

  /// The project's chosen SNP set, or null while it is still being fetched.
  Snp? snp;

  /// Cached so the `FutureBuilder` below does not fire a fresh query on every
  /// rebuild — and this tile rebuilds every few seconds while a design runs.
  Future<List<Snp>>? _snpsForGenome;

  String? _errorMessage;
  Timer? _timer;

  /// The run's progress file, re-read while the design is going.
  MipgenProgress _progress = const MipgenProgress.empty();

  @override
  void initState() {
    super.initState();
    // A tile that opens itself still has to load what it is going to show.
    if (_isExpanded) _reloadProject();
    // ⚠️ No timer until the tile is opened. This was an unconditional
    // `Timer.periodic(10s)` created for *every* tile in the list, so a hundred
    // projects meant a hundred timers waking up to find the tile collapsed and
    // do nothing.
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Schedules the next refresh, or stops.
  ///
  /// Faster while a design is running, because that is the only time the project
  /// changes on its own — and it is exactly when somebody is watching it.
  void _rearm() {
    _timer?.cancel();
    _timer = null;
    if (!_isExpanded) return;

    final running = ProjectState.of(widget.project).isRunning;
    _timer = Timer(
      running ? const Duration(seconds: 3) : const Duration(seconds: 15),
      () {
        if (!mounted) return;
        _reloadProject();
      },
    );
  }

  /// Reads the progress file, best-effort.
  ///
  /// Never surfaces its own failure: the run's state comes from the project row,
  /// and an unreadable progress file is not worth an error banner over a design
  /// that is going fine.
  Future<void> _loadProgress() async {
    try {
      final lines = await client.file.showMipsProgress(widget.project.id!);
      if (!mounted) return;
      setState(() => _progress = MipgenProgress(lines: lines));
    } catch (_) {
      // Left as it was; the panel keeps showing the last line it had.
    }
  }

  void _toggleExpand() async {
    setState(() {
      _isExpanded = !_isExpanded;
      genome = null;
      snp = null;
      _snpsForGenome = null;
    });
    if (_isExpanded) {
      await _reloadProject();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _reloadProject() async {
    try {
      var projectUpdate = await client.project.getProject(widget.project.id!);
      final options = await client.options.getProjectOptions(
        widget.project.options,
      );
      Genome? genomeUpdate;
      if (widget.project.genome != null) {
        genomeUpdate = await client.genome.getGenome(widget.project.genome!);
      }
      Snp? snpUpdate;
      if (widget.project.snp != null) {
        snpUpdate = await client.genome.getSnp(widget.project.snp!);
      }
      // ⚠️ Four awaits happened above. Deleting the project disposes this tile
      // while they are still in flight, and `setState` after dispose throws —
      // which Flutter paints as the red error screen over the whole tab. This is
      // the guard that was missing.
      if (!mounted) return;
      setState(() {
        widget.project = projectUpdate;
        projectOptions = options;
        if (genomeUpdate != null) {
          genome = genomeUpdate;
        }
        if (snpUpdate != null) {
          snp = snpUpdate;
        }
      });

      // Only while something is actually being written, so a finished project
      // does not re-read its log forever.
      if (ProjectState.of(projectUpdate).isRunning) {
        await _loadProgress();
      }
      _rearm();
    } catch (e) {
      // Stop the poll when the answer will not change. Without this, a project
      // that has stopped being ours mid-session — revoked session, ownership
      // reassigned — re-reports the same refusal for as long as the tile stays
      // expanded. A project that has been *deleted* is the same situation: it is
      // not coming back, so stop asking rather than reporting the same failure
      // six times a minute.
      if (isAccessDenied(e) || _isGone(e)) {
        _timer?.cancel();
        _timer = null;
      }
      if (!mounted) return;
      // A deleted project needs no error at all — the row is on its way out.
      if (_isGone(e)) return;
      setState(() {
        _errorMessage = 'Failed to reload project: ${describeError(e)}';
      });
      _rearm();
    }
  }

  /// Whether this error means the project no longer exists.
  ///
  /// The poll and the delete race by nature: a tick can be in flight when the row
  /// is removed, and the answer comes back as "not found".
  static bool _isGone(Object error) => error is FlumipFileNotFoundException;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- The endpoints this tile calls -----------------------------------------

  Future<void> _addGene(String gene) async {
    try {
      await client.project.addGeneToProject(widget.project.id!, gene);
      await _reloadProject();
    } catch (e) {
      _say('Failed to add gene: ${describeError(e)}');
    }
  }

  Future<void> _removeGene(String gene) async {
    try {
      await client.project.removeGeneFromProject(widget.project.id!, gene);
      await _reloadProject();
    } catch (e) {
      _say('Failed to remove gene: ${describeError(e)}');
    }
  }

  Future<void> _createBedFile() async {
    try {
      await client.mipgen.createBedFile(widget.project.id!);
      await _reloadProject();
      _say('BED file created successfully');
    } on BedCreationException catch (e) {
      _say(e.message);
    } catch (e) {
      _say('Failed to create BED file: ${describeError(e)}');
    }
  }

  Future<void> _generateMips() async {
    try {
      await client.mipgen.generateMips(widget.project.id!, _deleteExcessFiles);
      _reloadProject();
      _say('MIPs generation started successfully');
    } on FlumipFileNotFoundException catch (e) {
      _say(e.message);
    } on ArgumentException catch (e) {
      _say(e.message);
    } catch (e) {
      _say('Failed to generate MIPs: ${describeError(e)}');
    }
  }

  Future<List<String>> _genomeCategories() async {
    final categories = await client.genome.getCategories();
    categories.sort();
    return categories;
  }

  Future<List<Genome>> _genomesInCategory(String category) =>
      client.genome.getGenomeByCategory(category);

  /// The SNP sets this caller may use with [genomeId].
  ///
  /// Goes through `client.snp`, not `client.genome`: only that one filters by
  /// visibility, and having the picker and the genome tab disagree about what
  /// exists would be worse than either being wrong on its own.
  Future<List<Snp>> _snpsFor(int genomeId) =>
      client.snp.listSnpsForGenome(genomeId);

  /// Opens the genome picker and applies the answer.
  ///
  /// One dialog. The old flow was a category `DropdownButton` whose `onChanged`
  /// fetched genomes and *then* opened a dialog — two controls for one decision,
  /// with the dropdown hard-coded to `null` so it never reflected the choice.
  Future<void> _pickGenome() async {
    final List<String> categories;
    try {
      categories = await _genomeCategories();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Could not load genomes: ${describeError(e)}',
      );
      return;
    }
    if (!mounted) return;

    final picked = await showDialog<Genome>(
      context: context,
      builder: (_) => GenomePickerDialog(
        categories: categories,
        loadGenomes: _genomesInCategory,
        initialCategory: genome?.category,
        selectedGenomeId: widget.project.genome,
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      genome = picked;
      // The SNP list belongs to the old genome; drop it so the picker refetches.
      _snpsForGenome = null;
    });

    try {
      await client.project.setGeneById(widget.project.id!, picked.id!);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Failed to set genome: ${describeError(e)}',
      );
      return;
    }
    await _reloadProject();
  }

  /// Sets the project's SNP set, or clears it when [snpId] is null.
  Future<void> _setSnp(int? snpId) async {
    try {
      await client.project.setSnpById(widget.project.id!, snpId);
      await _reloadProject();
    } catch (e) {
      _say('Could not set the SNP set: ${describeError(e)}');
    }
  }

  Future<void> _setEmailNotification(bool enabled) async {
    try {
      await client.project.setEmailNotification(widget.project.id!, enabled);
      await _reloadProject();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Failed to change email notification: ${describeError(e)}';
      });
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// The SNP sets to offer, or null when they cannot be asked for yet.
  ///
  /// ⚠️ Only once the genome has actually loaded, and only while the project can
  /// still be edited — a finished project's SNP set is a fact about the run, not
  /// a choice, so listing the alternatives would be a query for nothing.
  Future<List<Snp>>? get _snpChoices {
    final genomeId = genome?.id;
    if (genomeId == null) return null;
    if (!ProjectInputsColumn.isEditable(widget.project)) return null;
    return _snpsForGenome ??= _snpsFor(genomeId);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: context.colours.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: IconButton(
              icon: Icon(
                _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              onPressed: _toggleExpand,
            ),
            // ⚠️ SelectableText, not Text. A project name is something people
            // copy into a lab notebook or an email, and in a Flutter web build
            // ordinary text cannot be selected at all.
            title: SelectableText(
              project.name,
              style: context.text.titleMedium,
            ),
            subtitle: project.description.isEmpty
                ? null
                : SelectableText(
                    project.description,
                    style: context.text.bodySmall,
                    maxLines: 2,
                  ),
            trailing: Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // What this project is doing, without having to open it.
                ProjectStatePill(state: ProjectState.of(project)),
                Text(DateFormat('dd.MM.yyyy').format(project.created)),
                Text(formatBytes(project.size)),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete project',
                  onPressed: _confirmDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            // Full width, above the three columns, so it appears once in both
            // layouts — ownership is a property of the project, not of any one
            // of them.
            if (widget.assignableOwners != null)
              OwnerPicker(
                owners: widget.assignableOwners!,
                ownerId: project.owner,
                onChanged: (id) => widget.onOwnerChanged?.call(id),
              ),
            Padding(
              // ⚠️ A bottom inset, not just horizontal. The columns used to run
              // flush into the tile's own border, so the last row of the design
              // options sat on the line.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ResponsiveRow(
                // Was `MediaQuery.sizeOf(context).width >= 795`, i.e. about
                // 265px a column. ResponsiveRow measures the tile rather than
                // the window, which is what keeps this honest now that the list
                // is capped: a wide monitor no longer implies a wide tile.
                minChildWidth: 260,
                spacing: 10,
                stackSpacing: 25,
                // ⚠️ One `SelectionArea` per column, nested inside the app-wide
                // one. Without them a drag across the design options runs on
                // into the results beside it, so copying the parameters gets you
                // the parameters *and* whatever sat to their right. A nested
                // SelectionArea claims its subtree, which scopes the drag to the
                // column it started in.
                children: [
                  SelectionArea(child: _inputs()),
                  SelectionArea(
                    child: ProjectOptionsView(options: projectOptions),
                  ),
                  SelectionArea(child: _runPanel()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputs() => ProjectInputsColumn(
    project: widget.project,
    genome: genome,
    snp: snp,
    snpsForGenome: _snpChoices,
    errorMessage: _errorMessage,
    onDismissError: () => setState(() => _errorMessage = null),
    onPickGenome: _pickGenome,
    onSnpChanged: _setSnp,
    onAddGene: _addGene,
    onRemoveGene: _removeGene,
  );

  Widget _runPanel() {
    final project = widget.project;
    return ProjectRunPanel(
      project: project,
      progress: _progress,
      notificationsAvailable: widget.notificationsAvailable,
      deleteExcessFiles: _deleteExcessFiles,
      onDeleteExcessFilesChanged: (value) =>
          setState(() => _deleteExcessFiles = value),
      onEmailNotificationChanged: _setEmailNotification,
      onCreateBedFile: _createBedFile,
      onGenerateMips: _generateMips,
      onShowMipsResult: () => showMipsResultDialog(context, project.id!),
      onShowSnpMipsResult: () => showSnpMipsResultDialog(context, project.id!),
      onShowUcscTrack: () => openUcscTrack(
        context,
        projectId: project.id!,
        // Unknown, or not yet loaded, means hg38 — which is what the app
        // installs by default and what `ucscTrackUrls` falls back to.
        genomeName: genome?.name ?? '',
      ),
      onShowUcscTrackFile: () => showUcscTrackFileDialog(context, project.id!),
      onShowDesignLog: () => showDesignLogDialog(context, project.id!),
      onShowDownloads: () => showProjectDownloadsDialog(context, project.id!),
    );
  }
}
