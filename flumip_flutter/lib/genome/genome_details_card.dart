import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';

class GenomeDetailsCard extends StatelessWidget {
  final Genome genome;
  final ValueNotifier<bool> genomeActiveNotifier;
  final VoidCallback onDeleteIndex;
  final VoidCallback onIndexGenome;
  final void Function(bool) onToggleGenomeActive;
  final Future<List<Snp>> Function() fetchSnps;
  final double Function(num, int) truncateToDecimalPlaces;

  const GenomeDetailsCard({
    super.key,
    required this.genome,
    required this.genomeActiveNotifier,
    required this.onDeleteIndex,
    required this.onIndexGenome,
    required this.onToggleGenomeActive,
    required this.fetchSnps,
    required this.truncateToDecimalPlaces,
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
            if (genome.snp != null) ...[
              Divider(height: 24, thickness: 1),
              Row(
                children: [
                  Icon(Icons.scatter_plot, color: Colors.purple),
                  SizedBox(width: 8),
                  Text("SNPs:", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Snp>>(
                  future: fetchSnps(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No SNPs available');
                    } else {
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, _) => SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final snp = snapshot.data![index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.label_important, color: Colors.purple),
                                      SizedBox(width: 8),
                                      Text(snp.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  if (snp.description != "")
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Description: ${snp.description}', style: TextStyle(color: Colors.black54)),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Size: ${truncateToDecimalPlaces(snp.size / 1000000000, 2)} Gb', style: TextStyle(color: Colors.black54)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
