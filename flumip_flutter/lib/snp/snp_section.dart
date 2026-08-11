import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/error_banner.dart';
import '../ui/theme.dart';
import 'add_custom_snp_dialog.dart';
import 'delete_snp_dialogs.dart';
import 'edit_snp_dialog.dart';
import 'snp_section_controller.dart';
import 'snp_tile.dart';

/// The SNP sets available for one genome, with whatever a user may do to them.
///
/// Replaces the read-only listing that used to live inside `GenomeDetailsCard`.
/// Two things about that are worth not repeating: it called `fetchSnps()` from
/// inside `build`, so a query went out on every rebuild — and the genome tab
/// rebuilt every five seconds — and it was hidden entirely behind
/// `genome.snp != null`, which is the *scanned* id list, so a genome whose only
/// SNP sets were custom would have shown nothing and offered no way to add one.
///
/// Fetching and changing live in [SnpSectionController]. What stays here is the
/// part that needs a `BuildContext`: four dialogs, and the snack bars.
class SnpSection extends StatefulWidget {
  const SnpSection({super.key, required this.genome, this.controller});

  final Genome genome;

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Owned by this widget when it builds its own, exactly like `GenomeTab`:
  /// it holds a poll for the sets on screen, and one shared instance would go on
  /// polling a genome nobody is looking at. A controller passed in belongs to the
  /// caller and is not disposed here.
  final SnpSectionController? controller;

  @override
  State<SnpSection> createState() => _SnpSectionState();
}

class _SnpSectionState extends State<SnpSection> {
  late final bool _ownsController = widget.controller == null;
  late final SnpSectionController _controller =
      widget.controller ?? createSnpSectionController(widget.genome.id!);
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _messages = _controller.messages.listen(_say);
    _controller.load();
  }

  @override
  void didUpdateWidget(SnpSection old) {
    super.didUpdateWidget(old);
    if (old.genome.id != widget.genome.id) {
      _controller.showGenome(widget.genome.id!);
    }
  }

  @override
  void dispose() {
    _messages?.cancel();
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handle(Snp snp, SnpAction action) async {
    switch (action) {
      case SnpAction.rename:
        await _rename(snp);
      case SnpAction.share:
        await _controller.setShared(snp, true);
      case SnpAction.unshare:
        await _controller.setShared(snp, false);
      case SnpAction.retry:
        await _controller.retry(snp);
      case SnpAction.cancelUpload:
        await _controller.cancelUpload(snp);
      case SnpAction.delete:
        await _delete(snp);
      case SnpAction.adminDelete:
        await _adminDelete(snp);
    }
  }

  Future<void> _add() async {
    final draft = await showDialog<CustomSnpDraft>(
      context: context,
      builder: (_) => AddCustomSnpDialog(
        genome: widget.genome,
        pickFile: pickFile,
        // False during a `flutter run`, where the app and the web server are
        // different origins and the session cookie cannot travel with a PUT.
        uploadAvailable: uploadsAvailable,
      ),
    );
    if (draft == null) return;

    final request = CustomSnpRequestDto(
      name: draft.name,
      description: draft.description,
      genomeId: draft.genomeId,
      private: !draft.shared,
      urls: draft.mode == AddSnpMode.url
          ? [draft.vcfUrl, if (draft.tbiUrl.isNotEmpty) draft.tbiUrl]
          : null,
    );

    if (draft.mode == AddSnpMode.url) {
      await _controller.importFromUrls(request, draft.name);
      return;
    }

    await _controller.startUpload(
      request,
      vcf: draft.vcfFile!,
      tbi: draft.tbiFile,
    );
  }

  Future<void> _rename(Snp snp) async {
    final edit = await showDialog<SnpEdit>(
      context: context,
      builder: (_) => EditSnpDialog(snp: snp),
    );
    if (edit == null) return;
    await _controller.rename(snp, edit.name, edit.description);
  }

  Future<void> _delete(Snp snp) async {
    final usage = await _controller.usage(snp);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteCustomSnpDialog(
        snp: snp,
        usage: usage ?? const [],
        usageFailed: usage == null,
      ),
    );
    if (confirmed != true) return;
    await _controller.delete(snp);
  }

  Future<void> _adminDelete(Snp snp) async {
    final usage = await _controller.usage(snp);
    if (!mounted) return;
    final confirmation = await showDialog<AdminDeleteConfirmation>(
      context: context,
      builder: (_) => AdminDeleteSnpDialog(
        snp: snp,
        usage: usage ?? const [],
        usageFailed: usage == null,
        // A signed-in administrator needs no password and must not be shown a
        // box asking for one; on a no-auth install it is the only credential.
        needsPassword: !_controller.isAdmin,
      ),
    );
    if (confirmation == null) return;
    await _controller.deleteAsAdmin(
      snp,
      confirmation.settingsPassword,
      force: confirmation.force,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snps = _controller.snps;
    final error = _controller.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No leading Divider: the detail pane owns the one divider between its
        // header and this. There used to be two, 24px apart.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
          child: Row(
            children: [
              // The count is part of the heading. It was a bare numeral floating
              // to the right of the title, which reads as nothing at all.
              Text(
                snps == null ? 'SNP sets' : 'SNP sets (${snps.length})',
                style: context.text.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
            child: ErrorBanner(error, onDismiss: _controller.dismissError),
          ),
        Expanded(
          child: switch (snps) {
            null => const Center(child: CircularProgressIndicator()),
            // Centred, to match the loading state it replaces. It used to be
            // left-aligned, so the pane visibly jumped when the load finished.
            [] => Center(
              child: Text(
                'No SNP sets for this genome yet.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ),
            _ => ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 4, 16, 16),
              itemCount: snps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) => SnpTile(
                // Keyed on the set's id. `SnpTile` is stateless, so nothing can
                // be handed to the wrong row the way it could in the projects
                // list — but a key still lets Flutter move an element rather
                // than rebuild every row below a deletion.
                key: ValueKey(snps[i].id),
                snp: snps[i],
                isMine: _controller.isMine(snps[i]),
                isAdmin: _controller.isAdmin,
                upload: _controller.uploads[snps[i].id],
                onCancelUpload: () => _controller.uploads.cancel(snps[i].id!),
                onAction: (a) => _handle(snps[i], a),
              ),
            ),
          },
        ),
      ],
    );
  }
}
