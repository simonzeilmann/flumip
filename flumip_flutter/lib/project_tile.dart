import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/main.dart';

class ProjectTile extends StatefulWidget {
  final String projectName;
  final VoidCallback onDelete;
  final Future<void> Function(List<String>) onCreateGeneFile;

  const ProjectTile({
    super.key,
    required this.projectName,
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
  List<String>? _genes;
  String? _errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkBedFileExists();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkBedFileExists();
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
      await _fetchGenes();
    }
  }

  Future<void> _fetchGenes() async {
    try {
      final genes = await client.mipgen.getGenes(widget.projectName);
      setState(() {
        if (genes.isEmpty) {
          _errorMessage = 'No genes found for this project.';
          _genes = null;
        } else {
          _genes = genes;
          _errorMessage = null;
        }
      });
    } on Exception {
      setState(() {
        _errorMessage = 'No genes file exists for this project.';
        _genes = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load genes: $e';
      });
    }
  }

  Future<void> _createGeneFile() async {
    if (_genesController.text.isEmpty) return;
    List<String> genes = _genesController.text.split(',');
    await widget.onCreateGeneFile(genes);
    _genesController.clear();
    await _fetchGenes();
  }

  Future<void> _createBedFile() async {
    try {
      await client.mipgen.createBedFile(widget.projectName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('BED file created successfully')),
        );
      }
      await _checkBedFileExists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create BED file: $e')),
        );
      }
    }
  }

  Future<void> _checkBedFileExists() async {
    /*
    try {
      bool exists = await client.mipgen.checkBedFileExists(widget.projectName);
      setState(() {
        //_bedFileExists = exists;
      });
    } catch (e) {
      setState(() {
        //_bedFileExists = false;
      });
    }
     */
  }

  Future<void> _generateMips() async {
    try {
      await client.mipgen.generateMips(widget.projectName, _deleteExcessFiles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MIPs generated successfully')),
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
      final result = await client.mipgen.showMipsResult(widget.projectName);
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
          SnackBar(content: Text('Failed to load MIPs result: $e')),
        );
      }
    }
  }

  Future<void> _showProgress() async {
    try {
      final result = await client.mipgen.showMipsProgress(widget.projectName);
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
            title: Text(widget.projectName),
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
                  if (_genes != null)
                    Column(
                      children: _genes!.map((gene) => Text(gene)).toList(),
                    ),
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
                  ElevatedButton(
                    onPressed: _createBedFile,
                    child: Text('Create BED File'),
                  ),
                  SizedBox(height: 5),
                  //if (_bedFileExists)
                  SizedBox(height: 5),
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
