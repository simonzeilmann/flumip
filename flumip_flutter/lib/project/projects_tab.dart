import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'create_project_widget.dart';

class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  _ProjectsTabState createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project>? _projects;
  String? _errorMessage;
  bool _showCreateProject = false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
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
        _errorMessage = '$e';
      });
    }
  }

  void _deleteProject(int projectID) async {
    try {
      await client.project.deleteProject(projectID);
      _fetchProjects();
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
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
          const SizedBox(height: 30),
          if (_errorMessage != null)
            Container(
              color: Colors.red[300],
              padding: const EdgeInsets.all(8),
              child: Text(_errorMessage!),
            ),
          if (_projects != null)
            Expanded(
              child: ListView.builder(
                itemCount: _projects!.length,
                itemBuilder: (context, index) {
                  return ProjectTile(
                    project: _projects![index],
                    onDelete: () => _deleteProject(_projects![index].id!),
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