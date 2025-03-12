import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'project_tile.dart';
import 'create_project_widget.dart';

var client = Client('http://$localhost:8080/')
  ..connectivityMonitor = FlutterConnectivityMonitor();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flumip Development',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Mipgen'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _toggleCreateProject,
                  child: Text(_showCreateProject ? 'Cancel' : 'Create Project'),
                ),
              ],
            ),
            if (_showCreateProject)
              CreateProjectWidget(
                onProjectCreated: _onProjectCreated,
                onAbort: _onAbort,
              ),
            SizedBox(height: 30),
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
                      onCreateGeneFile: (genes) => client.project
                          .addGenesToProject(_projects![index].id!, genes),
                    );
                  },
                ),
              ),
            if (_projects == null && _errorMessage == null)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}