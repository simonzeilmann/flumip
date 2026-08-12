import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../format.dart';
import '../services.dart';
import '../ui/responsive_row.dart';
import '../ui/theme.dart';
import 'genome_picker_dialog.dart';
import 'owner_picker.dart';
import 'project_inputs.dart';
import 'project_options_view.dart';
import 'project_result_actions.dart';
import 'project_run_panel.dart';
import 'project_state.dart';
import 'project_state_pill.dart';
import 'project_tile_controller.dart';

/// One project in the list: a row that says what it is doing, and — when opened —
/// its inputs, its design parameters and its results.
///
/// Loading, polling and every endpoint call live in [ProjectTileController].
/// What is left here is layout, two dialogs and the snack bars — the parts that
/// need a `BuildContext`. Everything it draws is a sibling widget that takes data
/// and callbacks:
///
///  * `project_inputs.dart` — genome, SNP set, genes
///  * `project_options_view.dart` — the design parameters
///  * `project_run_panel.dart` — the BED step, the run, the results
///  * `project_state_pill.dart` — the collapsed row's badge
///  * `project_result_actions.dart` — opening result files and downloads
///  * `ucsc_track.dart` — building the UCSC links
class ProjectTile extends StatefulWidget {
  const ProjectTile({
    super.key,
    required this.project,
    required this.onDelete,
    this.notificationsAvailable = false,
    this.assignableOwners,
    this.onOwnerChanged,
    this.initiallyExpanded = false,
    this.controller,
  });

  /// ⚠️ `final` now, and the class is `const`-constructible again. It used to be
  /// a mutable field the tile wrote its own reload results back into, which is
  /// what the `must_be_immutable` suppression was hiding. The controller holds
  /// the project it is showing; this is only the list's copy.
  final Project project;

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

  /// Opens without a click: a project that has just been created, or one a search
  /// result revealed.
  ///
  /// Read on build *and* watched in `didUpdateWidget`, because a revealed project
  /// may already be on screen with a `State` of its own.
  final bool initiallyExpanded;

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Owned by this widget when it builds its own: it holds a poll for one
  /// project, and there is one of these per row.
  final ProjectTileController? controller;

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  late final bool _ownsController = widget.controller == null;
  late final ProjectTileController _controller =
      widget.controller ??
      createProjectTileController(
        widget.project,
        expanded: widget.initiallyExpanded,
      );
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _messages = _controller.messages.listen(_say);
    // A tile that opens itself still has to load what it is going to show.
    _controller.openIfNeeded();
  }

  @override
  void didUpdateWidget(ProjectTile old) {
    super.didUpdateWidget(old);
    // The tab refetched the list; take its newer copy.
    if (!identical(old.project, widget.project)) {
      _controller.adopt(widget.project);
    }
    // ⚠️ A search result asking for a row that is already on screen. This tile is
    // keyed `ValueKey(project.id)`, so a project that was already in the list
    // keeps its `State` and never re-reads [ProjectTile.initiallyExpanded] through
    // the constructor — without this the tab would scroll the revealed project to
    // the top and leave it shut. The flag now means "should be open", not only
    // "starts open".
    if (!old.initiallyExpanded &&
        widget.initiallyExpanded &&
        !_controller.expanded) {
      // Loads what the open tile shows, so nothing extra is needed here.
      _controller.toggleExpanded();
    }
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

  /// Opens the genome picker and applies the answer.
  ///
  /// One dialog. The old flow was a category `DropdownButton` whose `onChanged`
  /// fetched genomes and *then* opened a dialog — two controls for one decision,
  /// with the dropdown hard-coded to `null` so it never reflected the choice.
  Future<void> _pickGenome() async {
    final List<String> categories;
    try {
      categories = await _controller.genomeCategories();
    } catch (e) {
      _controller.reportGenomeLoadFailure(e);
      return;
    }
    if (!mounted) return;

    final picked = await showDialog<Genome>(
      context: context,
      builder: (_) => GenomePickerDialog(
        categories: categories,
        loadGenomes: _controller.genomesInCategory,
        initialCategory: _controller.genome?.category,
        selectedGenomeId: _controller.project.genome,
      ),
    );
    if (picked == null) return;
    await _controller.chooseGenome(picked);
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

  @override
  Widget build(BuildContext context) {
    final project = _controller.project;
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
                _controller.expanded
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
              ),
              onPressed: _controller.toggleExpanded,
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
          if (_controller.expanded) ...[
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
                    child: ProjectOptionsView(options: _controller.options),
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
    project: _controller.project,
    genome: _controller.genome,
    snp: _controller.snp,
    snpsForGenome: _controller.snpChoices,
    errorMessage: _controller.errorMessage,
    onDismissError: _controller.dismissError,
    onPickGenome: _pickGenome,
    onSnpChanged: _controller.setSnp,
    onAddGene: _controller.addGene,
    onRemoveGene: _controller.removeGene,
  );

  Widget _runPanel() {
    final project = _controller.project;
    return ProjectRunPanel(
      project: project,
      progress: _controller.progress,
      notificationsAvailable: widget.notificationsAvailable,
      deleteExcessFiles: _controller.deleteExcessFiles,
      onDeleteExcessFilesChanged: _controller.setDeleteExcessFiles,
      onEmailNotificationChanged: _controller.setEmailNotification,
      onCreateBedFile: _controller.createBedFile,
      onGenerateMips: _controller.generateMips,
      onShowMipsResult: () => showMipsResultDialog(context, project.id!),
      onShowSnpMipsResult: () => showSnpMipsResultDialog(context, project.id!),
      onShowUcscTrack: () => openUcscTrack(
        context,
        projectId: project.id!,
        // Unknown, or not yet loaded, means hg38 — which is what the app
        // installs by default and what `ucscTrackUrls` falls back to.
        genomeName: _controller.genome?.name ?? '',
      ),
      onShowUcscTrackFile: () => showUcscTrackFileDialog(context, project.id!),
      onShowDesignLog: () => showDesignLogDialog(context, project.id!),
      onShowDownloads: () => showProjectDownloadsDialog(context, project.id!),
    );
  }
}
