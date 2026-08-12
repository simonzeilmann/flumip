import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// The genes on a panel, as removable chips, with the add field beneath.
///
/// ⚠️ Was a centred `Column` of `Row(Text + IconButton)` — one gene per line, so
/// a twenty-gene panel was a twenty-line list — plus a separate builder for the
/// add field that hand-rolled its own border, fill and padding and so stopped
/// matching every other field once the app had an `InputDecorationTheme`.
///
/// Stateful because it owns the add field's [TextEditingController]. That
/// controller is the only mutable thing in the whole left column, and keeping it
/// here rather than in the tile means the tile no longer has a controller to
/// forget to dispose.
class GeneEditor extends StatefulWidget {
  const GeneEditor({
    super.key,
    required this.genes,
    required this.editable,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> genes;

  /// False once the BED file has been built: the target regions are derived from
  /// this list, so changing it afterwards would describe a design that was never
  /// run.
  final bool editable;

  final void Function(String gene) onAdd;
  final void Function(String gene) onRemove;

  @override
  State<GeneEditor> createState() => _GeneEditorState();
}

class _GeneEditorState extends State<GeneEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final gene = value.trim();
    // Was unguarded, so pressing the button with an empty box sent an empty gene
    // name to the server and produced a failure for no reason.
    if (gene.isEmpty) return;
    widget.onAdd(gene);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.genes.isEmpty)
          Text(
            'None yet.',
            style: TextStyle(color: context.colours.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final gene in widget.genes)
                widget.editable
                    ? InputChip(
                        label: Text(gene),
                        labelStyle: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                        onDeleted: () => widget.onRemove(gene),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      )
                    : Chip(
                        label: Text(gene),
                        labelStyle: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
            ],
          ),
        if (widget.editable) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Add a gene',
                    hintText: 'e.g. BRCA1',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                tooltip: 'Add gene',
                onPressed: () => _submit(_controller.text),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
