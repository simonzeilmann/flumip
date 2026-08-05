import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

/// Pure helpers for describing where an SNP's bytes are in their journey.
///
/// Kept out of the widgets so they can be tested on the Dart VM, which is where
/// every test in this app runs today.

/// Whether nothing more is going to happen to this SNP on its own.
///
/// Drives the polling: while anything visible is non-terminal the list refreshes
/// briskly, and once everything has settled it drops back to a slow check for
/// something a colleague shared.
bool isTerminal(SnpImportStatus status) =>
    status == SnpImportStatus.ready || status == SnpImportStatus.failed;

/// What to call a status in the interface.
String statusLabel(SnpImportStatus status) => switch (status) {
      SnpImportStatus.pending => 'Queued',
      SnpImportStatus.downloading => 'Downloading',
      SnpImportStatus.indexing => 'Indexing',
      SnpImportStatus.ready => 'Ready',
      SnpImportStatus.failed => 'Failed',
    };

/// The colour a status chip is drawn in.
Color statusColour(SnpImportStatus status) => switch (status) {
      SnpImportStatus.pending => Colors.grey,
      SnpImportStatus.downloading => Colors.blue,
      // Orange matches how the genome tab already shows an index being built.
      SnpImportStatus.indexing => Colors.orange,
      SnpImportStatus.ready => Colors.green,
      SnpImportStatus.failed => Colors.red,
    };

/// The icon beside the label.
IconData statusIcon(SnpImportStatus status) => switch (status) {
      SnpImportStatus.pending => Icons.schedule,
      SnpImportStatus.downloading => Icons.cloud_download,
      SnpImportStatus.indexing => Icons.build,
      SnpImportStatus.ready => Icons.check_circle,
      SnpImportStatus.failed => Icons.error_outline,
    };

/// How far along a download is, or null when the total is not known.
///
/// ⚠️ **Clamped, and that is not defensive tidying.** `LinearProgressIndicator`
/// *asserts* on a value outside 0..1 in debug builds, so a server that reports
/// more bytes than it expected — a redirect it counted twice, a `Content-Length`
/// that was a lie — would take the whole tab down rather than draw a full bar.
double? progressFraction(int done, int total) =>
    total <= 0 ? null : (done / total).clamp(0.0, 1.0);

/// How long to wait before asking the server again.
///
/// Tight while something can still move, because two seconds is about the pace of
/// a byte counter somebody is actually watching. Slow otherwise: 20 seconds is
/// the cost of noticing an SNP a colleague has just shared, and is the same order
/// as the genome tab's existing five-second poll.
///
/// [consecutiveFailures] backs the interval off so that a server that has gone
/// away is not hammered, capped so it always recovers within a minute or so.
Duration pollInterval({required bool anyLive, int consecutiveFailures = 0}) {
  final base = anyLive
      ? const Duration(seconds: 2)
      : const Duration(seconds: 20);
  return base * (1 << consecutiveFailures.clamp(0, 3));
}
