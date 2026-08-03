import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _fetchNotificationsAvailable();
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

  void _fetchProjects() async {
    try {
      final projects = await client.project.getProjects();
      setState(() {
        _errorMessage = null;
        _projects = projects..sort((a, b) => b.created.compareTo(a.created));
      });
    } catch (e) {
      setState(() {
        _errorMessage = describeError(e);
      });
    }
  }

  void _deleteProject(int projectID) async {
    try {
      await client.project.deleteProject(projectID);
      _fetchProjects();
    } catch (e) {
      setState(() {
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 10,
        children: [
          if (!_showCreateProject)
            Center(
              child: ElevatedButton(
                onPressed: _toggleCreateProject,
                child: const Text('Create Project'),
              ),
            ),
          if (_showCreateProject)
            CreateProjectWidget(
              onProjectCreated: _onProjectCreated,
              onAbort: _onAbort,
            ),
          if (_errorMessage != null)
            Container(
              color: Colors.red[300],
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage!),
            ),
          if (!_showCreateProject && _projects != null)
            Expanded(
              child: ListView.builder(
                itemCount: _projects!.length,
                itemBuilder: (context, index) {
                  return ProjectTile(
                    project: _projects![index],
                    onDelete: () => _deleteProject(_projects![index].id!),
                    notificationsAvailable: _notificationsAvailable,
                  );
                },
              ),
            ),
          if (_projects == null && _errorMessage == null)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
