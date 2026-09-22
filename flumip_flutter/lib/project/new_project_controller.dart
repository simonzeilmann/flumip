import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/widgets.dart';

import '../error_text.dart';
import 'project_options_form.dart';

/// The create-project form: the two fields that are about the project, the 28
/// design parameters, and the two calls that turn them into a row.
///
/// Backs `CreateProjectWidget`. Every piece of I/O is a constructor parameter,
/// so the validation and the two-step create run on the Dart VM with no server.
///
/// ⚠️ Owns its controllers, [ProjectOptionsForm] included, and is built fresh
/// each time the form is opened — a half-filled form from a cancelled attempt
/// should not come back.
class NewProjectController extends ChangeNotifier {
  NewProjectController({
    required this._loadDefaultOptions,
    required this._insertOptions,
    required this._createProject,
  });

  final Future<ProjectOptions> Function() _loadDefaultOptions;
  final Future<ProjectOptions> Function(ProjectOptions options) _insertOptions;
  final Future<Project> Function(
    String name,
    ProjectOptions options,
    String description,
  )
  _createProject;

  final name = TextEditingController();
  final description = TextEditingController();
  final options = ProjectOptionsForm();

  String? _errorMessage;
  bool _showOptions = false;
  bool _disposed = false;

  String? get errorMessage => _errorMessage;

  /// Whether the design parameters are unfolded. Shut by default: the defaults
  /// come from the server and suit most panels.
  bool get showOptions => _showOptions;

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

  /// Creates the project, or returns null and reports why.
  ///
  /// ⚠️ Two calls, in order: the options row has to exist before a project can
  /// point at it. Returning the created project rather than calling back keeps
  /// the navigation decision with the widget.
  Future<Project?> create() async {
    if (name.text.isEmpty) {
      _errorMessage = 'Project name is required';
      _notify();
      return null;
    }
    try {
      final stored = await _insertOptions(options.toOptions());
      final created = await _createProject(name.text, stored, description.text);
      name.clear();
      description.clear();
      return created;
    } catch (e) {
      _errorMessage = describeError(e);
      _notify();
      return null;
    }
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
