import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

/// The result of an [EditSnpDialog].
class SnpEdit {
  const SnpEdit({required this.name, required this.description});

  final String name;
  final String description;
}

/// Renames a custom SNP set and rewrites its description.
///
/// Cosmetic only, and the copy says nothing that would suggest otherwise: the
/// files on disk are named after the row id, never after this, so nothing moves
/// and no stored path changes.
///
/// Parameter-in, result-out, so it can be pumped in a test without a client.
class EditSnpDialog extends StatefulWidget {
  const EditSnpDialog({super.key, required this.snp});

  final Snp snp;

  @override
  State<EditSnpDialog> createState() => _EditSnpDialogState();
}

class _EditSnpDialogState extends State<EditSnpDialog> {
  late final _nameController = TextEditingController(text: widget.snp.name);
  late final _descriptionController =
      TextEditingController(text: widget.snp.description);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    return name != widget.snp.name ||
        _descriptionController.text.trim() != widget.snp.description;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename SNP set'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What this SNP set is, and where it came from',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave
              ? () => Navigator.of(context).pop(
                    SnpEdit(
                      name: _nameController.text.trim(),
                      description: _descriptionController.text.trim(),
                    ),
                  )
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
