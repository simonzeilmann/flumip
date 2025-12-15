import 'dart:async';
import 'dart:math';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class GenomeTab extends StatefulWidget {
  const GenomeTab({super.key});

  @override
  State<GenomeTab> createState() => _GenomeTabState();
}

class _GenomeTabState extends State<GenomeTab> {
  List<String> categories = [];
  List<Genome> genomes = [];
  Genome? selectedGenome;
  String? _errorMessage;
  String? selectedCategory;
  Timer? _timer;
  final ValueNotifier<bool> _genomeActiveNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _timer =
        Timer.periodic(Duration(seconds: 5), (_) => _reloadSelectedGenome());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _genomeActiveNotifier.dispose();
    super.dispose();
  }

  void _reloadSelectedGenome() {
    if (selectedGenome != null) {
      _fetchGenome(selectedGenome!.id!);
    }
  }

  void _fetchCategories() async {
    try {
      final categories = await client.genome.getCategories();
      categories.sort(
          (a, b) => a.compareTo(b)); // Sort categories alphabetically by name
      setState(() {
        _errorMessage = null;
        this.categories = categories;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _fetchGenomes(String category) async {
    try {
      final genomes = await client.genome.getGenomeByCategory(category);
      genomes.sort((a, b) =>
          a.name.compareTo(b.name)); // Sort genomes alphabetically by name
      setState(() {
        _errorMessage = null;
        this.genomes = genomes;
        selectedCategory = category;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _fetchGenome(int genomeID) async {
    try {
      final genome = await client.genome.getGenome(genomeID);
      setState(() {
        _errorMessage = null;
        selectedGenome = genome;
        _genomeActiveNotifier.value = genome.active;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _indexGenome() async {
    try {
      await client.genome.indexFasta(selectedGenome!.id!);
      _fetchGenome(selectedGenome!.id!);
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _collectGenomes() async {
    try {
      await client.genome.collectGenomes();
      _fetchCategories();
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _deleteIndex() async {
    try {
      await client.genome.deleteFastaIndex(selectedGenome!.id!);
      _fetchGenome(selectedGenome!.id!);
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _showIndexDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete index for ${selectedGenome!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteIndex();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleGenomeActive(bool value) async {
    try {
      setState(() {
        selectedGenome!.active = value;
      });
      await client.genome.updateGenome(selectedGenome!.id!, selectedGenome!);
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  Future<List<Snp>> _fetchSnps() async {
    try {
      final snps = await client.genome.getAllSnpForGenome(selectedGenome!.id!);
      return snps;
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
      return [];
    }
  }

  double _truncateToDecimalPlaces(num value, int fractionalDigits) =>
      (value * pow(10, fractionalDigits)).truncate() /
      pow(10, fractionalDigits);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _collectGenomes,
            child: Text('Collect Genomes'),
          ),
          SizedBox(height: 50),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text("Categories:",
                            style: Theme.of(context).textTheme.titleLarge),
                        Expanded(
                          child: SizedBox(
                            width: 200,
                            child: ListView.builder(
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return GestureDetector(
                                  onTap: () => _fetchGenomes(category),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: selectedCategory == category
                                          ? Colors.blue[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Text(category,
                                        style: TextStyle(
                                            color: selectedCategory == category
                                                ? Colors.blue
                                                : Colors.black)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedCategory != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text("Genomes for $selectedCategory:",
                              style: Theme.of(context).textTheme.titleLarge),
                          Expanded(
                            child: SizedBox(
                              width: 200,
                              child: ListView.builder(
                                itemCount: genomes.length,
                                itemBuilder: (context, index) {
                                  final genome = genomes[index];
                                  return GestureDetector(
                                    onTap: () => _fetchGenome(genome.id!),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: selectedGenome?.id == genome.id
                                            ? Colors.blue[100]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(genome.name,
                                              style: TextStyle(
                                                  color: selectedGenome?.id ==
                                                          genome.id
                                                      ? Colors.blue
                                                      : Colors.black)),
                                          Text(
                                              'Size: ${_truncateToDecimalPlaces(genome.size / 1000000000, 2)} GB',
                                              style: TextStyle(
                                                  color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selectedGenome != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        spacing: 10,
                        children: [
                          Text("Details for ${selectedGenome!.name}:",
                              style: Theme.of(context).textTheme.titleLarge),
                          Text("ID: ${selectedGenome!.id}"),
                          if (selectedGenome!.description != '')
                            Text("Description: ${selectedGenome!.description}"),
                          ValueListenableBuilder<bool>(
                            valueListenable: _genomeActiveNotifier,
                            builder: (context, value, child) {
                              return Switch(
                                value: value,
                                onChanged: (value) {
                                  _genomeActiveNotifier.value = value;
                                  _toggleGenomeActive(value);
                                },
                              );
                            },
                          ),
                          if (selectedGenome!.indexing)
                            Text("Indexing: ${selectedGenome!.indexing}...")
                          else
                            Text("Indexed: ${selectedGenome!.indexed}"),
                          if (selectedGenome!.indexed &&
                              !selectedGenome!.indexing)
                            ElevatedButton(
                                onPressed: _showIndexDeleteDialog,
                                child: Text('delete index')),
                          if (!selectedGenome!.indexed &&
                              !selectedGenome!.indexing) ...[
                            ElevatedButton(
                                onPressed: _indexGenome, child: Text('index')),
                          ],
                          if (selectedGenome!.snp != null) ...[
                            Text("SNPs:"),
                            FutureBuilder<List<Snp>>(
                              future: _fetchSnps(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Text('No SNPs available');
                                } else {
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final snp = snapshot.data![index];
                                      return GestureDetector(
                                        onTap: () => _fetchSnps(),
                                        child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(snp.name,
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                                if (snp.description != "")
                                                  Text(
                                                      'Description: ${snp.description}',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.black54)),
                                                Text(
                                                  'Size: ${_truncateToDecimalPlaces(snp.size / 1000000000, 2)} Gb',
                                                  style: TextStyle(
                                                      color: Colors.black54),
                                                ),
                                              ],
                                            )
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}
