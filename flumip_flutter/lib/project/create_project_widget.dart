import 'package:flumip_client/flumip_client.dart';
import 'package:material_ui/material_ui.dart';

import '../services.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';
import '../ui/theme.dart';
import 'gene_editor.dart';
import 'genome_picker_dialog.dart';
import 'new_project_controller.dart';
import 'project_inputs.dart';
import 'project_options_fields.dart';

/// The create-project form: everything a project needs, on one page.
///
/// A name and a description, what to design against (genome, SNP set, genes),
/// the MIP design options, and how the run should behave. It ends in three
/// actions:
///
/// - **Cancel** — nothing was stored, so nothing is undone.
/// - **Save** — stores the project as a draft. It opens in the list, where
///   everything here can still be changed.
/// - **Save and start** — stores it, builds the BED file and starts the run.
///
/// ⚠️ **This used to be two steps.** The form asked for a name and the design
/// options and made a bare project; the genome, the SNP set and the genes were
/// then set on the project's tile, one call each, followed by two more buttons
/// to start it. Nothing about that order was necessary — it was the order the
/// endpoints had been written in.
///
/// The fields live in [NewProjectController] and `ProjectOptionsFields`; this is
/// the layout and the one decision that needs a widget — what to do once the
/// project exists.
class CreateProjectWidget extends StatefulWidget {
  const CreateProjectWidget({
    super.key,
    required this.onSaved,
    required this.onAbort,
    this.notificationsAvailable = false,
    this.willHaveOwner = false,
    this.controller,
  });

  /// Called once the project exists, so the list can open it — and say whether
  /// it was started.
  final void Function(NewProjectResult result) onSaved;
  final VoidCallback onAbort;

  /// Whether the server can send mail at all. The "Email me" switch is not
  /// offered when it cannot, as on the tile.
  final bool notificationsAvailable;

  /// Whether the project will be stamped with an owner — that is, whether
  /// somebody is signed in. Without one there is nobody to mail, and the
  /// switch says so rather than promising mail that never arrives.
  final bool willHaveOwner;

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Owned by this widget when it builds its own, and built fresh every time
  /// the form is opened — a half-filled form from a cancelled attempt should not
  /// come back.
  final NewProjectController? controller;

  @override
  State<CreateProjectWidget> createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  late final bool _ownsController = widget.controller == null;
  late final NewProjectController _controller =
      widget.controller ?? createNewProjectController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.loadDefaults();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Which of the two saving buttons was pressed, so that one can say what is
  /// happening while both are disabled.
  bool _starting = false;

  Future<void> _save({required bool start}) async {
    setState(() => _starting = start);
    final result = await _controller.save(start: start);
    if (result != null) widget.onSaved(result);
  }

  /// Opens the genome picker and applies the answer. The tile's picker, fed
  /// from this form's controller.
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
        selectedGenomeId: _controller.genome?.id,
      ),
    );
    if (picked != null) _controller.chooseGenome(picked);
  }

  @override
  Widget build(BuildContext context) {
    final error = _controller.errorMessage;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ContentWidth(
              maxWidth: ContentWidth.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  if (error != null)
                    ErrorBanner(error, onDismiss: _controller.dismissError),
                  _detailsSection(),
                  _targetSection(context),
                  _optionsToggle(),
                  if (_controller.showOptions)
                    ProjectOptionsFields(
                      form: _controller.options,
                      onChanged: _controller.optionsChanged,
                    ),
                  _runSection(),
                ],
              ),
            ),
          ),
        ),
        FormSaveBar.custom(maxWidth: ContentWidth.form, children: _actions()),
      ],
    );
  }

  /// Cancel, Save, and Save and start.
  ///
  /// ⚠️ All three go dead while a save is in flight, and stay dead once it has
  /// succeeded — the form is about to be replaced by the list, and a second
  /// press in between would store the project twice. The button that was
  /// pressed says how far it has got.
  List<Widget> _actions() {
    final busy = _controller.isBusy;
    final canStart = _controller.canStart;

    final start = FilledButton.icon(
      onPressed: busy || !canStart ? null : () => _save(start: true),
      icon: busy && _starting
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow),
      label: Text(
        !busy || !_starting
            ? 'Save and start'
            : _controller.busy == NewProjectBusy.starting
            ? 'Starting…'
            : 'Saving…',
      ),
    );

    return [
      TextButton(
        onPressed: busy ? null : widget.onAbort,
        child: const Text('Cancel'),
      ),
      FilledButton.tonal(
        onPressed: busy ? null : () => _save(start: false),
        child: Text(busy && !_starting ? 'Saving…' : 'Save'),
      ),
      // A disabled button explains nothing on its own, so it says what it is
      // waiting for — the same sentence as the tile's "Create BED file".
      if (canStart)
        start
      else
        Tooltip(message: NewProjectController.startRequirement, child: start),
    ];
  }

  /// Name and description.
  ///
  /// ⚠️ Neither field is full-bleed any more. They used to be direct children of
  /// a `Column` with no spacing at all, so the two boxes touched — and after the
  /// projects list was capped at 1400px they were 1400px wide for a project
  /// called "test33".
  FormSection _detailsSection() => FormSection(
    title: 'Project',
    children: [
      ResponsiveRow(
        minChildWidth: 260,
        // The name is short and the description is not, so an even split would
        // waste the room the description actually needs.
        flex: const [2, 3],
        children: [
          TextField(
            controller: _controller.name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText: 'Required.',
            ),
          ),
          TextField(
            controller: _controller.description,
            // A description is prose, so it gets a box that grows rather than a
            // one-line field that scrolls sideways.
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Description',
              helperText: 'Optional.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ],
  );

  /// What the MIPs are designed against.
  ///
  /// The same three inputs, and the same widgets, as the project tile's left
  /// column — but nothing here is stored until the form is saved.
  FormSection _targetSection(BuildContext context) {
    final genome = _controller.genome;
    final snps = _controller.snpsForGenome;
    final muted = TextStyle(color: context.colours.onSurfaceVariant);

    return FormSection(
      title: 'Design target',
      description:
          'What the MIPs are designed against. A run needs a genome and at '
          'least one gene; all of it can also be set later on the project.',
      children: [
        InputRow(
          label: 'Genome',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  genome?.name ?? 'None chosen',
                  style: genome == null ? muted : null,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _controller.isBusy ? null : _pickGenome,
                child: Text(genome == null ? 'Choose' : 'Change'),
              ),
            ],
          ),
        ),
        InputRow(
          label: 'SNP set',
          child: genome == null || snps == null
              ? Text('Choose a genome first.', style: muted)
              : SnpSelector(
                  // ⚠️ Keyed on the genome. The dropdown keeps its own value,
                  // and without a new state it would go on showing a set from
                  // the genome that was just replaced.
                  key: ValueKey(genome.id),
                  snps: snps,
                  selectedId: _controller.snpId,
                  onChanged: _controller.setSnp,
                ),
        ),
        InputRow(
          label: 'Genes',
          child: GeneEditor(
            genes: _controller.genes,
            editable: true,
            onAdd: _controller.addGene,
            onRemove: _controller.removeGene,
          ),
        ),
      ],
    );
  }

  /// How the run behaves. The tile's two switches, with the tile's wording.
  FormSection _runSection() => FormSection(
    title: 'Run',
    description: 'How the run behaves when it is started.',
    children: [
      SwitchListTile(
        value: _controller.deleteExcessFiles,
        title: const Text('Delete intermediate files'),
        subtitle: const Text(
          'Saves a lot of disk space. Turn off to keep them for debugging.',
        ),
        contentPadding: EdgeInsets.zero,
        onChanged: _controller.setDeleteExcessFiles,
      ),
      if (widget.notificationsAvailable)
        SwitchListTile(
          value: widget.willHaveOwner && _controller.emailNotification,
          title: const Text('Email me when it finishes'),
          subtitle: widget.willHaveOwner
              ? null
              : const Text('This project will have no owner to notify.'),
          contentPadding: EdgeInsets.zero,
          onChanged: widget.willHaveOwner
              ? _controller.setEmailNotification
              : null,
        ),
    ],
  );

  Widget _optionsToggle() => FormSection(
    title: 'MIP design options',
    description:
        'Defaults come from the server and suit most panels. '
        'Change them only if you know which knob you are turning.',
    children: [
      SwitchListTile(
        value: _controller.showOptions,
        title: const Text('Show options'),
        contentPadding: EdgeInsets.zero,
        onChanged: (_) => _controller.toggleOptions(),
      ),
    ],
  );
}
