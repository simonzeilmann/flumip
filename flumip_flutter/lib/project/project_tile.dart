import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/api_config.dart';
import 'package:flumip_flutter/main.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../error_text.dart';

final String siteUrl = resolveSiteUrl();

class GenomeRange {
  final String name;
  int start;
  int end;

  GenomeRange(this.name, this.start, this.end);
}

//ignore: must_be_immutable
class ProjectTile extends StatefulWidget {
  Project project;
  final VoidCallback onDelete;

  ProjectTile({super.key, required this.project, required this.onDelete});

  @override
  State<ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<ProjectTile> {
  bool _isExpanded = false;
  bool _deleteExcessFiles = false;
  late ProjectOptions projectOptions = ProjectOptions();
  late Genome genome = Genome(name: 'default');
  late Snp snp = Snp(
    name: 'default',
    vcfPath: '',
    tbiPath: '',
    folder: '',
    active: false,
  );
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
        name: 'default',
        vcfPath: '',
        tbiPath: '',
        folder: '',
        active: false,
      );
    });
    if (_isExpanded) {
      await _reloadProject();
    }
  }

  Future<void> _reloadProject() async {
    try {
      var projectUpdate = await client.project.getProject(widget.project.id!);
      final options = await client.options.getProjectOptions(
        widget.project.options,
      );
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
      // Stop the ten-second poll when the answer will not change. Without this,
      // a project that has stopped being ours mid-session — revoked session,
      // ownership reassigned — re-reports the same refusal every ten seconds for
      // as long as the tile stays expanded.
      if (isAccessDenied(e)) {
        _timer?.cancel();
        _timer = null;
      }
      setState(() {
        _errorMessage = 'Failed to reload project: ${describeError(e)}';
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
          SnackBar(content: Text('Failed to add gene: ${describeError(e)}')),
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
          SnackBar(content: Text('Failed to remove gene: ${describeError(e)}')),
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
    } on BedCreationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create BED file: ${describeError(e)}'),
          ),
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
    } on FlumipFileNotFoundException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on ArgumentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate MIPs: ${describeError(e)}'),
          ),
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
                        ClipboardData(text: result.join('\n')),
                      ).then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("MIPs copied to clipboard")),
                          );
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
          SnackBar(
            content: Text('Failed to load MIPs result: ${describeError(e)}'),
          ),
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
                        ClipboardData(text: result.join('\n')),
                      ).then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Snp MIPs copied to clipboard"),
                            ),
                          );
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
          SnackBar(
            content: Text(
              'Failed to load SNP MIPs result: ${describeError(e)}',
            ),
          ),
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
          SnackBar(
            content: Text('Failed to load progress: ${describeError(e)}'),
          ),
        );
      }
    }
  }

  List<GenomeRange> _getGenomeRanges(List<String> ucscTrack) {
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
    List<GenomeRange> ranges = [];
    for (var name in uniqueNames) {
      var result = GenomeRange(name, 0x20000000000000, 0);
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

  /// Builds one UCSC Genome Browser URL per genome range in [track].
  ///
  /// [trackToken] keys the public `/ucsc_track/<token>` URL that UCSC will fetch.
  /// It used to be `widget.project.id`, which made every project's track readable
  /// and enumerable by anyone who could reach the port; the token comes from
  /// `client.file.getUcscTrackToken`, which checks access before releasing it.
  Map<String, String> _generateUCSCTrackUrl(
    List<String> track,
    String trackToken,
  ) {
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
      // `url +` and not `url +=`. This was `+=`, which mutated the shared base on
      // every iteration, so with two ranges the second URL carried the first
      // range's `&position=` as well and UCSC was handed two conflicting
      // positions. Only projects with more than one range were affected, which is
      // presumably why it went unnoticed. Corrected here because this line is
      // being rewritten anyway; it is not part of the authorization change.
      map[range.name] =
          '$url&position=${range.name}:${range.start}-${range.end} '
          '&hgt.customText=$siteUrl/ucsc_track/$trackToken';
    }

    return map;
  }

  Future<void> _showUCSCTrack() async {
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
                      ? [Text('No UCSC Track file found.')]
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
                      // Fetched here rather than with the track itself so the
                      // token is only ever minted when somebody actually opens
                      // UCSC.
                      final String trackToken;
                      try {
                        trackToken = await client.file.getUcscTrackToken(
                          widget.project.id!,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not build the UCSC track link: '
                                '${describeError(e)}',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      // `context` here belongs to the dialog builder, not to the
                      // State, so State.mounted says nothing about it — hence
                      // context.mounted rather than the mounted check used
                      // elsewhere in this file.
                      if (!context.mounted) return;
                      var ucscTrack = _generateUCSCTrackUrl(result, trackToken);
                      if (ucscTrack.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("No UCSC Track found")),
                        );
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
                                        .map(
                                          (entry) => TextButton(
                                            onPressed: () {
                                              web.window.open(
                                                entry.value,
                                                'new tab',
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(entry.key),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      }
                    },
                    child: Text('Open in UCSC Track browser'),
                  ),
                if (result.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: result.join('\n')),
                      ).then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Snp MIPs copied to clipboard"),
                            ),
                          );
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
          SnackBar(
            content: Text(
              'Failed to load SNP MIPs result: ${describeError(e)}',
            ),
          ),
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
      _errorMessage = 'Failed to load gene categories: ${describeError(e)}';
      return [];
    }
  }

  Future<List<Genome>> getGenomeByCategory(String category) async {
    try {
      return await client.genome.getGenomeByCategory(category);
    } catch (e) {
      _errorMessage = 'Failed to load genes for category: ${describeError(e)}';
      return [];
    }
  }

  Future<List<Snp>> getSnpForGene(int geneId) async {
    try {
      return await client.genome.getAllSnpForGenome(geneId);
    } catch (e) {
      _errorMessage = 'Failed to load snps for genome: ${describeError(e)}';
      return [];
    }
  }

  Future<void> setGenome(int geneId) async {
    try {
      await client.project.setGeneById(widget.project.id!, geneId);
      await _reloadProject();
    } catch (e) {
      _errorMessage = 'Failed to set genome: ${describeError(e)}';
    }
  }

  Future<void> setSnp(int snpId) async {
    try {
      await client.project.setSnpById(widget.project.id!, snpId);
      await _reloadProject();
    } catch (e) {
      _errorMessage = 'Failed to set snp: ${describeError(e)}';
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
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 795;
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
                _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              onPressed: _toggleExpand,
            ),
            title: Text(widget.project.name),
            subtitle: Text(widget.project.description),
            trailing: Wrap(
              spacing: 12,
              children: <Widget>[
                Text(DateFormat("dd.MM.yyyy").format(widget.project.created)),
                Text(
                  '${_truncateToDecimalPlaces(widget.project.size / 1000000000, 2)} GB',
                ),
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
                    Expanded(child: buildGenomeSelectorColumn()),
                    Expanded(child: buildProjectOptionsColumn()),
                    Expanded(child: buildProjectActionColumn()),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  spacing: 25,
                  children: [
                    buildGenomeSelectorColumn(),
                    buildProjectOptionsColumn(),
                    buildProjectActionColumn(),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Column buildProjectActionColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.project.genes?.isNotEmpty == true &&
            widget.project.genome != null &&
            widget.project.bedFileCreated == false) ...[
          ElevatedButton(
            onPressed: _createBedFile,
            child: Text('Create BED File'),
          ),
        ],
        if (widget.project.bedFileCreated == false &&
            (widget.project.genes == null ||
                widget.project.genes?.isEmpty == true ||
                widget.project.genome == null)) ...[
          Tooltip(
            message: "Select a genome and add genes to create a BED file.",
            child: ElevatedButton(
              onPressed: null,
              child: Text('Create BED File'),
            ),
          ),
        ],
        SizedBox(height: 5),
        if (widget.project.bedFileCreated == true &&
            widget.project.active == false &&
            widget.project.completedIn == null)
          buildMipgenStartColumn(),
        SizedBox(height: 5),
        if (widget.project.active == true && widget.project.completedIn == null)
          buildMipgenProgressColumn(),
        if (widget.project.active == false &&
            widget.project.completedIn != null &&
            widget.project.error.isEmpty)
          buildMipgenResultColumn(),
        if (widget.project.active == false &&
            widget.project.completedIn != null &&
            widget.project.error.isNotEmpty)
          Text(
            'Error: ${widget.project.error}',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Column buildGenomeSelectorColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_errorMessage != null)
          Text(_errorMessage!, style: TextStyle(color: Colors.red)),
        if (widget.project.genome == null) buildGenomeSelector(),
        if (widget.project.genome != null) ...[
          Text('Genome:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (genome.name == 'default') ...[
            Text('loading...'),
          ] else ...[
            Text(genome.name),
          ],
        ],
        SizedBox(height: 10),
        if (widget.project.genome != null &&
            genome.snp != null &&
            widget.project.snp == null &&
            !widget.project.active &&
            widget.project.completedIn == null)
          buildSnpSelector(),
        if (widget.project.snp != null) ...[
          Text('Snp:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (snp.name == 'default') ...[
            Text('loading...'),
          ] else ...[
            Text(snp.name),
          ],
        ],
        SizedBox(height: 10),
        if (widget.project.genes != null && widget.project.genes!.isNotEmpty)
          buildGeneColumn(),
        if (widget.project.bedFileCreated == false) buildAddGeneColumn(),
      ],
    );
  }

  Column buildGenomeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
                                              "${selectedGenome.name} (indexing)",
                                            ),
                                            subtitle: Text(
                                              "Genome is currently unavailable",
                                            ),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ] else ...[
                                          ListTile(
                                            title: Text(
                                              "${selectedGenome.name} (not indexed)",
                                            ),
                                            onTap: () {
                                              genome = selectedGenome;
                                              setGenome(selectedGenome.id!);
                                              _reloadProject();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ],
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
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
                    .map(
                      (snp) =>
                          DropdownMenuItem(value: snp, child: Text(snp.name)),
                    )
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Project Options:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          'Logistic Priority Score: ${projectOptions.logisticPriorityScore}',
        ),
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(gene, style: TextStyle(fontStyle: FontStyle.italic)),
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
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
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
        ),
      ],
    );
  }

  Column buildMipgenStartColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
        ElevatedButton(onPressed: _generateMips, child: Text('Generate MIPs')),
      ],
    );
  }

  Column buildMipgenProgressColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: _showProgress, child: Text('Show Progress')),
        SizedBox(height: 10),
      ],
    );
  }

  Column buildMipgenResultColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Completed in: ${_printDuration(widget.project.completedIn!)}'),
        SizedBox(height: 10),
        Text(
          'Output size: ${_truncateToDecimalPlaces(widget.project.size / 1000000000, 2)} GB',
        ),
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
          onPressed: _showUCSCTrack,
          child: Text('Show UCSC Track'),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
