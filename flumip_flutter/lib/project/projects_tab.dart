import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flutter/material.dart';

import '../ui/layout.dart';
import '../ui/error_banner.dart';

import '../main.dart';
import 'create_project_widget.dart';
import '../error_text.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project>? _projects;
  String? _errorMessage;
  bool _showCreateProject = false;
  bool _notificationsAvailable = false;
  List<FlumipUserDto>? _assignableOwners;

  /// Whether the signed-in user may reassign ownership.
  ///
  /// Null while signed out, which is every request on a no-auth install — and
  /// there the server refuses reassignment outright, so the controls stay hidden
  /// exactly where they would not work.
  bool get _isAdmin => authController.user?.isAdmin ?? false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _fetchNotificationsAvailable();
    _fetchAssignableOwners();
  }

  /// Asks once whether an administrator has mail switched on, so the per-project
  /// notification checkbox can be hidden when it could not do anything.
  ///
  /// Asked here rather than in each tile so one answer serves the whole list.
  /// Staying false on failure is the safe direction: it costs a control, never a
  /// notification, because whether mail is actually sent is decided on the
  /// server's send path regardless of what this returned.
  void _fetchNotificationsAvailable() async {
    try {
      final available = await client.project.notificationsAvailable();
      if (!mounted) return;
      setState(() {
        _notificationsAvailable = available;
      });
    } catch (_) {
      // Deliberately not surfaced: the projects themselves loaded fine, and an
      // error banner about a checkbox would be noise.
    }
  }

  /// Loads the users a project can be handed to, for administrators only.
  ///
  /// Skipped entirely for everyone else rather than called and discarded: the
  /// endpoint refuses non-admins, so calling it would log a refusal on every
  /// ordinary page load. Fetched once for the whole list, like the mail flag.
  void _fetchAssignableOwners() async {
    if (!_isAdmin) return;
    try {
      final owners = await client.project.assignableOwners();
      if (!mounted) return;
      setState(() {
        _assignableOwners = owners;
      });
    } catch (_) {
      // Leaves the picker out; the projects themselves are unaffected.
    }
  }

  /// Hands [projectID] to [ownerId], or to nobody when null.
  Future<void> _setProjectOwner(int projectID, int? ownerId) async {
    try {
      await client.project.setProjectOwner(projectID, ownerId);
      _fetchProjects();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = describeError(e);
      });
    }
  }

  void _fetchProjects() async {
    try {
      final projects = await client.project.getProjects();
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        _projects = projects..sort((a, b) => b.created.compareTo(a.created));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = describeError(e);
      });
    }
  }

  /// Deletes a project, taking its row off the list straight away.
  ///
  /// ⚠️ Optimistic on purpose. The server deletes the project's directory before
  /// it answers, which for a multi-gigabyte result is seconds — and the old code
  /// waited for that before refetching, so the row you had just deleted sat
  /// there looking untouched the whole time. It is put back if the server
  /// refuses.
  void _deleteProject(int projectID) async {
    final before = _projects;
    setState(() {
      _errorMessage = null;
      _projects = _projects?.where((p) => p.id != projectID).toList();
    });

    try {
      await client.project.deleteProject(projectID);
      _fetchProjects();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projects = before;
        _errorMessage = describeError(e);
      });
    }
  }

  void _toggleCreateProject() {
    setState(() {
      _showCreateProject = !_showCreateProject;
    });
  }

  void _onProjectCreated() {
    _fetchProjects();
    _toggleCreateProject();
  }

  void _onAbort() {
    _toggleCreateProject();
  }

  @override
  Widget build(BuildContext context) {
    // The create form replaces the list rather than sitting above it, and it is
    // given the full width so its own pinned action bar can span the window the
    // way the settings one does. It caps its fields itself.
    if (_showCreateProject) {
      return CreateProjectWidget(
        onProjectCreated: _onProjectCreated,
        onAbort: _onAbort,
      );
    }

    return ContentWidth(
      padding: const EdgeInsets.all(16),
      child: Column(
        // ⚠️ ContentWidth gives a tight width, but a Column still centres its
        // children on the cross axis by default — which would leave the error
        // banner shrink-wrapped to its text in the middle of a 1400px band.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Center(
            child: FilledButton.icon(
              onPressed: _toggleCreateProject,
              icon: const Icon(Icons.add),
              label: const Text('Create project'),
            ),
          ),
          if (_errorMessage != null)
            ErrorBanner(
              _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          if (_projects != null)
            Expanded(
              child: ListView.builder(
                itemCount: _projects!.length,
                itemBuilder: (context, index) {
                  final project = _projects![index];
                  return ProjectTile(
                    // ⚠️ Keyed on the project id, and this is load-bearing.
                    // Without a key Flutter matches children by position, so
                    // deleting one project hands its `State` — its expanded
                    // flag, its ten-second poll, its loaded genome and SNP, and
                    // the mutable `widget.project` it writes back into — to
                    // whichever project shuffles up into that slot. That is the
                    // "zombie" row: a tile showing one project's details under
                    // another project's name.
                    key: ValueKey(project.id),
                    project: project,
                    onDelete: () => _deleteProject(project.id!),
                    notificationsAvailable: _notificationsAvailable,
                    assignableOwners: _assignableOwners,
                    onOwnerChanged: (ownerId) =>
                        _setProjectOwner(project.id!, ownerId),
                  );
                },
              ),
            ),
          // Centred explicitly: under `stretch` it would otherwise be handed
          // the full band width and draw its spinner against the left edge.
          if (_projects == null && _errorMessage == null)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
