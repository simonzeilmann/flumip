import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/dialog_body.dart';
import '../ui/theme.dart';

/// Shows the contents of one of the project's text files.
///
/// Replaces four near-identical `AlertDialog`s — MIPs result, SNP MIPs result,
/// progress log, UCSC track file — each of which built its own `ListBody` of
/// `Text` widgets, one per line. That renders every line of a file that can run
/// to thousands of rows, in the proportional body font, with no way to copy it
/// in one go.
///
/// Monospaced, because these are columnar files whose alignment is the point,
/// and built lazily so a long result does not lock the frame.
Future<void> showTextFileDialog(
  BuildContext context, {
  required String title,
  required List<String> lines,
  String emptyMessage = 'Nothing here yet.',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _TextFileDialog(title: title, lines: lines, emptyMessage: emptyMessage),
  );
}

class _TextFileDialog extends StatelessWidget {
  const _TextFileDialog({
    required this.title,
    required this.lines,
    required this.emptyMessage,
  });

  final String title;
  final List<String> lines;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final empty = lines.isEmpty;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (!empty)
            Text(
              '${lines.length} line${lines.length == 1 ? '' : 's'}',
              style: context.text.bodySmall?.copyWith(
                color: context.colours.onSurfaceVariant,
              ),
            ),
        ],
      ),
      content: DialogBody(
        width: 760,
        child: empty
            ? Text(
                emptyMessage,
                style: TextStyle(color: context.colours.onSurfaceVariant),
              )
            : SizedBox(
                height: 420,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colours.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colours.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(8),
                  // Horizontal scroll rather than wrapping: these lines are
                  // records, and wrapping one makes it look like two.
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (context, i) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          lines[i],
                          maxLines: 1,
                          style: context.mono.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
      actions: [
        if (!empty)
          TextButton.icon(
            icon: const Icon(Icons.copy_all, size: 18),
            label: const Text('Copy all'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: lines.join('\n')));
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $title to the clipboard.')),
              );
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Picks which region to open in the UCSC genome browser.
///
/// ⚠️ **Replaces two stacked modals.** The old flow opened a dialog showing the
/// raw contents of the track file — which nobody needs to read — with a button
/// inside it that opened a *second* dialog listing the regions. Two modals deep
/// to reach a link, with the useful list underneath the useless one.
///
/// This is only shown when there is a genuine choice: a project with a single
/// region opens straight through to UCSC, because a one-item picker is a
/// question with one answer.
class UcscTrackDialog extends StatelessWidget {
  const UcscTrackDialog({super.key, required this.regions});

  /// Region name to the UCSC URL that shows it.
  final Map<String, String> regions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open in UCSC'),
      content: DialogBody(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This project covers ${regions.length} regions. '
              'Each opens in a new tab.',
              style: TextStyle(color: context.colours.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in regions.entries)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => Navigator.of(context).pop(entry.value),
                      ),
                  ],
                ),
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
      ],
    );
  }
}
