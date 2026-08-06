import 'package:flutter/material.dart';

/// Side by side when there is room for it, stacked when there is not.
///
/// This is an idiom the app had already written twice by hand — in
/// `project_tile.dart` and `create_project_widget.dart`, both as
/// `if (isScreenWide) Row(3 × Expanded) else Column`, and each with its own
/// `MediaQuery.sizeOf` read and its own magic number. The two numbers disagreed
/// (795 and 1020) and neither was named.
///
/// Rather than name two constants, this asks the question that actually matters:
/// **is there room for each child to be usable?** [minChildWidth] is the answer
/// in the only units that mean anything — how wide one column has to be before
/// putting three of them in a row stops helping.
///
/// ⚠️ **`LayoutBuilder`, never `MediaQuery.sizeOf`, and that is load-bearing.**
/// Once content is capped by `ContentWidth`, the window size stops describing
/// the space a widget has. A row inside a 900px settings form on a 3440px
/// monitor would see 3440 from `MediaQuery` and lay out three columns in a space
/// that fits one. Capping the width while leaving the old `MediaQuery` reads in
/// place would therefore have *introduced* that bug, which is why the cap and
/// this widget were adopted in the same change.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.minChildWidth = 300,
    this.flex = const [],
    this.spacing = 16,
    double? stackSpacing,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : stackSpacing = stackSpacing ?? spacing;

  final List<Widget> children;

  /// The narrowest a single child may become before the row stacks instead.
  final double minChildWidth;

  /// Optional per-child flex, for pairs that are not equals.
  ///
  /// `flex: [3, 1]` is how an SMTP server and its port share a line: a hostname
  /// wants the room, a five-digit port does not. Equal columns — which is all a
  /// grid can offer — would leave the port field 430px wide for four characters.
  ///
  /// Shorter than [children], or empty, means the rest default to 1.
  final List<int> flex;

  /// The gutter between columns when they sit side by side.
  final double spacing;

  /// The gap between them once they stack, which usually wants to be larger.
  ///
  /// A 10px gutter reads as "these are columns of one thing"; 10px of vertical
  /// space between three stacked sections reads as one undifferentiated run.
  /// Defaults to [spacing] when the distinction does not matter.
  final double stackSpacing;

  final CrossAxisAlignment crossAxisAlignment;

  int _flexAt(int i) => i < flex.length ? flex[i] : 1;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final needed =
            minChildWidth * children.length + spacing * (children.length - 1);
        // An unbounded width — inside a horizontal scroll view, say — has room
        // for anything, so lay out wide rather than dividing by infinity.
        final fits = !constraints.hasBoundedWidth ||
            constraints.maxWidth >= needed;

        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: stackSpacing,
            children: children,
          );
        }

        return Row(
          crossAxisAlignment: crossAxisAlignment,
          spacing: spacing,
          children: [
            for (var i = 0; i < children.length; i++)
              Expanded(flex: _flexAt(i), child: children[i]),
          ],
        );
      },
    );
  }
}
