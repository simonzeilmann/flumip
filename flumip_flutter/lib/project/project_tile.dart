import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/main.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Truple {
  final String name;
  int start;
  int end;

  Truple(this.name, this.start, this.end);
}

//ignore: must_be_immutable
class ProjectTile extends StatefulWidget {
  Project project;
  final VoidCallback onDelete;

  ProjectTile({
    super.key,
    required this.project,
    required this.onDelete,
  });

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  bool _isExpanded = false;
  bool _deleteExcessFiles = false;
  late ProjectOptions projectOptions = ProjectOptions();
  late Genome genome = Genome(name: 'default');
  late Snp snp =
      Snp(name: 'default', vcfPath: '', tbiPath: '', folder: '', active: false);
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
      genome = Genome(name: 'default');
      snp = Snp(
          name: 'default', vcfPath: '', tbiPath: '', folder: '', active: false);
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
      Genome? genomeUpdate;
      if (widget.project.genome != null) {
        genomeUpdate = await client.genome.getGenome(widget.project.genome!);
      }
      Snp? snpUpdate;
      if (widget.project.snp != null) {
        snpUpdate = await client.genome.getSnp(widget.project.snp!);
      }
      setState(() {
        widget.project = projectUpdate;
        projectOptions = options;
        if (genomeUpdate != null) {
          genome = genomeUpdate;
        }
        if (snpUpdate != null) {
          snp = snpUpdate;
        }
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

  List<Truple> _getGenomeRanges(List<String> ucscTrack) {
    Set<String> uniqueNames = {};
    for (var line in ucscTrack) {
      if (line.startsWith('chr')) {
        var parts = line.split('\t');
        if (parts.length >= 3) {
          var name = parts[0];
          uniqueNames.add(name);
        }
      }
    }
    List<Truple> ranges = [];
    for (var name in uniqueNames) {
      var result = Truple(name, 0x20000000000000, 0);
      for (var line in ucscTrack) {
        if (line.startsWith(name)) {
          var parts = line.split('\t');
          if (parts.length >= 3) {
            var start = int.parse(parts[1]);
            var end = int.parse(parts[2]);
            if (result.start > start) {
              result.start = start;
            }
            if (result.end < end) {
              result.end = end;
            }
          }
        }
      }
      ranges.add(result);
    }

    return ranges;
  }

  Map<String, String> _generateUCSCTrackUrl(List<String> track) {
    String url = 'https://genome.ucsc.edu/cgi-bin/hgTracks?';
    switch (genome.name) {
      case 'hg18':
        url += 'db=hg18';
        break;
      case 'hg19':
        url += 'db=hg19';
        break;
      case 'hs1':
        url += 'db=hs1';
        break;
      default:
        url += 'db=hg38';
        break;
    }

    var map = <String, String>{};

    var genomeRanges = _getGenomeRanges(track);
    for (var range in genomeRanges) {
      map[range.name] = url +=
          '&position=${range.name}:${range.start}-${range.end} &hgt.customText=http://localhost:8082/ucsc_track/${widget.project.id}';
    }

    return map;
  }

  Future<void> _showUSCSTrack() async {
    try {
      final result = await client.file.showUSCSTrack(widget.project.id!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('UCSC Track'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: result.isEmpty
                      ? [Text('No USCS Track file found.')]
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
                      var ucscTrack = _generateUCSCTrackUrl(result);
                      if (ucscTrack.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("No UCSC Track found")));
                        return;
                      }
                      if (ucscTrack.length == 1) {
                        web.window.open(ucscTrack.values.first, 'new tab');
                      } else {
                        if (mounted) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Select UCSC Track'),
                                  content: SingleChildScrollView(
                                    child: ListBody(
                                      children: ucscTrack.entries
                                          .map((entry) => TextButton(
                                                onPressed: () {
                                                  web.window.open(
                                                      entry.value, 'new tab');
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(entry.key),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                );
                              });
                        }
                      }
                    },
                    child: Text('Open in UCSC Track browser'),
                  ),
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

  Future<List<String>> getGenomeCategories() async {
    try {
      var cat = await client.genome.getCategories();
      cat.sort((a, b) => a.compareTo(b));
      return cat;
    } catch (e) {
      _errorMessage = 'Failed to load gene categories: $e';
      return [];
    }
  }

  Future<List<Genome>> getGenomeByCategory(String category) async {
    try {
      return await client.genome.getGenomeByCategory(category);
    } catch (e) {
      _errorMessage = 'Failed to load genes for category: $e';
      return [];
    }
  }

  Future<List<Snp>> getSnpForGene(int geneId) async {
    try {
      return await client.genome.getAllSnpForGenome(geneId);
    } catch (e) {
      _errorMessage = 'Failed to load snps for genome: $e';
      return [];
    }
  }

  Future<void> setGenome(int geneId) async {
    try {
      await client.project.setGeneById(widget.project.id!, geneId);
      await _reloadProject();
    } catch (e) {
      _errorMessage = 'Failed to set genome: $e';
    }
  }

  Future<void> setSnp(int snpId) async {
    try {
      await client.project.setSnpById(widget.project.id!, snpId);
      await _reloadProject();
    } catch (e) {
      _errorMessage = 'Failed to set snp: $e';
    }
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  double _truncateToDecimalPlaces(num value, int fractionalDigits) =>
      (value * pow(10, fractionalDigits)).truncate() /
      pow(10, fractionalDigits);

  @override
  Widget build(BuildContext context) {
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 670;
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
            trailing: Wrap(
              spacing: 12,
              children: <Widget>[
                Text(DateFormat("dd.MM.yyyy").format(widget.project.created)),
                Text(
                    '${_truncateToDecimalPlaces(widget.project.size / 1000000000, 2)} GB'),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _showDeleteConfirmationDialog,
                ),
              ],
            ),
          ),
          if (_isExpanded)
            if (isScreenWide) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: buildGenomeSelectorColumn(),
                    ),
                    Expanded(
                      child: buildProjectOptionsColumn(),
                    ),
                    Expanded(child: buildProjectActionColumn())
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  spacing: 10,
                  children: [
                    buildGenomeSelectorColumn(),
                    buildProjectOptionsColumn(),
                    buildProjectActionColumn()
                  ],
                ),
              ),
            ]
        ],
      ),
    );
  }

  Column buildProjectActionColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (widget.project.active == true && widget.project.completedIn == null)
          Center(
            child: buildMipgenProgressColumn(),
          ),
        if (widget.project.active == false &&
            widget.project.completedIn != null &&
            widget.project.error.isEmpty)
          Center(
            child: buildMipgenResultColumn(),
          ),
        if (widget.project.active == false &&
            widget.project.completedIn != null &&
            widget.project.error.isNotEmpty)
          Center(
            child: Text(
              'Error: ${widget.project.error}',
              style: TextStyle(color: Colors.red),
            ),
          )
      ],
    );
  }

  Column buildGenomeSelectorColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null)
          Center(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (widget.project.genome == null)
          Center(
            child: buildGenomeSelector(),
          ),
        if (widget.project.genome != null) ...[
          Center(
              child: Text('Genome:',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          if (genome.name == 'default') ...[
            Center(child: Text('loading...')),
          ] else ...[
            Center(
              child: Text(genome.name),
            )
          ],
          SizedBox(height: 10),
        ],
        if (widget.project.genome != null &&
            genome.snp != null &&
            widget.project.snp == null &&
            !widget.project.active &&
            widget.project.completedIn == null)
          Center(
            child: buildSnpSelector(),
          ),
        if (widget.project.snp != null) ...[
          Center(
            child: Text('Snp:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (snp.name == 'default') ...[
            Center(child: Text('loading...')),
          ] else ...[
            Center(child: Text(snp.name)),
          ]
        ],
        SizedBox(height: 30),
        if (widget.project.genes != null && widget.project.genes!.isNotEmpty)
          Center(
            child: buildGeneColumn(),
          ),
        if (widget.project.bedFileCreated == false)
          Center(
            child: buildAddGeneColumn(),
          )
      ],
    );
  }

  Column buildGenomeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Category:"),
        FutureBuilder<List<String>>(
          future: getGenomeCategories(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.isNotEmpty) {
                return DropdownButton<String>(
                  value: null,
                  onChanged: (String? category) {
                    if (category != null) {
                      getGenomeByCategory(category).then((genomes) {
                        if (context.mounted) {
                          genomes.sort((a, b) => a.name.compareTo(b.name));
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Select Genome:'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var selectedGenome in genomes)
                                      if (selectedGenome.active) ...[
                                        if (selectedGenome.indexed) ...[
                                          ListTile(
                                            title: Text(selectedGenome.name),
                                            onTap: () {
                                              genome = selectedGenome;
                                              setGenome(selectedGenome.id!);
                                              _reloadProject();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ] else if (selectedGenome.indexing) ...[
                                          ListTile(
                                            title: Text(
                                                "${selectedGenome.name} (indexing)"),
                                            subtitle: Text(
                                                "Genome is currently unavailable"),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ] else ...[
                                          ListTile(
                                            title: Text(
                                                "${selectedGenome.name} (not indexed)"),
                                            onTap: () {
                                              genome = selectedGenome;
                                              setGenome(selectedGenome.id!);
                                              _reloadProject();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ]
                                      ]
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      });
                    } else {
                      Text("No genomes available");
                    }
                  },
                  items: snapshot.data!
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                );
              } else {
                return Text("No categories available");
              }
            } else if (snapshot.hasError) {
              return Text('Failed to load gene categories: ${snapshot.error}');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ],
    );
  }

  Column buildSnpSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select SNP (optional):"),
        FutureBuilder<List<Snp>>(
          future: getSnpForGene(genome.id!),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return DropdownButton<Snp>(
                value: null,
                onChanged: (Snp? selectedSnp) {
                  if (selectedSnp != null) {
                    snp = selectedSnp;
                    setSnp(selectedSnp.id!);
                    _reloadProject();
                  }
                },
                items: snapshot.data!
                    .map((snp) => DropdownMenuItem(
                          value: snp,
                          child: Text(snp.name),
                        ))
                    .toList(),
              );
            } else if (snapshot.hasError) {
              return Text('Failed to load snps: ${snapshot.error}');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ],
    );
  }

  Column buildProjectOptionsColumn() {
    return Column(
      spacing: 3,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text('Min Capture Size: ${projectOptions.minCaptureSize}'),
        Text('Max Capture Size: ${projectOptions.maxCaptureSize}'),
        if (projectOptions.armLengths != null &&
            projectOptions.armLengths!.isNotEmpty)
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
      children: [
        Text('Genes:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Column(
          children: widget.project.genes!.map((gene) {
            return Row(
              children: [
                Text(
                  gene,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                if (widget.project.bedFileCreated == false)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline),
                    onPressed: () => _removeGene(gene),
                  ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Column buildAddGeneColumn() {
    return Column(
      children: [
        SizedBox(height: 15),
        Row(
          spacing: 10,
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
        )
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
            Text('Auto delete intermediate files'),
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
        Text(
            'Output size: ${_truncateToDecimalPlaces(widget.project.size / 1000000000, 2)} GB'),
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
        ElevatedButton(
            onPressed: _showUSCSTrack, child: Text('Show UCSC Track')),
        SizedBox(height: 10),
      ],
    );
  }
}
