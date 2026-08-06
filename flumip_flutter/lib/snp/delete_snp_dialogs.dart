import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flumip_flutter/ui/dialog_body.dart';

/// What an administrative delete was confirmed with.
class AdminDeleteConfirmation {
  const AdminDeleteConfirmation({this.settingsPassword, required this.force});

  /// Null when the caller is a signed-in administrator, who needs no password.
  final String? settingsPassword;

  /// Whether to go ahead even though projects are still using the SNP.
  final bool force;
}

/// Confirms deleting your own custom SNP.
///
/// A plain red confirm, deliberately. The administrative dialog below asks the
/// user to type the SNP's name, and making *both* ask for that would train people
/// to type names without reading — which is exactly the habit the hard one relies
/// on them not having.
///
/// Takes its data as parameters and returns its answer, touching no global
/// client, so it can be pumped in a widget test.
class DeleteCustomSnpDialog extends StatelessWidget {
  const DeleteCustomSnpDialog({
    super.key,
    required this.snp,
    required this.usage,
    this.usageFailed = false,
  });

  final Snp snp;

  /// The projects using this SNP, read *before* the dialog opened.
  final List<SnpUsageDto> usage;

  /// True when that lookup failed, so the dialog can say it does not know rather
  /// than implying "nothing is using it".
  final bool usageFailed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete "${snp.name}"?'),
      content: DialogBody(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This removes the SNP set and its files from the server. '
              'It cannot be undone.',
            ),
            const SizedBox(height: 16),
            if (usageFailed)
              Text(
                'Could not check which projects are using it.',
                style: TextStyle(color: context.status.warning),
              )
            else if (usage.isEmpty)
              Text(
                'No projects are using it.',
                style: TextStyle(color: context.colours.onSurfaceVariant),
              )
            else
              _UsageWarning(usage: usage),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colours.error,
            foregroundColor: context.colours.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// Confirms an administrator deleting **any** SNP, including a global one.
///
/// ⚠️ This is the most destructive thing in the application. A global SNP's files
/// are part of the hand-assembled genome tree — dbSNP is tens of gigabytes and
/// hours of transfer, quite possibly on a shared mount — and there is no undo.
///
/// So the dialog is unmistakably not the ordinary one: a warning icon, the
/// literal paths that are about to be removed, the projects that will lose their
/// selection, and a name that has to be typed exactly before the button comes
/// alive. Showing the paths is the single most useful thing here — an
/// administrator who sees a path they did not expect stops.
class AdminDeleteSnpDialog extends StatefulWidget {
  const AdminDeleteSnpDialog({
    super.key,
    required this.snp,
    required this.usage,
    required this.needsPassword,
    this.usageFailed = false,
  });

  final Snp snp;
  final List<SnpUsageDto> usage;
  final bool usageFailed;

  /// True on an install with no sign-in, where the settings password is the only
  /// administrative credential there is. A signed-in administrator needs none,
  /// and must not be shown a field asking for one.
  final bool needsPassword;

  @override
  State<AdminDeleteSnpDialog> createState() => _AdminDeleteSnpDialogState();
}

class _AdminDeleteSnpDialogState extends State<AdminDeleteSnpDialog> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _force = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Case-sensitive, and the helper text says so. A confirmation that accepts an
  /// approximation is not a confirmation.
  bool get _nameMatches => _nameController.text.trim() == widget.snp.name;

  bool get _canDelete {
    if (!_nameMatches) return false;
    if (widget.usage.isNotEmpty && !_force) return false;
    if (widget.needsPassword && _passwordController.text.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final snp = widget.snp;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: context.colours.error, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Delete "${snp.name}" as administrator',
              style: TextStyle(color: context.colours.error),
            ),
          ),
        ],
      ),
      content: DialogBody(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!snp.custom)
                const Text(
                  'This is a global SNP set, found by scanning the genome '
                  'directory. Its files are part of the server\'s reference '
                  'data and will be deleted from disk. Restoring it means '
                  'putting the files back and collecting again.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'This removes the SNP set and its files from the server.',
                ),
              const SizedBox(height: 16),
              const Text(
                'These files will be deleted:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              _PathBlock(paths: [
                if (snp.vcfPath.isNotEmpty) snp.vcfPath,
                if (snp.tbiPath.isNotEmpty) snp.tbiPath,
                if (snp.vcfPath.isEmpty && snp.tbiPath.isEmpty)
                  snp.folder.isEmpty ? '(nothing on disk)' : snp.folder,
              ]),
              const SizedBox(height: 16),
              if (widget.usageFailed)
                Text(
                  'Could not check which projects are using it.',
                  style: TextStyle(color: context.status.warning),
                )
              else if (widget.usage.isEmpty)
                Text(
                  'No projects are using it.',
                  style: TextStyle(color: context.colours.onSurfaceVariant),
                )
              else ...[
                _UsageWarning(usage: widget.usage),
                CheckboxListTile(
                  value: _force,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => _force = v ?? false),
                  title: Text(
                    'Delete anyway, detaching it from '
                    '${widget.usage.length} project(s).',
                  ),
                ),
              ],
              if (widget.needsPassword) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Settings password',
                    helperText:
                        'This server has no sign-in, so the settings password '
                        'is the administrator credential.',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Confirm the name',
                  helperText: 'Type ${snp.name} exactly, including capitals.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canDelete
              ? () => Navigator.of(context).pop(
                    AdminDeleteConfirmation(
                      settingsPassword: widget.needsPassword
                          ? _passwordController.text
                          : null,
                      force: _force,
                    ),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colours.error,
            foregroundColor: context.colours.onError,
          ),
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}

/// The projects that will lose their SNP, named rather than counted.
class _UsageWarning extends StatelessWidget {
  const _UsageWarning({required this.usage});

  final List<SnpUsageDto> usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colours.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colours.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${usage.length} project(s) are using this SNP set:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final u in usage) Text('  • ${u.projectName}'),
          const SizedBox(height: 6),
          // "as of a moment ago" rather than a claim of certainty: this was read
          // before the dialog opened, and a project can adopt the SNP while it
          // sits here. That is what the force flag is really for.
          Text(
            'Checked a moment ago. Deleting it will leave them with no SNP set.',
            style: TextStyle(
              color: context.colours.onErrorContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Absolute paths, selectable and in a monospaced face so they can be read
/// character by character and copied into a shell to check.
class _PathBlock extends StatelessWidget {
  const _PathBlock({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colours.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colours.outlineVariant),
      ),
      child: SelectableText(
        paths.join('\n'),
        style: context.mono.copyWith(fontSize: 12),
      ),
    );
  }
}
