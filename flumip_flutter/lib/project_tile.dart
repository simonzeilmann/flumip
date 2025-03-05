import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/main.dart';

//ignore: must_be_immutable
class ProjectTile extends StatefulWidget {
  Project project;
  final VoidCallback onDelete;
  final Future<void> Function(List<String>) onCreateGeneFile;

  ProjectTile({
    super.key,
    required this.project,
    required this.onDelete,
    required this.onCreateGeneFile,
  });

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  bool _isExpanded = false;
  bool _deleteExcessFiles = false;
  final TextEditingController _genesController = TextEditingController();
  String? _errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isExpanded) {
        _reloadProject();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleExpand() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      await _reloadProject();
    }
  }

  Future<void> _reloadProject() async {
    try {
      final project = await client.project.getProject(widget.project.id!);
      setState(() {
        widget.project = project;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reload project: $e';
      });
    }
  }

  Future<void> _createGeneFile() async {
    if (_genesController.text.isEmpty) return;
    List<String> genes = _genesController.text.split(',');
    await widget.onCreateGeneFile(genes);
    _genesController.clear();
    await _reloadProject();
  }

  Future<void> _createBedFile() async {
    try {
      await client.mipgen.createBedFile(widget.project.id!);
      await _reloadProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BED file created successfully')),
        );
      }
    } on IOException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: The genes.txt file does not exist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create BED file: $e')),
        );
      }
    }
  }

  Future<void> _generateMips() async {
    try {
      await client.mipgen.generateMips(widget.project.id!, _deleteExcessFiles);
      _reloadProject();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MIPs generation started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate MIPs: $e')),
        );
      }
    }
  }

  Future<void> _showMipsResult() async {
    try {
      final result = await client.file.showMipsResult(widget.project.id!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('MIPs Result'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: result.isEmpty
                      ? [Text('No MIPs result file found.')]
                      : [
                    SelectableText.rich(
                      TextSpan(
                        children: result
                            .map((line) => TextSpan(text: '$line\n'))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load MIPs result: $e')),
        );
      }
    }
  }

  Future<void> _showSnpMipsResult() async {
    try {
      final result = await client.file.showSnpMipsResult(widget.project.id!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('MIPs Result'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: result.isEmpty
                      ? [Text('No MIPs result file found.')]
                      : [
                    SelectableText.rich(
                      TextSpan(
                        children: result
                            .map((line) => TextSpan(text: '$line\n'))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load MIPs result: $e')),
        );
      }
    }
  }

  Future<void> _showProgress() async {
    try {
      final result = await client.file.showMipsProgress(widget.project.id!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('MIPs Progress'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: result.isEmpty
                      ? [Text('No progress file found.')]
                      : result.map((line) => Text(line)).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load progress: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Project'),
          content: Text('Are you sure you want to delete this project?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                widget.onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: IconButton(
              icon: Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              onPressed: _toggleExpand,
            ),
            title: Text(widget.project.name),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: _showDeleteConfirmationDialog,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  if (widget.project.genes != null &&
                      widget.project.genes!.isNotEmpty)
                    Column(
                      children: widget.project.genes!
                          .map((gene) => Text(
                                gene,
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ))
                          .toList(),
                    ),
                  if (widget.project.geneFileCreated == false)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _genesController,
                            decoration: InputDecoration(
                              labelText: 'Genes (comma separated)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _createGeneFile,
                        ),
                      ],
                    ),
                  SizedBox(height: 5),
                  if (widget.project.geneFileCreated == true &&
                      widget.project.bedFileCreated == false)
                    ElevatedButton(
                      onPressed: _createBedFile,
                      child: Text('Create BED File'),
                    ),
                  SizedBox(height: 5),
                  //if (_bedFileExists)
                  SizedBox(height: 5),
                  if (widget.project.bedFileCreated == true &&
                      widget.project.active == false)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _deleteExcessFiles,
                          onChanged: (bool? value) {
                            setState(() {
                              _deleteExcessFiles = value ?? false;
                            });
                          },
                        ),
                        Text('Delete excess files'),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _generateMips,
                          child: Text('Generate MIPs'),
                        ),
                      ],
                    ),
                  SizedBox(height: 5),
                  //TODO: plit and only show result if project is finished
                  if (widget.project.active == true)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: _showProgress,
                          child: Text('Show Progress'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _showMipsResult,
                          child: Text('Show MIPs Result'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _showSnpMipsResult,
                          child: Text('Show SNP MIPs Result'),
                        ),
                      ],
                    ),
                  SizedBox(height: 5),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
