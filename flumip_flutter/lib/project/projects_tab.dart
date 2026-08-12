import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/error_banner.dart';
import '../ui/layout.dart';
import 'create_project_widget.dart';
import 'project_tile.dart';
import 'projects_controller.dart';

/// The projects list.
///
/// Everything that fetches or changes anything lives in [ProjectsController],
/// which takes its I/O as parameters — so this file is layout, and the tab can be
/// pumped in a test by handing it a controller built from fakes.
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key, this.controller});

  /// The controller to use, or null to take the app-wide one.
  ///
  /// ⚠️ A test passes its own; nothing else should. The default is resolved in
  /// [State.initState] rather than here, because `services.dart`'s controller is
  /// `late` and reading it in a `const` constructor's default would run before
  /// `main()` has installed it.
  final ProjectsController? controller;

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  late final ProjectsController _controller =
      widget.controller ?? projectsController;

  bool _showCreateProject = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    // ⚠️ Never disposed here. The app-wide controller outlives this tab —
    // `TabBarView` can rebuild it — and a test owns the one it passed in.
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _toggleCreateProject() {
    setState(() => _showCreateProject = !_showCreateProject);
  }

  void _onProjectCreated(Project created) {
    _controller.projectCreated(created);
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
        onAbort: _toggleCreateProject,
      );
    }

    final projects = _controller.projects;
    final error = _controller.errorMessage;

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
          if (error != null)
            ErrorBanner(
              error,
              // ⚠️ Dismissible only when there is a list behind it. `ErrorBanner`
              // says it in its own doc — "one that explains why a screen is
              // empty has to stay, or the screen is just empty" — and here the
              // consequence is worse than empty: `loading` is "no projects and
              // no error", so dismissing the *only* thing on a failed first load
              // put the tab back into a spinner that never stops, with nothing
              // left to say why.
              onDismiss: projects == null ? null : _controller.dismissError,
            ),
          if (projects != null)
            Expanded(
              child: ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ProjectTile(
                    // ⚠️ Keyed on the project id, and this is load-bearing.
                    // Without a key Flutter matches children by position, so
                    // deleting one project hands its `State` — its expanded
                    // flag, its poll, its loaded genome and SNP, and the mutable
                    // `widget.project` it writes back into — to whichever
                    // project shuffles up into that slot. That is the "zombie"
                    // row: a tile showing one project's details under another
                    // project's name.
                    key: ValueKey(project.id),
                    project: project,
                    // A project created a moment ago opens straight away — there
                    // is nothing in it yet, and setting it up is the only reason
                    // it exists.
                    initiallyExpanded: project.id == _controller.openProjectId,
                    onDelete: () => _controller.delete(project.id!),
                    notificationsAvailable: _controller.notificationsAvailable,
                    assignableOwners: _controller.assignableOwners,
                    onOwnerChanged: (ownerId) =>
                        _controller.setOwner(project.id!, ownerId),
                  );
                },
              ),
            ),
          // Centred explicitly: under `stretch` it would otherwise be handed the
          // full band width and draw its spinner against the left edge.
          if (_controller.loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
