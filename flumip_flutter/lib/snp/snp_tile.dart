import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/format.dart';
import 'package:flumip_flutter/snp/snp_status.dart';
import 'package:flumip_flutter/snp/snp_upload_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One action from an SNP's overflow menu.
enum SnpAction {
  rename,
  share,
  unshare,
  retry,
  cancelUpload,
  delete,
  adminDelete,
}

/// One SNP set in the list.
///
/// Stateless and callback-driven: everything it can do is handed up to
/// [SnpSection], which owns the client calls and the refresh.
class SnpTile extends StatelessWidget {
  const SnpTile({
    super.key,
    required this.snp,
    required this.isMine,
    required this.isAdmin,
    required this.onAction,
    this.upload,
    this.onCancelUpload,
  });

  final Snp snp;

  /// A browser upload in flight for this SNP set, if there is one.
  ///
  /// ⚠️ When present it **wins over the row's own byte counts**: the server cannot
  /// know how far a PUT has got until it lands, so it would show zero for however
  /// long the transfer takes.
  final UploadJob? upload;
  final VoidCallback? onCancelUpload;

  /// Whether this caller added it. Not computable from the session — it carries
  /// no user id — so it is derived from `listMySnps` by the section above.
  final bool isMine;
  final bool isAdmin;
  final void Function(SnpAction) onAction;

  bool get _mayEdit => snp.custom && (isMine || isAdmin);

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  snp.custom ? Icons.label_important : Icons.dns,
                  color: snp.custom ? Colors.purple : Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snp.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_mayEdit || isAdmin) _menu(context),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: _chips()),
            if (snp.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  snp.description,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${formatBytes(snp.size)} · '
                'added ${DateFormat('dd.MM.yyyy').format(snp.created)}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            if (upload != null)
              _uploadProgress(upload!)
            else if (!isTerminal(snp.status))
              _progress(),
            if (upload == null && snp.status == SnpImportStatus.failed)
              _failure(),
          ],
        ),
      ),
    );
  }

  List<Widget> _chips() => [
        if (!snp.custom)
          const _Chip(label: 'Global', colour: Colors.blueGrey)
        else ...[
          const _Chip(label: 'Custom', colour: Colors.purple),
          if (isMine)
            _Chip(
              label: snp.private ? 'Private' : 'Shared',
              icon: snp.private ? Icons.lock_outline : Icons.public,
              colour: snp.private ? Colors.grey : Colors.teal,
            )
          else
            const _Chip(
              label: 'Shared by someone else',
              icon: Icons.public,
              colour: Colors.teal,
            ),
        ],
        // ⚠️ On every SNP set, global ones included. The first version hid this
        // on globals, on the theory that they are ready by construction and a
        // "Ready" badge on each is noise — but that stopped being true the moment
        // the reconcile pass could mark one `failed` for missing files or
        // `indexing` while its index is rebuilt. Hiding the chip hid the failure.
        _Chip(
          label: statusLabel(snp.status),
          icon: statusIcon(snp.status),
          colour: statusColour(snp.status),
        ),
      ];

  Widget _progress() {
    final fraction = progressFraction(snp.bytesDownloaded, snp.totalBytes);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 4),
          Text(
            snp.totalBytes > 0
                ? '${formatBytes(snp.bytesDownloaded)} of '
                    '${formatBytes(snp.totalBytes)}'
                : statusLabel(snp.status),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// The bar for a browser upload, driven by this tab rather than by the row.
  Widget _uploadProgress(UploadJob job) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.error == null) ...[
              LinearProgressIndicator(value: job.fraction),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Uploading ${job.fileLabel} — '
                      '${formatBytes(job.sent)} of ${formatBytes(job.total)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (onCancelUpload != null)
                    TextButton(
                      onPressed: onCancelUpload,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ] else
              SelectableText(
                job.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
      );

  Widget _failure() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shown in full and selectable: the messages carry the command to
            // fix the problem (`bgzip -c …`) or tabix's own diagnostic, and
            // truncating them would throw away the useful half.
            SelectableText(
              snp.statusMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            if (_mayEdit)
              TextButton.icon(
                onPressed: () => onAction(SnpAction.retry),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
          ],
        ),
      );

  Widget _menu(BuildContext context) {
    return PopupMenuButton<SnpAction>(
      onSelected: onAction,
      itemBuilder: (context) => [
        if (_mayEdit)
          const PopupMenuItem(
            value: SnpAction.rename,
            child: Text('Rename…'),
          ),
        if (_mayEdit)
          PopupMenuItem(
            value: snp.private ? SnpAction.share : SnpAction.unshare,
            child: Text(snp.private ? 'Share with everyone' : 'Make private'),
          ),
        if (_mayEdit && snp.status == SnpImportStatus.failed)
          const PopupMenuItem(
            value: SnpAction.retry,
            child: Text('Retry import'),
          ),
        // A row whose files never turned up. Offered as its own action rather
        // than as a plain delete, because there is nothing here to lose and no
        // confirmation is warranted.
        if (_mayEdit &&
            upload == null &&
            snp.status == SnpImportStatus.pending)
          const PopupMenuItem(
            value: SnpAction.cancelUpload,
            child: Text('Cancel — no files arrived'),
          ),
        if (_mayEdit)
          const PopupMenuItem(
            value: SnpAction.delete,
            child: Text('Delete…', style: TextStyle(color: Colors.red)),
          ),
        // Visually separated, because it is a different kind of act: it can
        // reach the server's reference data, and it cannot be undone.
        if (isAdmin) const PopupMenuDivider(),
        if (isAdmin)
          const PopupMenuItem(
            value: SnpAction.adminDelete,
            child: Text(
              'Delete as administrator…',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.colour, this.icon});

  final String label;
  final Color colour;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colour),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colour,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
