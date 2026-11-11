import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/widgets.dart';

import '../error_text.dart';
import 'project_options_form.dart';

/// How far a press on "Save" or "Save and start" has got.
enum NewProjectBusy {
  /// Nothing is in flight; the buttons are live.
  idle,

  /// The project is being stored.
  saving,

  /// The project exists, and its BED file and run are being started.
  starting,
}

/// What a successful save produced.
///
/// A save that fails has no result at all — the form stays open and says why.
/// This exists for the case in between: the project was stored, so the form is
/// finished with, but "Save and start" could not start it.
class NewProjectResult {
  const NewProjectResult({
    required this.project,
    this.started = false,
    this.startError,
  });

  final Project project;

  /// Whether a run was started (or queued) as part of the save.
  final bool started;

  /// Why the run did not start, in words for the user; null when it did, or
  /// when nobody asked for one.
  final String? startError;
}

/// The create-project form: everything a project needs, and the one call that
/// turns it into a row.
///
/// Backs `CreateProjectWidget`. Every piece of I/O is a constructor parameter,
/// so the validation and the save run on the Dart VM with no server.
///
/// ⚠️ **Nothing is stored until "Save".** The project tile writes each change
/// the moment it is made, because there the project already exists. Here the
/// genome, the SNP set and the genes are only fields, and the whole form goes
/// to the server as one `ProjectDraftDto` — which is what lets "Cancel" mean
/// that nothing happened.
///
/// ⚠️ Owns its controllers, [ProjectOptionsForm] included, and is built fresh
/// each time the form is opened — a half-filled form from a cancelled attempt
/// should not come back.
class NewProjectController extends ChangeNotifier {
  NewProjectController({
    required this._loadDefaultOptions,
    required this._saveProject,
    required this._loadGenomeCategories,
    required this._loadGenomesInCategory,
    required this._loadSnpsForGenome,
    required this._createBedFile,
    required this._generateMips,
  });

  /// What "Save and start" needs before it can be pressed. The wording of the
  /// tile's "Create BED file" button, which has the same requirement.
  static const startRequirement =
      'Choose a genome and add at least one gene first.';

  /// What a gene symbol may look like. The server's rule, repeated here only so
  /// that a mistyped gene is refused when it is typed rather than when the
  /// whole form is saved; the server checks again.
  static final _geneSymbol = RegExp(r'^[A-Za-z0-9]+$');

  final Future<ProjectOptions> Function() _loadDefaultOptions;
  final Future<Project> Function(ProjectDraftDto draft) _saveProject;
  final Future<List<String>> Function() _loadGenomeCategories;
  final Future<List<Genome>> Function(String category) _loadGenomesInCategory;
  final Future<List<Snp>> Function(int genomeId) _loadSnpsForGenome;
  final Future<void> Function(int projectId) _createBedFile;
  final Future<void> Function(int projectId, bool deleteExcessFiles)
  _generateMips;

  final name = TextEditingController();
  final description = TextEditingController();
  final options = ProjectOptionsForm();

  String? _errorMessage;
  bool _showOptions = false;
  bool _disposed = false;

  Genome? _genome;
  int? _snpId;
  Future<List<Snp>>? _snpsForGenome;
  final List<String> _genes = [];
  bool _deleteExcessFiles = true;
  bool _emailNotification = false;
  NewProjectBusy _busy = NewProjectBusy.idle;

  String? get errorMessage => _errorMessage;

  /// Whether the design parameters are unfolded. Shut by default: the defaults
  /// come from the server and suit most panels.
  bool get showOptions => _showOptions;

  /// The genome to design against, or null while none is chosen.
  Genome? get genome => _genome;

  /// The chosen SNP set, or null for none.
  int? get snpId => _snpId;

  /// The SNP sets for [genome], or null while no genome is chosen.
  ///
  /// One future per genome, kept here rather than asked for in `build`, so a
  /// rebuild does not fetch the list again.
  Future<List<Snp>>? get snpsForGenome => _snpsForGenome;

  List<String> get genes => List.unmodifiable(_genes);

  /// Whether the run's intermediate files are deleted. Only "Save and start"
  /// uses it; on by default, as on the tile.
  bool get deleteExcessFiles => _deleteExcessFiles;

  bool get emailNotification => _emailNotification;

  NewProjectBusy get busy => _busy;

  /// Whether a save is in flight — or has succeeded, see [save].
  bool get isBusy => _busy != NewProjectBusy.idle;

  /// Whether there is enough here to start a run: the BED file is built from
  /// the genes against the genome, so it needs both.
  bool get canStart => _genome != null && _genes.isNotEmpty;

  /// Fills the form with the server's defaults.
  Future<void> loadDefaults() async {
    try {
      options.load(await _loadDefaultOptions());
      _notify();
    } catch (e) {
      _errorMessage = 'Failed to load default options: ${describeError(e)}';
      _notify();
    }
  }

  void toggleOptions() {
    _showOptions = !_showOptions;
    _notify();
  }

  /// Called by the option fields, whose switches need a rebuild to move.
  void optionsChanged() => _notify();

  /// The categories the genome picker offers.
  Future<List<String>> genomeCategories() async {
    final categories = await _loadGenomeCategories();
    // Sorted on our own copy: the list belongs to the caller.
    return [...categories]..sort();
  }

  Future<List<Genome>> genomesInCategory(String category) =>
      _loadGenomesInCategory(category);

  void reportGenomeLoadFailure(Object error) {
    _errorMessage = 'Could not load genomes: ${describeError(error)}';
    _notify();
  }

  /// Applies a genome chosen in the picker.
  ///
  /// ⚠️ Changing the genome drops the SNP set. A set is called against one
  /// build, and the server refuses a set from another — so keeping the choice
  /// would only turn a visible reset into a refused save.
  void chooseGenome(Genome picked) {
    if (picked.id == _genome?.id) return;
    _genome = picked;
    _snpId = null;
    final id = picked.id;
    _snpsForGenome = id == null ? null : _loadSnpsForGenome(id);
    _notify();
  }

  /// Sets the SNP set, or clears it when [snpId] is null.
  void setSnp(int? snpId) {
    _snpId = snpId;
    _notify();
  }

  /// Adds a gene, stored the way the server stores it: trimmed and upper-cased.
  void addGene(String gene) {
    final typed = gene.trim();
    if (typed.isEmpty) return;
    final symbol = typed.toUpperCase();
    // The server's wording for both refusals, so the form and the tile say the
    // same thing about the same mistake.
    if (!_geneSymbol.hasMatch(typed)) {
      _errorMessage =
          'A gene symbol can only contain letters and numbers, so "$typed" '
          'cannot be one.';
    } else if (_genes.contains(symbol)) {
      _errorMessage = '$symbol is already on this project.';
    } else {
      _genes.add(symbol);
      _errorMessage = null;
    }
    _notify();
  }

  void removeGene(String gene) {
    _genes.remove(gene);
    _notify();
  }

  void setDeleteExcessFiles(bool value) {
    _deleteExcessFiles = value;
    _notify();
  }

  void setEmailNotification(bool value) {
    _emailNotification = value;
    _notify();
  }

  /// Stores the project and, with [start], builds its BED file and starts the
  /// run. Returns null — and reports why — when nothing was stored.
  ///
  /// ⚠️ **Once the project exists this never fails.** The save is one call that
  /// stores everything or nothing, so a refusal there leaves the form open with
  /// nothing behind it. Starting is two more calls on a project that is already
  /// in the list, and either can refuse for reasons the form cannot know — a
  /// gene the genome does not have, a guest who already has a run going. That
  /// comes back as [NewProjectResult.startError] with the project, never as
  /// null: the caller closes the form and opens the project, where the same
  /// two steps are buttons. Leaving the form open instead would offer "Save"
  /// again on a project that is already saved.
  ///
  /// ⚠️ [busy] is deliberately **not** reset after a success, for the same
  /// reason. It is also what stops a double click from saving twice.
  Future<NewProjectResult?> save({required bool start}) async {
    if (isBusy) return null;
    if (name.text.isEmpty) {
      // The server's own wording for the same refusal, so the guard reads as
      // the same rule rather than a second, differently-worded one.
      _errorMessage = 'A project needs a name.';
      _notify();
      return null;
    }
    if (start && !canStart) {
      _errorMessage = startRequirement;
      _notify();
      return null;
    }

    _errorMessage = null;
    _busy = NewProjectBusy.saving;
    _notify();

    final Project created;
    try {
      created = await _saveProject(
        ProjectDraftDto(
          name: name.text,
          description: description.text,
          options: options.toOptions(),
          genome: _genome?.id,
          snp: _snpId,
          genes: [..._genes],
          emailNotification: _emailNotification,
        ),
      );
    } catch (e) {
      _busy = NewProjectBusy.idle;
      _errorMessage = describeError(e);
      _notify();
      return null;
    }
    if (!start) return NewProjectResult(project: created);

    _busy = NewProjectBusy.starting;
    _notify();
    try {
      await _createBedFile(created.id!);
      await _generateMips(created.id!, _deleteExcessFiles);
    } catch (e) {
      return NewProjectResult(
        project: created,
        startError:
            'The project was saved, but could not be started: '
            '${describeError(e)}',
      );
    }
    return NewProjectResult(project: created, started: true);
  }

  void dismissError() {
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    name.dispose();
    description.dispose();
    options.dispose();
    super.dispose();
  }
}
