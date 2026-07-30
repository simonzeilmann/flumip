import 'dart:async';
import 'dart:math';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'genome_details_card.dart';
import 'genome_subcategory_list.dart';

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
    _timer = Timer.periodic(
      Duration(seconds: 5),
          (_) => _reloadSelectedGenome(),
    );
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
            (a, b) => a.compareTo(b),
      ); // Sort categories alphabetically by name
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
      genomes.sort(
            (a, b) => a.name.compareTo(b.name),
      ); // Sort genomes alphabetically by name
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              "Categories",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: SizedBox(
                            width: 220,
                            child: ListView.separated(
                              itemCount: categories.length,
                              separatorBuilder: (context, _) => SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final isSelected = selectedCategory == category;
                                return Card(
                                  elevation: isSelected ? 4 : 1,
                                  color: isSelected ? Colors.blue[50] : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[300]!),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _fetchGenomes(category),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.label, color: isSelected ? Colors.blue : Colors.grey),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: isSelected ? Colors.blue : Colors.black,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                if (selectedCategory != null)
                  Expanded(
                    child: Center(
                      child: GenomeSubcategoryList(
                        genomes: genomes,
                        selectedGenome: selectedGenome,
                        onGenomeSelected: (id) => _fetchGenome(id),
                        truncateToDecimalPlaces: _truncateToDecimalPlaces,
                      ),
                    ),
                  ),
                if (selectedGenome != null)
                  Expanded(
                    child: Center(
                      child: GenomeDetailsCard(
                        genome: selectedGenome!,
                        genomeActiveNotifier: _genomeActiveNotifier,
                        onDeleteIndex: _showIndexDeleteDialog,
                        onIndexGenome: _indexGenome,
                        onToggleGenomeActive: _toggleGenomeActive,
                        fetchSnps: _fetchSnps,
                        truncateToDecimalPlaces: _truncateToDecimalPlaces,
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
