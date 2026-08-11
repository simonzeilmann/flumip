import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import '../error_text.dart';
import 'mipgen_progress.dart';
import 'project_inputs.dart';
import 'project_state.dart';

/// One project's own state: what it is, what it is doing, and everything that
/// changes it.
///
/// Every piece of I/O is a constructor parameter. This was the last widget in
/// the app reaching for `client` from inside a `State`, and the largest untested
/// surface left — the poll, the genome and SNP loading, and the whole run
/// lifecycle. Its *pieces* were already covered; the state driving them was not.
class ProjectTileController extends ChangeNotifier {
  ProjectTileController({
    required Project project,
    required bool expanded,
    required Future<Project> Function(int projectId) loadProject,
    required Future<ProjectOptions> Function(int optionsId) loadOptions,
    required Future<Genome> Function(int genomeId) loadGenome,
    required Future<Snp> Function(int snpId) loadSnp,
    required Future<List<String>> Function(int projectId) loadProgress,
    required Future<void> Function(int projectId, String gene) addGene,
    required Future<void> Function(int projectId, String gene) removeGene,
    required Future<void> Function(int projectId) createBedFile,
    required Future<void> Function(int projectId, bool deleteExcessFiles)
    generateMips,
    required Future<List<String>> Function() loadGenomeCategories,
    required Future<List<Genome>> Function(String category)
    loadGenomesInCategory,
    required Future<List<Snp>> Function(int genomeId) loadSnpsForGenome,
    required Future<void> Function(int projectId, int genomeId) setGenome,
    required Future<void> Function(int projectId, int? snpId) setSnp,
    required Future<void> Function(int projectId, bool enabled)
    setEmailNotification,
  }) : _project = project,
       _expanded = expanded,
       _loadProject = loadProject,
       _loadOptions = loadOptions,
       _loadGenome = loadGenome,
       _loadSnp = loadSnp,
       _loadProgress = loadProgress,
       _addGene = addGene,
       _removeGene = removeGene,
       _createBedFile = createBedFile,
       _generateMips = generateMips,
       _loadGenomeCategories = loadGenomeCategories,
       _loadGenomesInCategory = loadGenomesInCategory,
       _loadSnpsForGenome = loadSnpsForGenome,
       _setGenome = setGenome,
       _setSnp = setSnp,
       _setEmailNotification = setEmailNotification;

  final Future<Project> Function(int projectId) _loadProject;
  final Future<ProjectOptions> Function(int optionsId) _loadOptions;
  final Future<Genome> Function(int genomeId) _loadGenome;
  final Future<Snp> Function(int snpId) _loadSnp;
  final Future<List<String>> Function(int projectId) _loadProgress;
  final Future<void> Function(int projectId, String gene) _addGene;
  final Future<void> Function(int projectId, String gene) _removeGene;
  final Future<void> Function(int projectId) _createBedFile;
  final Future<void> Function(int projectId, bool deleteExcessFiles)
  _generateMips;
  final Future<List<String>> Function() _loadGenomeCategories;
  final Future<List<Genome>> Function(String category) _loadGenomesInCategory;
  final Future<List<Snp>> Function(int genomeId) _loadSnpsForGenome;
  final Future<void> Function(int projectId, int genomeId) _setGenome;
  final Future<void> Function(int projectId, int? snpId) _setSnp;
  final Future<void> Function(int projectId, bool enabled)
  _setEmailNotification;

  Project _project;
  bool _expanded;
  bool _deleteExcessFiles = false;
  ProjectOptions _options = ProjectOptions();

  /// The project's genome, or null while it is still being fetched.
  ///
  /// ⚠️ Was a `Genome(name: 'default')` sentinel, which read as a loaded genome
  /// with no id — so the SNP query did `genome.id!` on it and threw during the
  /// frame between opening a tile and its genome arriving. A thrown build is the
  /// red error screen over the whole tab.
  Genome? _genome;

  /// The project's chosen SNP set, or null while it is still being fetched.
  Snp? _snp;

  /// Cached so the `FutureBuilder` does not fire a fresh query on every rebuild
  /// — and this tile rebuilds every few seconds while a design runs.
  Future<List<Snp>>? _snpsForGenome;

  String? _errorMessage;
  Timer? _timer;
  bool _disposed = false;

  /// The run's progress file, re-read while the design is going.
  MipgenProgress _progress = const MipgenProgress.empty();

  final _messages = StreamController<String>.broadcast();

  Project get project => _project;
  ProjectOptions get options => _options;
  Genome? get genome => _genome;
  Snp? get snp => _snp;
  String? get errorMessage => _errorMessage;
  MipgenProgress get progress => _progress;
  bool get expanded => _expanded;
  bool get deleteExcessFiles => _deleteExcessFiles;

  /// One-off reports — the tile turns these into snack bars.
  Stream<String> get messages => _messages.stream;

  /// Whether a tick is actually pending. For tests.
  @visibleForTesting
  bool get polling => _timer?.isActive ?? false;

  /// Takes the list's newer copy of this project.
  ///
  /// The tab refetches the whole list, and this is how a change made elsewhere —
  /// an owner reassignment, say — reaches an open tile.
  void adopt(Project project) {
    _project = project;
    _notify();
  }

  Future<void> toggleExpanded() async {
    _expanded = !_expanded;
    // The genome and SNP are reloaded on open; drop them so a stale one cannot
    // flash under the new heading.
    _genome = null;
    _snp = null;
    _snpsForGenome = null;
    _notify();

    if (_expanded) {
      await refresh();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Opens the tile if it is not already, for a project that has just been made.
  Future<void> openIfNeeded() => _expanded ? refresh() : Future.value();

  Future<void> refresh() async {
    try {
      final project = await _loadProject(_project.id!);
      final options = await _loadOptions(_project.options);
      Genome? genome;
      if (_project.genome != null) {
        genome = await _loadGenome(_project.genome!);
      }
      Snp? snp;
      if (_project.snp != null) {
        snp = await _loadSnp(_project.snp!);
      }

      _project = project;
      _options = options;
      if (genome != null) _genome = genome;
      if (snp != null) _snp = snp;
      _notify();

      // Only while something is actually being written, so a finished project
      // does not re-read its log forever.
      if (ProjectState.of(project).isRunning) await _refreshProgress();
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
      // A deleted project needs no error at all — the row is on its way out.
      if (_isGone(e)) return;
      _errorMessage = 'Failed to reload project: ${describeError(e)}';
      _notify();
      if (!isAccessDenied(e)) _rearm();
    }
  }

  /// Whether this error means the project no longer exists.
  ///
  /// The poll and the delete race by nature: a tick can be in flight when the
  /// row is removed, and the answer comes back as "not found".
  static bool _isGone(Object error) => error is FlumipFileNotFoundException;

  /// Reads the progress file, best-effort.
  ///
  /// Never surfaces its own failure: the run's state comes from the project row,
  /// and an unreadable progress file is not worth an error banner over a design
  /// that is going fine.
  Future<void> _refreshProgress() async {
    try {
      _progress = MipgenProgress(lines: await _loadProgress(_project.id!));
      _notify();
    } catch (_) {
      // Left as it was; the panel keeps showing the last line it had.
    }
  }

  /// Schedules the next refresh, or stops.
  ///
  /// Faster while a design is running, because that is the only time the project
  /// changes on its own — and it is exactly when somebody is watching it.
  ///
  /// ⚠️ Nothing is scheduled while the tile is shut. This was one
  /// `Timer.periodic(10s)` per tile in the list, so a hundred projects meant a
  /// hundred timers waking up to find the tile collapsed and do nothing.
  void _rearm() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || !_expanded) return;

    final running = ProjectState.of(_project).isRunning;
    _timer = Timer(
      running ? const Duration(seconds: 3) : const Duration(seconds: 15),
      () {
        if (_disposed) return;
        refresh();
      },
    );
  }

  // ------------------------------------------------------------- actions ---

  Future<void> addGene(String gene) =>
      _run(() => _addGene(_project.id!, gene), failure: 'Failed to add gene');

  Future<void> removeGene(String gene) => _run(
    () => _removeGene(_project.id!, gene),
    failure: 'Failed to remove gene',
  );

  Future<void> createBedFile() async {
    try {
      await _createBedFile(_project.id!);
      await refresh();
      _say('BED file created successfully');
    } on BedCreationException catch (e) {
      _say(e.message);
    } catch (e) {
      _say('Failed to create BED file: ${describeError(e)}');
    }
  }

  Future<void> generateMips() async {
    try {
      await _generateMips(_project.id!, _deleteExcessFiles);
      // ⚠️ Not awaited. The refresh is what starts the poll, and the message
      // should appear the moment the run is accepted rather than a round trip
      // later.
      refresh();
      _say('MIPs generation started successfully');
    } on FlumipFileNotFoundException catch (e) {
      _say(e.message);
    } on ArgumentException catch (e) {
      _say(e.message);
    } catch (e) {
      _say('Failed to generate MIPs: ${describeError(e)}');
    }
  }

  void setDeleteExcessFiles(bool value) {
    _deleteExcessFiles = value;
    _notify();
  }

  Future<void> setEmailNotification(bool enabled) async {
    try {
      await _setEmailNotification(_project.id!, enabled);
      await refresh();
    } catch (e) {
      _errorMessage =
          'Failed to change email notification: ${describeError(e)}';
      _notify();
    }
  }

  /// The categories the genome picker offers.
  Future<List<String>> genomeCategories() async {
    final categories = await _loadGenomeCategories();
    // Sorted on our own copy: the list belongs to the caller.
    return [...categories]..sort();
  }

  Future<List<Genome>> genomesInCategory(String category) =>
      _loadGenomesInCategory(category);

  /// Applies a genome chosen in the picker.
  Future<void> chooseGenome(Genome picked) async {
    _genome = picked;
    // The SNP list belongs to the old genome; drop it so the picker refetches.
    _snpsForGenome = null;
    _notify();

    try {
      await _setGenome(_project.id!, picked.id!);
    } catch (e) {
      _errorMessage = 'Failed to set genome: ${describeError(e)}';
      _notify();
      return;
    }
    await refresh();
  }

  void reportGenomeLoadFailure(Object error) {
    _errorMessage = 'Could not load genomes: ${describeError(error)}';
    _notify();
  }

  /// Sets the project's SNP set, or clears it when [snpId] is null.
  Future<void> setSnp(int? snpId) async {
    try {
      await _setSnp(_project.id!, snpId);
      await refresh();
    } catch (e) {
      _say('Could not set the SNP set: ${describeError(e)}');
    }
  }

  /// The SNP sets to offer, or null when they cannot be asked for yet.
  ///
  /// ⚠️ Only once the genome has actually loaded, and only while the project can
  /// still be edited — a finished project's SNP set is a fact about the run, not
  /// a choice, so listing the alternatives would be a query for nothing.
  Future<List<Snp>>? get snpChoices {
    final genomeId = _genome?.id;
    if (genomeId == null) return null;
    if (!ProjectInputsColumn.isEditable(_project)) return null;
    return _snpsForGenome ??= _loadSnpsForGenome(genomeId);
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failure,
  }) async {
    try {
      await action();
      await refresh();
    } catch (e) {
      _say('$failure: ${describeError(e)}');
    }
  }

  void dismissError() {
    _errorMessage = null;
    _notify();
  }

  void _say(String message) {
    if (_disposed) return;
    _messages.add(message);
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _messages.close();
    super.dispose();
  }
}
