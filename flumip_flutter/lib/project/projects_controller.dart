import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

import '../error_text.dart';
import 'project_state.dart';

/// The projects list: what is in it, and everything that changes it.
///
/// Every piece of I/O is a constructor parameter, so the whole of this file runs
/// on the Dart VM with no server — the same shape as [AuthController],
/// [AccessController] and `SnpUploadController`, which are the three things in
/// this app that were already testable and the reason this pattern was chosen
/// over an interface per endpoint.
///
/// ⚠️ The generated Serverpod `Client` cannot be faked: its endpoint fields are
/// `late final` and assigned in its own constructor, so nothing can subclass it
/// and swap one out. That is why the dependencies here are functions rather than
/// a client, and why an `InheritedWidget` carrying the real client would not have
/// made the tab testable.
class ProjectsController extends ChangeNotifier {
  ProjectsController({
    required this._loadProjects,
    required this._deleteProject,
    required this._setOwner,
    required this._setDepartment,
    required this._loadAssignableDepartments,
    required this._loadNotificationsAvailable,
    required this._loadAssignableOwners,
    required this._isAdmin,
    this._auth,
  }) {
    // Who may reassign a project changes with sign-in state, and `TabBarView`
    // builds this tab before the bearer token exists — the same reason
    // AccessController listens.
    _auth?.addListener(_onAuthChanged);
  }

  final Future<List<Project>> Function() _loadProjects;
  final Future<void> Function(int projectId) _deleteProject;
  final Future<void> Function(int projectId, int? ownerId) _setOwner;
  final Future<void> Function(int projectId, String? department) _setDepartment;
  final Future<List<String>> Function() _loadAssignableDepartments;
  final Future<bool> Function() _loadNotificationsAvailable;
  final Future<List<FlumipUserDto>> Function() _loadAssignableOwners;
  final bool Function() _isAdmin;
  final Listenable? _auth;

  List<Project>? _projects;
  String? _errorMessage;
  bool _notificationsAvailable = false;
  List<FlumipUserDto>? _assignableOwners;
  List<String> _assignableDepartments = const [];
  int? _openProjectId;
  bool _disposed = false;
  Timer? _timer;

  /// How often the list re-reads itself while a design is running.
  ///
  /// ⚠️ The tile polls every three seconds, but only while it is *open*. The
  /// collapsed row's state pill had nothing driving it at all, so a design that
  /// finished while the tile was shut went on reading "Designing" until somebody
  /// opened it. A minute is enough for a job measured in minutes, and it is one
  /// query for the whole list rather than one per row.
  static const runningPollInterval = Duration(minutes: 1);

  /// The projects, newest first, or null until the first answer arrives.
  List<Project>? get projects => _projects;

  String? get errorMessage => _errorMessage;

  /// True before the list has loaded and while nothing has gone wrong.
  bool get loading => _projects == null && _errorMessage == null;

  /// Whether an administrator has mail switched on for this install.
  bool get notificationsAvailable => _notificationsAvailable;

  /// The users a project can be handed to, or null when the viewer is not an
  /// administrator.
  ///
  /// ⚠️ Null and empty mean different things and the tile depends on it: null
  /// hides the picker entirely, an empty list means "an install with no users".
  List<FlumipUserDto>? get assignableOwners => _assignableOwners;

  /// The groups a project can be put into, or empty when this install does not
  /// collect them — which is the default, and hides the picker entirely.
  List<String> get assignableDepartments => _assignableDepartments;

  /// The project to open without a click: one just created, or one [reveal]ed by
  /// a search result.
  int? get openProjectId => _openProjectId;

  /// Whether a tick is actually pending. For tests.
  @visibleForTesting
  bool get polling => _timer?.isActive ?? false;

  /// Loads everything the list needs.
  Future<void> load() async {
    await Future.wait([
      refresh(),
      _refreshNotificationsAvailable(),
      _refreshAssignableOwners(),
      _refreshAssignableDepartments(),
    ]);
  }

  Future<void> refresh() async {
    try {
      final projects = await _loadProjects();
      _projects = _ordered(projects);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = describeError(e);
    }
    _notify();
    _rearm();
  }

  /// Newest first, with [openProjectId] — if any — hoisted to the top.
  ///
  /// ⚠️ Sorted here rather than by the caller, and on our own copy: the list the
  /// endpoint returns is ours to order, but sorting a list somebody else handed us
  /// in a test would be a surprise.
  ///
  /// Called from [refresh] as well as [reveal], so the one-minute poll cannot put
  /// a revealed project back where it was while somebody is looking at it.
  List<Project>? _ordered(List<Project>? projects) {
    if (projects == null) return null;
    final ordered = [...projects]
      ..sort((a, b) => b.created.compareTo(a.created));

    final open = _openProjectId;
    if (open == null) return ordered;
    final index = ordered.indexWhere((p) => p.id == open);
    if (index <= 0) return ordered;
    return [ordered[index], ...ordered]..removeAt(index + 1);
  }

  /// Opens [projectId] and puts it at the top of the list. A search result.
  ///
  /// ⚠️ Reordering rather than scrolling, and on purpose. The tab renders a
  /// `ListView.builder`, so a project below the fold has no element at all and
  /// `Scrollable.ensureVisible` has nothing to aim at; scrolling to an unbuilt
  /// child needs either a fixed item extent or a package, and there is neither.
  /// Putting it first makes scrolling unnecessary, is deterministic, and is
  /// already what happens to a just-created project under the newest-first sort.
  void reveal(int projectId) {
    _openProjectId = projectId;
    _projects = _ordered(_projects);
    _notify();
  }

  /// Schedules the next read of the list, or stops.
  ///
  /// ⚠️ Only while something is actually running. A list that cannot change on
  /// its own is not worth a query a minute, and this controller is app-wide — it
  /// would go on asking while somebody is reading another tab.
  void _rearm() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;

    final anyRunning =
        _projects?.any((p) => ProjectState.of(p).isRunning) ?? false;
    if (!anyRunning) return;

    _timer = Timer(runningPollInterval, () {
      if (_disposed) return;
      refresh();
    });
  }

  /// Asks once whether mail is switched on, so the per-project notification
  /// switch can be hidden when it could not do anything.
  ///
  /// Staying false on failure is the safe direction: it costs a control, never a
  /// notification, because whether mail is actually sent is decided on the
  /// server's send path regardless of what this returned.
  Future<void> _refreshNotificationsAvailable() async {
    try {
      _notificationsAvailable = await _loadNotificationsAvailable();
      _notify();
    } catch (_) {
      // Deliberately not surfaced: the projects themselves loaded fine, and an
      // error banner about a switch would be noise.
    }
  }

  /// Loads the users a project can be handed to, for administrators only.
  ///
  /// Skipped entirely for everyone else rather than called and discarded: the
  /// endpoint refuses non-admins, so calling it would log a refusal on every
  /// ordinary page load.
  Future<void> _refreshAssignableOwners() async {
    if (!_isAdmin()) return;
    try {
      _assignableOwners = await _loadAssignableOwners();
      _notify();
    } catch (_) {
      // Leaves the picker out; the projects themselves are unaffected.
    }
  }

  /// Loads the groups this caller may use.
  ///
  /// ⚠️ Called for **everyone**, not only administrators, unlike
  /// [_refreshAssignableOwners]: the endpoint answers an ordinary user with
  /// their own groups, which is exactly what the picker offers them. It
  /// answers an empty list when no claim is configured, and an empty list is
  /// what hides the control.
  Future<void> _refreshAssignableDepartments() async {
    try {
      _assignableDepartments = await _loadAssignableDepartments();
      _notify();
    } catch (_) {
      // Leaves the picker out; the projects themselves are unaffected.
    }
  }

  void _onAuthChanged() {
    _refreshAssignableOwners();
    _refreshAssignableDepartments();
  }

  /// Hands [projectId] to [ownerId], or to nobody when null.
  Future<void> setOwner(int projectId, int? ownerId) async {
    try {
      await _setOwner(projectId, ownerId);
      await refresh();
    } catch (e) {
      _errorMessage = describeError(e);
      _notify();
    }
  }

  /// Moves [projectId] into [department], or out of every department with null.
  Future<void> setDepartment(int projectId, String? department) async {
    try {
      await _setDepartment(projectId, department);
      await refresh();
      // A project moving into a department the caller had not used before makes
      // that department offerable on every other tile.
      await _refreshAssignableDepartments();
    } catch (e) {
      _errorMessage = describeError(e);
      _notify();
    }
  }

  /// Deletes a project, taking its row off the list straight away.
  ///
  /// ⚠️ Optimistic on purpose. The server deletes the project's directory before
  /// it answers, which for a multi-gigabyte result is seconds — and waiting for
  /// that meant the row you had just deleted sat there looking untouched the
  /// whole time. It is put back if the server refuses.
  Future<void> delete(int projectId) async {
    final before = _projects;
    _errorMessage = null;
    _projects = _projects?.where((p) => p.id != projectId).toList();
    _notify();

    try {
      await _deleteProject(projectId);
      await refresh();
    } catch (e) {
      _projects = before;
      _errorMessage = describeError(e);
      _notify();
    }
  }

  /// Records that [created] should open on the next build.
  Future<void> projectCreated(Project created) async {
    _openProjectId = created.id;
    await refresh();
  }

  void dismissError() {
    _errorMessage = null;
    _notify();
  }

  /// ⚠️ Guarded, because every method here awaits at least one round trip and
  /// the tab can be disposed while one is in flight — notifying a disposed
  /// `ChangeNotifier` throws, and Flutter paints that over the whole tab.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }
}
