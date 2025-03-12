import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/main.dart';
import 'package:flutter/services.dart';

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
  late ProjectOptions projectOptions = ProjectOptions();
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
      var projectUpdate = await client.project.getProject(widget.project.id!);
      final options =
          await client.options.getProjectOptions(widget.project.options);
      setState(() {
        widget.project = projectUpdate;
        projectOptions = options;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reload project: $e';
      });
    }
  }

  Future<void> _addGene(String gene) async {
    try {
      await client.project.addGeneToProject(widget.project.id!, gene);
      await _reloadProject();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add gene: $e')),
        );
      }
    }
  }

  Future<void> _removeGene(String gene) async {
    try {
      await client.project.removeGeneFromProject(widget.project.id!, gene);
      await _reloadProject();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove gene: $e')),
        );
      }
    }
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
    } on ArgumentError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR: The supplied genes cannot be found')),
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
                if (result.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                              ClipboardData(text: result.join('\n')))
                          .then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("MIPs copied to clipboard")));
                        }
                      });
                    },
                    child: Text('Copy to clipboard'),
                  ),
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
              title: Text('SNP MIPs Result'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: result.isEmpty
                      ? [Text('No SNP MIPs result file found.')]
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
                if (result.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                              ClipboardData(text: result.join('\n')))
                          .then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Snp MIPs copied to clipboard")));
                        }
                      });
                    },
                    child: Text('Copy to clipboard'),
                  ),
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
          SnackBar(content: Text('Failed to load SNP MIPs result: $e')),
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

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
            subtitle: Text(widget.project.description),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: _showDeleteConfirmationDialog,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        if (widget.project.genes != null &&
                            widget.project.genes!.isNotEmpty)
                          buildGeneColumn(),
                        if (widget.project.bedFileCreated == false)
                          buildAddGeneRow(),
                      ],
                    ),
                  ),
                  Expanded(
                      child: Row(
                    children: [
                      Expanded(
                        child: buildProjectOptionsColumn(),
                      ),
                    ],
                  )),
                  SizedBox(height: 5),
                  if (widget.project.genes?.isNotEmpty == true &&
                      widget.project.bedFileCreated == false)
                    Center(
                      child: ElevatedButton(
                        onPressed: _createBedFile,
                        child: Text('Create BED File'),
                      ),
                    ),
                  SizedBox(height: 5),
                  if (widget.project.bedFileCreated == true &&
                      widget.project.active == false &&
                      widget.project.completedIn == null)
                    Center(
                      child: buildMipgenStartColumn(),
                    ),
                  SizedBox(height: 5),
                  if (widget.project.active == true &&
                      widget.project.completedIn == null)
                    Center(
                      child: buildMipgenProgressColumn(),
                    ),
                  if (widget.project.active == false &&
                      widget.project.completedIn != null)
                    Center(
                      child: buildMipgenResultColumn(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Column buildProjectOptionsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text('Min Capture Size: ${projectOptions.minCaptureSize}'),
        Text('Max Capture Size: ${projectOptions.maxCaptureSize}'),
        if (projectOptions.armLengths != null)
          Text('Arm Lengths: ${projectOptions.armLengths}'),
        Text('Arm Length Sums: ${projectOptions.armLengthSums}'),
        Text('Ext Min Length: ${projectOptions.extMinLength}'),
        Text('Ext Max Length: ${projectOptions.extMaxLength}'),
        Text('Lig Min Length: ${projectOptions.ligMinLength}'),
        Text('Tag Sizes: ${projectOptions.tagSizes}'),
        Text('Masked Arm Threshold: ${projectOptions.maskedArmThreshold}'),
        Text('Target Arm Copy: ${projectOptions.targetArmCopy}'),
        Text('Max Arm Copy Product: ${projectOptions.maxArmCopyProduct}'),
        if (projectOptions.trf) Text('TRF: on') else Text('TRF: off'),
        if (projectOptions.genomeDir != null)
          Text('Genome Dir: ${projectOptions.genomeDir}'),
        Text('Feature Flank: ${projectOptions.featureFlank}'),
        Text('Capture Increment: ${projectOptions.captureIncrement}'),
        if (projectOptions.logisticHeuristic)
          Text('Logistic Heuristic: on')
        else
          Text('Logistic Heuristic: off'),
        Text('Max Mip Overlap: ${projectOptions.maxMipOverlap}'),
        Text('Starting Mip Overlap: ${projectOptions.startingMipOverlap}'),
        if (projectOptions.checkCopyNumber)
          Text('Check Copy Number: on')
        else
          Text('Check Copy Number: off'),
        if (projectOptions.sealBothStrands)
          Text('Seal Both Strands: on')
        else
          Text('Seal Both Strands: off'),
        if (projectOptions.halfSealBothStrands)
          Text('Half Seal Both Strands: on')
        else
          Text('Half Seal Both Strands: off'),
        if (projectOptions.doubleTileStrandUnaware)
          Text('Double Tile Strand Unaware: on')
        else
          Text('Double Tile Strand Unaware: off'),
        if (projectOptions.doubleTileStrandsSeparately)
          Text('Double Tile Strands Separately: on')
        else
          Text('Double Tile Strands Separately: off'),
        Text('Score Method: ${projectOptions.scoreMethod}'),
        Text('Logistic Optimal Score: ${projectOptions.logisticOptimalScore}'),
        Text('SVR Optimal Score: ${projectOptions.svrOptimalScore}'),
        Text(
            'Logistic Priority Score: ${projectOptions.logisticPriorityScore}'),
        Text('SVR Priority Score: ${projectOptions.svrPriorityScore}'),
        SizedBox(height: 5),
      ],
    );
  }

  Column buildGeneColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Genes:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        ...widget.project.genes!.map(
          (gene) => Row(
            children: [
              Center(
                child: Text(
                  gene,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              if (widget.project.bedFileCreated == false)
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeGene(gene),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Row buildAddGeneRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _genesController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'add gene',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            ),
            keyboardType: TextInputType.text,
            onSubmitted: (value) {
              _addGene(value);
              _genesController.clear();
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () {
            _addGene(_genesController.text);
            _genesController.clear();
          },
        ),
      ],
    );
  }

  Column buildMipgenStartColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Checkbox(
              value: _deleteExcessFiles,
              onChanged: (bool? value) {
                setState(() {
                  _deleteExcessFiles = value ?? false;
                });
              },
            ),
            Text('Auto delete excess files'),
          ],
        ),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _generateMips,
          child: Text('Generate MIPs'),
        ),
      ],
    );
  }

  Column buildMipgenProgressColumn() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _showProgress,
          child: Text('Show Progress'),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Column buildMipgenResultColumn() {
    return Column(
      children: [
        Text('Completed in: ${_printDuration(widget.project.completedIn!)}'),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _showMipsResult,
          child: Text('Show MIPs Result'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _showSnpMipsResult,
          child: Text('Show SNP MIPs Result'),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
