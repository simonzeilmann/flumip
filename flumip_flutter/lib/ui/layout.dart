import 'package:flutter/material.dart';

/// Below this, a master–detail cannot show both panes and collapses to one.
///
/// The only real breakpoint left in the app. Everything else decides from the
/// space it is actually given — see [ResponsiveRow] in `responsive_row.dart` —
/// because a fixed pixel threshold answers the wrong question once content is
/// capped: a row inside a 900px form on a 3440px monitor is narrow, whatever the
/// window says.
///
/// 840 is Material 3's medium/expanded window boundary, and it is also the
/// honest number here: a 320px rail plus a divider plus the ~480px an SNP tile
/// needs for a chip row and a progress bar.
const double kSplitWidth = 840;

/// Caps content and centres it, so a wide monitor gets margins instead of very
/// long lines.
///
/// The app had no width constraint at any level — `MaterialApp → Scaffold →
/// TabBarView` straight through to each tab — so every list ran the full width
/// of the display. That is the "everything is too large" complaint: not type
/// size, but a project row rendered as one item on a 3400px line.
///
/// Applied per tab rather than once around `TabBarView`, for four reasons that
/// are specific to this tree:
///
///  1. The settings tab returns a `SingleChildScrollView` directly into
///     `TabBarView`. A cap outside it would leave the scrollbar at the window
///     edge, a thousand pixels from the content it scrolls — so there the cap has
///     to live *inside* the scroll view.
///  2. The three surfaces want three different widths ([content], [form],
///     [wide]).
///  3. The genome tab is a master–detail and needs the rail rebuilt, not just a
///     cap.
///  4. The `TabBar` lives in `AppBar.bottom` and should stay full-bleed. Chrome
///     the width of the window, content capped, is the right look.
///
/// ⚠️ **The child is given a tight width, on purpose.** `Center` loosens the
/// constraints it passes down, which would let the child shrink-wrap to nothing
/// — a `SizedBox(height: 100)` inside a loose parent is 100 tall and *zero*
/// wide. The `SizedBox(width: double.infinity)` below clamps against the
/// `maxWidth` above it, so the contract is "fill the width you are given, up to
/// the cap", which is what every caller expects.
///
/// Vertically it stays loose, so an `Expanded` in a parent `Column` still
/// resolves. Children that lay out on the cross axis — a `Column` of fields —
/// should still pass `crossAxisAlignment: CrossAxisAlignment.stretch` if they
/// want their children to fill rather than centre.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    this.maxWidth = content,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    required this.child,
  });

  /// Lists and tables — the projects tab.
  ///
  /// Set by how many data columns must sit side by side, not by reading measure.
  /// A project tile and the create-project form both want three columns; 1400
  /// less gutters gives each about 440px, comfortably past the ~340px the old
  /// hand-written 1020 threshold treated as usable.
  static const double content = 1400;

  /// Forms — the settings tab.
  ///
  /// Two ~430px field columns plus a gutter. Narrower than [content] on purpose:
  /// a form is not a table, and a value like `/opt/flumip/data/genomes` needs
  /// about 400px not to scroll inside its own field.
  static const double form = 900;

  /// The genome master–detail, which uses width productively — but 3400px of SNP
  /// tile is still absurd.
  static const double wide = 1800;

  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
