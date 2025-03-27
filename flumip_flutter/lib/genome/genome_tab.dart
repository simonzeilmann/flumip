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

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() async {
    try {
      final categories = await client.genome.getCategories();
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
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  void _collectGenomes() async {
    try {
      await client.genome.collectGenomes();
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

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
                        Text("Categories:", style: Theme.of(context).textTheme.titleLarge),
                        ...categories.map((category) => GestureDetector(
                          onTap: () => _fetchGenomes(category),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedCategory == category ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Text(category, style: TextStyle(color: selectedCategory == category ? Colors.blue : Colors.black)),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                if (selectedCategory != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text("Genomes for $selectedCategory:", style: Theme.of(context).textTheme.titleLarge),
                          ...genomes.map((genome) => GestureDetector(
                            onTap: () => _fetchGenome(genome.id!),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedGenome?.id == genome.id ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: Text(genome.name, style: TextStyle(color: selectedGenome?.id == genome.id ? Colors.blue : Colors.black)),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                if (selectedGenome != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        children: [
                          Text("Details for ${selectedGenome!.name}:", style: Theme.of(context).textTheme.titleLarge),
                          Text("ID: ${selectedGenome!.id}"),
                          Text("Description: ${selectedGenome!.description}"),
                          ElevatedButton(onPressed: _indexGenome, child: Text('index')),
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