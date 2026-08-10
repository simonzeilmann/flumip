/// Everything the tile can *open* about a finished run: the result files, the
/// UCSC links, the downloads.
///
/// These are free functions rather than methods because none of them touches the
/// tile's state — each fetches something, decides whether there is anything worth
/// showing, and either opens a dialog or says why not. Grouping them here is what
/// lets `project_tile.dart` be about a project's lifecycle rather than about
/// eight variations on "read a file and put it in a box".
///
/// ⚠️ Unlike the rest of the split, this file is **not** testable: it reaches the
/// top-level `client`, which comes from `main.dart`, which builds a Serverpod
/// client and touches `web.window` at import time. That is precisely why the pure
/// parts — `ucsc_track.dart`, `mipgen_progress.dart`, `result_dialogs.dart` —
/// were pulled out from under it first.
library;

import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../api_config.dart';
import '../error_text.dart';
import '../format.dart';
import '../main.dart';
import '../ui/dialog_body.dart';
import 'mipgen_progress.dart';
import 'result_dialogs.dart';
import 'ucsc_track.dart';

final String siteUrl = resolveSiteUrl();

/// A one-line report, for a failure that does not deserve a banner.
///
/// ⚠️ Every caller checks `context.mounted` first, including in its `catch`, and
/// the analyzer is what holds them to it. Every one of these functions awaits at
/// least one round trip, and deleting a project unmounts its tile while that is
/// still in flight — so an unguarded report here would throw on the way out of a
/// delete.
void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showMipsResultDialog(BuildContext context, int projectId) async {
  try {
    final lines = await client.file.showMipsResult(projectId);
    if (!context.mounted) return;
    if (!resultHasData(lines)) {
      _say(context, 'This run produced no MIPs.');
      return;
    }
    await showTextFileDialog(
      context,
      title: 'MIPs result',
      lines: lines,
      summary: ResultCounts.of(lines).summary,
      emptyMessage: 'No MIPs result file found.',
    );
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Could not load the mips result: ${describeError(e)}');
  }
}

Future<void> showSnpMipsResultDialog(
  BuildContext context,
  int projectId,
) async {
  try {
    final lines = await client.file.showSnpMipsResult(projectId);
    if (!context.mounted) return;
    // ⚠️ Not just `lines.isEmpty`. The file is written with its header row even
    // when the run produced no SNP-overlapping MIPs, so a "present but empty"
    // result used to open a dialog containing one header line and nothing else,
    // which reads as a bug rather than as an answer.
    if (!resultHasData(lines)) {
      _say(context, 'This run produced no SNP MIPs.');
      return;
    }
    await showTextFileDialog(
      context,
      title: 'SNP MIPs result',
      lines: lines,
      summary: ResultCounts.of(lines).summary,
      emptyMessage: 'No SNP MIPs result file found.',
    );
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Could not load the SNP MIPs result: ${describeError(e)}');
  }
}

Future<void> showDesignLogDialog(BuildContext context, int projectId) async {
  try {
    final lines = await client.file.showMipsProgress(projectId);
    if (!context.mounted) return;
    await showTextFileDialog(
      context,
      title: 'Design log',
      lines: lines,
      emptyMessage: 'No progress file yet.',
    );
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Could not load the design log: ${describeError(e)}');
  }
}

/// Opens the project's region in the UCSC genome browser.
///
/// ⚠️ **This used to be two modals deep.** The first dialog dumped the raw
/// contents of the track file — which nobody needs to read — and carried a button
/// that opened a *second* dialog listing the regions to choose from. So the
/// useful list sat underneath the useless one, and a project with a single region
/// still made you read a file to reach one link.
///
/// Now: one region opens straight through, several show one picker, and the track
/// file itself is a separate action for whoever wants it.
Future<void> openUcscTrack(
  BuildContext context, {
  required int projectId,
  required String genomeName,
}) async {
  final List<String> track;
  final String trackToken;
  try {
    track = await client.file.showUSCSTrack(projectId);
    if (!context.mounted) return;
    if (track.isEmpty) {
      _say(context, 'This project has no UCSC track file.');
      return;
    }
    // Fetched only now, so the token is minted when somebody actually opens UCSC
    // rather than whenever the results are looked at.
    trackToken = await client.file.getUcscTrackToken(projectId);
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Could not build the UCSC track link: ${describeError(e)}');
    return;
  }
  if (!context.mounted) return;

  final regions = ucscTrackUrls(
    track: track,
    genomeName: genomeName,
    trackToken: trackToken,
    siteUrl: siteUrl,
  );
  if (regions.isEmpty) {
    _say(context, 'The track file names no regions to show.');
    return;
  }

  // One region is not a choice, so do not stage one.
  if (regions.length == 1) {
    web.window.open(regions.values.first, '_blank');
    return;
  }

  final chosen = await showDialog<String>(
    context: context,
    builder: (_) => UcscTrackDialog(regions: regions),
  );
  if (chosen != null) web.window.open(chosen, '_blank');
}

/// Shows the track file itself, for when the URL is not the point.
Future<void> showUcscTrackFileDialog(
  BuildContext context,
  int projectId,
) async {
  try {
    final track = await client.file.showUSCSTrack(projectId);
    if (!context.mounted) return;
    await showTextFileDialog(
      context,
      title: 'UCSC track file',
      lines: track,
      emptyMessage: 'This project has no UCSC track file.',
    );
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Could not load the track file: ${describeError(e)}');
  }
}

/// Opens a download.
///
/// A plain navigation rather than a fetch: the response carries
/// `Content-Disposition: attachment`, so the browser saves it and draws its own
/// progress, and the bytes never pass through this app. That is what lets a
/// multi-gigabyte project be downloaded at all.
///
/// It also goes to the **web** origin, not the API one — that is where the
/// session cookie is valid, and a download carries no bearer header.
void downloadProjectFile(int projectId, String fileName) {
  web.window.open(
    '$siteUrl/download/$projectId/${Uri.encodeComponent(fileName)}',
    '_blank',
  );
}

Future<void> showProjectDownloadsDialog(
  BuildContext context,
  int projectId,
) async {
  final List<ProjectFileDto> files;
  try {
    files = await client.file.listProjectFiles(projectId);
  } catch (e) {
    if (!context.mounted) return;
    _say(context, 'Failed to list files: ${describeError(e)}');
    return;
  }
  if (!context.mounted) return;

  final total = files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Download files'),
      content: DialogBody(
        width: 460,
        child: files.isEmpty
            ? const Text('This project has no files to download yet.')
            : SingleChildScrollView(
                child: ListBody(
                  children: [
                    for (final file in files)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(file.name),
                        subtitle: Text(formatBytes(file.sizeBytes)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download ${file.name}',
                          onPressed: () =>
                              downloadProjectFile(projectId, file.name),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        if (files.isNotEmpty)
          // The size is on the button on purpose: a project that kept its
          // intermediates can be gigabytes, and "Download all" with no
          // indication is how somebody starts a 4 GB transfer by accident.
          TextButton.icon(
            icon: const Icon(Icons.folder_zip),
            label: Text(
              'Download all (${files.length} files, ${formatBytes(total)})',
            ),
            onPressed: () => downloadProjectFile(projectId, 'all.zip'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
