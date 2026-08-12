import 'package:flutter/material.dart';

/// A small, non-interactive badge: `Ready`, `Global`, `Indexing…`.
///
/// Lifted out of `snp/snp_tile.dart`, where it began as a private `_Chip`, once
/// the genome detail pane needed the same vocabulary for its index state.
///
/// ⚠️ **Deliberately not Material's `Chip`.** `Chip` has a 32px minimum height
/// and a 48px tap target, and three of them on every tile down a list is
/// visibly heavier than this — the SNP list would grow by roughly a third. Making
/// `ChipThemeData` produce this shape needs `materialTapTargetSize: shrinkWrap`
/// plus `VisualDensity.compact` plus `labelPadding: zero`, with the per-instance
/// colours threaded through anyway, which is more configuration than the whole
/// widget. `Chip` is also nominally interactive, and these are not: they are
/// read, never pressed. The app has no Material `Chip` anywhere, which is why
/// the theme deliberately sets no `chipTheme`.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.colour,
    this.icon,
    this.tooltip,
  });

  final String label;

  /// The single colour the pill is built from: the text and icon take it as-is,
  /// the fill and border take it at low alpha. One input, so a caller cannot
  /// produce an unreadable combination by choosing two.
  final Color colour;

  final IconData? icon;

  /// For a label short enough to fit that trades away some meaning to get there.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
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

    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}
