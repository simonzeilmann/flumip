import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// What a MIP design run is doing right now, read out of its progress file.
///
/// mipgen writes a `.progress.txt` as it works. Until now the only way to see it
/// was a "Show Progress" button that opened a modal with the whole file in it —
/// so the answer to "is this still going?" was three clicks away and stale the
/// moment it was drawn.
class MipgenProgress {
  const MipgenProgress({required this.lines});

  const MipgenProgress.empty() : lines = const [];

  final List<String> lines;

  /// The last line with anything on it, which is what the run is doing now.
  String? get current {
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      if (line.isNotEmpty) return line;
    }
    return null;
  }

  /// A fraction, when the progress file happens to state one.
  ///
  /// ⚠️ Returns null rather than guessing, and null means an indeterminate bar.
  /// A made-up percentage that sticks at 40% for ten minutes is worse than an
  /// honest barber's pole — it invites people to estimate a finish time from a
  /// number nobody computed.
  ///
  /// ⚠️ Clamped, because `LinearProgressIndicator` *asserts* on a value outside
  /// 0..1 in a debug build, which would take the tab down rather than draw a
  /// full bar. Same reasoning as `progressFraction` in `snp/snp_status.dart`.
  double? get fraction {
    final line = current;
    if (line == null) return null;

    // "43%" or "43 %" anywhere in the line.
    final percent = RegExp(r'(\d{1,3})\s*%').firstMatch(line);
    if (percent != null) {
      final value = int.parse(percent.group(1)!) / 100;
      return value.clamp(0.0, 1.0);
    }

    // "designing MIPs for gene 3 of 12"
    final ofTotal = RegExp(r'\b(\d+)\s*(?:of|/)\s*(\d+)\b').firstMatch(line);
    if (ofTotal != null) {
      final done = int.parse(ofTotal.group(1)!);
      final total = int.parse(ofTotal.group(2)!);
      if (total > 0) return (done / total).clamp(0.0, 1.0);
    }

    return null;
  }
}

/// The live panel shown while a design run is going.
class MipgenProgressPanel extends StatelessWidget {
  const MipgenProgressPanel({
    super.key,
    required this.progress,
    required this.elapsed,
    required this.onShowLog,
  });

  final MipgenProgress progress;

  /// How long the run has been going, or null if that is not known.
  final Duration? elapsed;

  final VoidCallback onShowLog;

  @override
  Widget build(BuildContext context) {
    final line = progress.current;
    final fraction = progress.fraction;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.status.infoContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.status.onInfoContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Designing MIPs',
                  style: context.text.labelLarge?.copyWith(
                    color: context.status.onInfoContainer,
                  ),
                ),
              ),
              if (elapsed != null)
                Text(
                  _short(elapsed!),
                  style: context.text.bodySmall?.copyWith(
                    color: context.status.onInfoContainer,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: context.status.onInfoContainer.withValues(
                alpha: 0.15,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // The run has usually been going for some seconds before mipgen
            // writes anything, so say that rather than showing a blank line.
            line ?? 'Starting up…',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: context.status.onInfoContainer,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onShowLog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                foregroundColor: context.status.onInfoContainer,
              ),
              child: const Text('Show full log'),
            ),
          ),
        ],
      ),
    );
  }

  static String _short(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
