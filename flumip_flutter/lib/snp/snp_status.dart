import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../ui/status_colors.dart';

// `pollInterval` moved to `lib/poll.dart` once the genome tab needed the same
// rule. Re-exported so the SNP widgets still get their polling from one import.
export '../poll.dart' show pollInterval;

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
///
/// ⚠️ Takes the palette rather than a `BuildContext`, which is what keeps this
/// file testable on the Dart VM — where every test in this app runs.
/// [StatusColors] is const-constructible, so a test passes `StatusColors.light`
/// and never builds a widget tree.
///
/// The five have to be distinguishable at a glance, so this is the one place
/// semantic colour survives the move to scheme roles. `error` is the only one
/// Material 3 supplies; the rest come from the theme extension.
Color statusColour(SnpImportStatus status, StatusColors colours) =>
    switch (status) {
      SnpImportStatus.pending => colours.neutral,
      SnpImportStatus.downloading => colours.info,
      // Warning, not success: an index being built is work in progress, and the
      // genome tab shows its own indexing state the same way.
      SnpImportStatus.indexing => colours.warning,
      SnpImportStatus.ready => colours.success,
      SnpImportStatus.failed => _errorRed,
    };

/// Failure is the one role Material 3 does define, but `statusColour` cannot
/// reach a `ColorScheme` without a context. This matches `ColorScheme.error` for
/// the app's seed closely enough that the two never look like different reds.
const Color _errorRed = Color(0xFFBA1A1A);

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
