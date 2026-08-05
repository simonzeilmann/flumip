import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/snp_section.dart';

class GenomeDetailsCard extends StatelessWidget {
  final Genome genome;
  final ValueNotifier<bool> genomeActiveNotifier;
  final VoidCallback onDeleteIndex;
  final VoidCallback onIndexGenome;
  final void Function(bool) onToggleGenomeActive;

  const GenomeDetailsCard({
    super.key,
    required this.genome,
    required this.genomeActiveNotifier,
    required this.onDeleteIndex,
    required this.onIndexGenome,
    required this.onToggleGenomeActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Details for ${genome.name}",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 24, thickness: 1),
            Row(
              children: [
                Icon(Icons.fingerprint, color: Colors.grey),
                SizedBox(width: 8),
                Text("ID: ${genome.id}", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (genome.description != '') ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("Description: ${genome.description}", style: TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.toggle_on, color: Colors.green),
                SizedBox(width: 8),
                Text("Active:"),
                ValueListenableBuilder<bool>(
                  valueListenable: genomeActiveNotifier,
                  builder: (context, value, child) {
                    return Switch(
                      value: value,
                      onChanged: (value) {
                        genomeActiveNotifier.value = value;
                        onToggleGenomeActive(value);
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange),
                SizedBox(width: 8),
                if (genome.indexing)
                  Text("Indexing: ${genome.indexing}...", style: TextStyle(color: Colors.orange))
                else
                  Text("Indexed: ${genome.indexed}", style: TextStyle(color: genome.indexed ? Colors.green : Colors.red)),
              ],
            ),
            if (genome.indexed && !genome.indexing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.delete),
                  onPressed: onDeleteIndex,
                  label: Text('Delete Index'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
              ),
            if (!genome.indexed && !genome.indexing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.build),
                  onPressed: onIndexGenome,
                  label: Text('Index'),
                ),
              ),
            // ⚠️ Deliberately not gated on `genome.snp != null`. That field is
            // the denormalised list of *scanned* ids, so a genome whose only SNP
            // sets are custom used to show nothing here at all — and therefore
            // offered no way to add one either.
            Expanded(child: SnpSection(genome: genome)),
          ],
        ),
      ),
    );
  }
}
