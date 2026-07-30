import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';

class GenomeSubcategoryList extends StatelessWidget {
  final List<Genome> genomes;
  final Genome? selectedGenome;
  final void Function(int genomeId) onGenomeSelected;
  final double Function(num, int) truncateToDecimalPlaces;

  const GenomeSubcategoryList({
    super.key,
    required this.genomes,
    required this.selectedGenome,
    required this.onGenomeSelected,
    required this.truncateToDecimalPlaces,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.biotech, color: Colors.green),
            SizedBox(width: 8),
            Text(
              "Genomes for ${selectedGenome?.category ?? ''}:",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: SizedBox(
            width: 260,
            child: ListView.separated(
              itemCount: genomes.length,
              separatorBuilder: (context, _) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final genome = genomes[index];
                final isSelected = selectedGenome?.id == genome.id;
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.green[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.grey[300]!,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onGenomeSelected(genome.id!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.biotech,
                                color: isSelected ? Colors.green : Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  genome.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.storage,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Size: ${truncateToDecimalPlaces(genome.size / 1000000000, 2)} GB',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          if (genome.description.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    genome.description,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
