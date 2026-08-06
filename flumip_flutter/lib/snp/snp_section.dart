import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/error_text.dart';
import 'package:flumip_flutter/main.dart';
import 'package:flumip_flutter/snp/add_custom_snp_dialog.dart';
import 'package:flumip_flutter/snp/delete_snp_dialogs.dart';
import 'package:flumip_flutter/snp/edit_snp_dialog.dart';
import 'package:flumip_flutter/snp/snp_status.dart';
import 'package:flumip_flutter/snp/snp_tile.dart';
import 'package:flutter/material.dart';

import '../ui/error_banner.dart';
import '../ui/theme.dart';

/// The SNP sets available for one genome, with whatever a user may do to them.
///
/// Replaces the read-only listing that used to live inside `GenomeDetailsCard`.
/// Two things about that are worth not repeating: it called `fetchSnps()` from
/// inside `build`, so a query went out on every rebuild — and the genome tab
/// rebuilds every five seconds — and it was hidden entirely behind
/// `genome.snp != null`, which is the *scanned* id list, so a genome whose only
/// SNP sets were custom would have shown nothing and offered no way to add one.
class SnpSection extends StatefulWidget {
  const SnpSection({super.key, required this.genome});

  final Genome genome;

  @override
  State<SnpSection> createState() => _SnpSectionState();
}

class _SnpSectionState extends State<SnpSection> {
  List<Snp>? _snps;

  /// The ids this caller added.
  ///
  /// ⚠️ Derived from `listMySnps` rather than compared against the session,
  /// because the session carries no user id — `SessionTokenResponse` has email,
  /// display name and the admin flag, and nothing to match `Snp.owner` against.
  Set<int> _mine = {};

  String? _errorMessage;
  Timer? _timer;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    _load();
    authController.addListener(_onAuthChanged);
    accessController.addListener(_onAccessChanged);
    // An upload's progress is only known in this browser — the server cannot see
    // how far a PUT has got until it lands — so the bar is driven from here.
    snpUploads.addListener(_onUploadsChanged);
  }

  @override
  void didUpdateWidget(SnpSection old) {
    super.didUpdateWidget(old);
    if (old.genome.id != widget.genome.id) {
      setState(() => _snps = null);
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    authController.removeListener(_onAuthChanged);
    accessController.removeListener(_onAccessChanged);
    snpUploads.removeListener(_onUploadsChanged);
    super.dispose();
  }

  void _onUploadsChanged() {
    if (mounted) setState(() {});
  }

  /// The whole list depends on who is asking, so a change of identity has to
  /// throw the answer away rather than keep showing the previous caller's.
  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      _snps = null;
      _mine = {};
    });
    _load();
  }

  /// Admin-ness gates which menu items exist, so a late answer must redraw.
  void _onAccessChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final snps = await client.snp.listSnpsForGenome(widget.genome.id!);
      final mine = await client.snp.listMySnps();
      if (!mounted) return;
      setState(() {
        _snps = snps;
        _mine = mine.map((s) => s.id!).nonNulls.toSet();
        _errorMessage = null;
        _failures = 0;
      });
    } catch (e) {
      if (!mounted) return;
      // Copied from project_tile: a revoked session would otherwise re-report
      // the same refusal every couple of seconds, for as long as the tab is open.
      if (isAccessDenied(e)) {
        _timer?.cancel();
        _timer = null;
        setState(() => _snps = const []);
        return;
      }
      setState(() {
        _failures++;
        _errorMessage = 'Could not load SNP sets: ${describeError(e)}';
      });
    }
    _rearm();
  }

  void _rearm() {
    _timer?.cancel();
    if (!mounted) return;
    final anyLive = (_snps ?? const <Snp>[]).any((s) => !isTerminal(s.status)) ||
        snpUploads.anyLive;
    _timer = Timer(
      pollInterval(anyLive: anyLive, consecutiveFailures: _failures),
      _load,
    );
  }

  Future<void> _handle(Snp snp, SnpAction action) async {
    switch (action) {
      case SnpAction.rename:
        await _rename(snp);
      case SnpAction.share:
        await _setShared(snp, true);
      case SnpAction.unshare:
        await _setShared(snp, false);
      case SnpAction.retry:
        await _run(
          () => client.snp.retryImport(snp.id!),
          failure: 'Could not retry the import',
        );
      case SnpAction.cancelUpload:
        await _run(
          () => client.snp.cancelUpload(snp.id!),
          failure: 'Could not cancel',
          success: 'Removed "${snp.name}".',
        );
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
        // False during a `flutter run`, where the app and the web server are
        // different origins and the session cookie cannot travel with a PUT.
        uploadAvailable: uploadsAvailable,
      ),
    );
    if (draft == null) return;

    final dto = CustomSnpRequestDto(
      name: draft.name,
      description: draft.description,
      genomeId: draft.genomeId,
      private: !draft.shared,
      urls: draft.mode == AddSnpMode.url
          ? [draft.vcfUrl, if (draft.tbiUrl.isNotEmpty) draft.tbiUrl]
          : null,
    );

    if (draft.mode == AddSnpMode.url) {
      await _run(
        () => client.snp.importFromUrls(dto),
        failure: 'Could not start the import',
        success: 'Downloading "${draft.name}" — watch its progress in the list.',
      );
      return;
    }

    // ⚠️ Create the row, then hand the transfer to the long-lived controller and
    // return. The upload must not be owned by anything that can be closed: it
    // takes minutes, and this widget is rebuilt every time the genome selection
    // changes.
    Snp created;
    try {
      created = await client.snp.createUpload(dto);
    } catch (e) {
      _say('Could not start the upload: ${describeError(e)}');
      return;
    }
    await _load();
    snpUploads.start(
      snpId: created.id!,
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
    await _run(
      () => client.snp.renameSnp(snp.id!, edit.name, edit.description),
      failure: 'Could not rename the SNP set',
    );
  }

  Future<void> _setShared(Snp snp, bool shared) async {
    // Optimistic, *with a rollback*. The genome tab's existing active toggle sets
    // state first and never reverts on failure, which leaves the interface
    // asserting something the server refused.
    setState(() => snp.private = !shared);
    try {
      await client.snp.setShared(snp.id!, shared);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => snp.private = shared);
      _say('Could not change sharing: ${describeError(e)}');
    }
  }

  Future<void> _delete(Snp snp) async {
    final usage = await _usage(snp);
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
    await _run(
      () => client.snp.deleteCustomSnp(snp.id!),
      failure: 'Could not delete the SNP set',
      success: 'Deleted "${snp.name}" and its files.',
    );
  }

  Future<void> _adminDelete(Snp snp) async {
    final usage = await _usage(snp);
    if (!mounted) return;
    final confirmation = await showDialog<AdminDeleteConfirmation>(
      context: context,
      builder: (_) => AdminDeleteSnpDialog(
        snp: snp,
        usage: usage ?? const [],
        usageFailed: usage == null,
        // A signed-in administrator needs no password and must not be shown a
        // box asking for one; on a no-auth install it is the only credential.
        needsPassword: !accessController.isAdmin,
      ),
    );
    if (confirmation == null) return;
    await _run(
      () => client.snp.deleteSnpAsAdmin(
        snp.id!,
        confirmation.settingsPassword,
        force: confirmation.force,
      ),
      failure: 'Could not delete the SNP set',
      success: 'Deleted "${snp.name}" and its files.',
    );
  }

  /// The projects using this SNP, or null when the lookup itself failed.
  ///
  /// Read *before* the dialog opens so the confirmation can name them, rather
  /// than spinning inside it. Null and empty are kept apart: the dialog must be
  /// able to say "could not check" instead of implying "nothing is using it".
  Future<List<SnpUsageDto>?> _usage(Snp snp) async {
    try {
      return await client.snp.snpUsage(snp.id!);
    } catch (_) {
      return null;
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failure,
    String? success,
  }) async {
    try {
      await action();
      await _load();
      if (success != null) _say(success);
    } catch (e) {
      if (!mounted) return;
      _say('$failure: ${describeError(e)}');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snps = _snps;
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
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
            child: ErrorBanner(
              _errorMessage!,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ),
        Expanded(
          child: switch (snps) {
            null => const Center(child: CircularProgressIndicator()),
            // Centred, to match the loading state it replaces. It used to be
            // left-aligned, so the pane visibly jumped when the load finished.
            [] => Center(
                child: Text(
                  'No SNP sets for this genome yet.',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colours.onSurfaceVariant),
                ),
              ),
            _ => ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 4, 16, 16),
                itemCount: snps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) => SnpTile(
                  snp: snps[i],
                  isMine: _mine.contains(snps[i].id),
                  isAdmin: accessController.isAdmin,
                  upload: snpUploads[snps[i].id],
                  onCancelUpload: () => snpUploads.cancel(snps[i].id!),
                  onAction: (a) => _handle(snps[i], a),
                ),
              ),
          },
        ),
      ],
    );
  }
}
