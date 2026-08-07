import 'package:flutter/material.dart';

/// A dialog body of a chosen width that still fits on a narrow window.
///
/// Every `AlertDialog` in the app sized its content with a bare
/// `SizedBox(width: …)` — 460, 460, 460, 520, 560. Those widths are fine
/// choices; the problem is that `SizedBox` is not a request, it is an
/// instruction. On a browser window narrower than the number, the child
/// overflows its dialog and Flutter paints the yellow-and-black stripe over it.
/// A 560px body needs a ~660px window, and nothing was stopping a narrower one.
///
/// The clamp keeps the chosen width whenever it fits and gives up exactly as
/// much as it must otherwise. 96px is the room `AlertDialog` wants for its own
/// margins on both sides.
class DialogBody extends StatelessWidget {
  const DialogBody({super.key, required this.width, required this.child});

  /// The width to use when the window allows it.
  final double width;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final available = MediaQuery.sizeOf(context).width - 96;
    return SizedBox(
      // `MediaQuery` is right here and wrong in ResponsiveRow: a dialog floats
      // above the layout and is bounded by the window itself, not by whatever
      // constrains the widget that opened it.
      width: width < available ? width : available,
      child: child,
    );
  }
}
