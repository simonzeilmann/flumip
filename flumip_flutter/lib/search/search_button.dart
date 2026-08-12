import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/layout.dart';
import '../ui/theme.dart';
import 'search_controller.dart';
import 'search_dialog.dart';

/// How wide the field is when nothing is competing for the space.
///
/// ⚠️ Sized to the hint, not picked round. [_hint] is 29 characters, which Roboto
/// sets at roughly 200px at `bodyMedium`; the icon, the two gaps, the `Ctrl K`
/// chip and the horizontal padding add about 115 more. 300 therefore cut the hint
/// short by a word — the field advertised what it searched and then hid half of
/// it. The remainder is headroom for a face with wider metrics.
const double _fieldMaxWidth = 360;

/// How narrow it may be squeezed before collapsing is the better answer.
const double _fieldMinWidth = 190;

/// What the field says it searches. Named because [_fieldMaxWidth] is derived
/// from its length, and the two have to be changed together.
const String _hint = 'Search projects, genomes, SNP';

/// Search, in the app bar, on every tab.
///
/// ⚠️ **A field rather than only an icon, and that is the entire point of this
/// widget.** It started as a bare `IconButton` with the shortcut in its tooltip,
/// which is discoverable only by somebody who already suspects search exists and
/// hovers to check. A visible field says the feature is there, says what it
/// searches, and shows the shortcut — so nobody has to be told about `Ctrl+K` to
/// find it, and anybody who uses it twice learns the shortcut for free.
///
/// It is deliberately **not** a real `TextField`. Tapping it opens
/// [SearchDialog], which has the actual input, the results and the keyboard
/// handling. Two live fields would mean transferring focus and the half-typed
/// query between them on the first keystroke, for no gain — the palette pattern
/// every editor and issue tracker uses avoids that entirely.
///
/// Lives in its own file under `lib/` rather than inside `main.dart` because
/// `test/platform_boundary_test.dart` forbids anything under `lib/` importing
/// `main.dart`. The app bar's other action, `SignedInMenu`, was written into
/// `main.dart` and shipped a label that overflowed the bar for exactly as long,
/// because nothing there can be pumped in a test.
class SearchButton extends StatelessWidget {
  const SearchButton({super.key, this.controller, this.onOpen});

  /// The controller to hand the dialog, or null to let it build its own.
  final UnifiedSearchController? controller;

  /// What to do with the chosen hit, or null for the real navigation. A test
  /// passes this to observe where a hit would have gone.
  final void Function(SearchHitDto hit)? onOpen;

  @override
  Widget build(BuildContext context) {
    // ⚠️ `kSplitWidth`, not a threshold of its own. `layout.dart` calls it "the
    // only real breakpoint left in the app" and it is right to: a second number
    // 140px away from it is two answers to one question. Picking 700 first
    // produced a 12px overflow in a signed-in app bar, which is how this got
    // measured rather than guessed.
    //
    // `MediaQuery` is right here for the reason `DialogBody` gives: what matters
    // is how much window the app bar spans, not the constraints an action slot
    // passes down — which are the bar's height and an unbounded width.
    final room = MediaQuery.sizeOf(context).width >= kSplitWidth;
    if (!room) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _icon(context),
      );
    }
    // ⚠️ The [Flexible] has to be the value returned from `build`, not something
    // wrapped in the `Padding` below it. `AppBar` lays `actions` out in a `Row`,
    // and a `ParentDataWidget` only reaches its `Flex` when it is that `Flex`'s
    // direct child — with a `Padding` in between, Flutter throws "Incorrect use
    // of ParentDataWidget" instead of laying anything out. The padding therefore
    // moves inside.
    return Flexible(
      child: Padding(
        // 8 rather than 4: this is the gap to the account label on one side and,
        // with the theme's `actionsPadding`, to the window edge on the other. A
        // bordered field 4px from either reads as clipped.
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _field(context),
      ),
    );
  }

  Widget _icon(BuildContext context) => IconButton(
    icon: const Icon(Icons.search),
    tooltip: 'Search (Ctrl+K)',
    onPressed: () => open(context),
  );

  Widget _field(BuildContext context) {
    final colours = context.colours;
    // ⚠️ A width **range**, under the [Flexible] in `build`, and that is what
    // makes [_fieldMaxWidth] safe to set generously. The account menu next to
    // this carries an email address, so how much room is left over is not
    // something a constant can know — a *fixed* 300px overflowed the bar by 12px
    // for a signed-in user at the breakpoint. With a range the max is only ever a
    // preference: shrinking degrades the hint to an ellipsis, where overflowing
    // paints a yellow-and-black stripe across the app bar.
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: _fieldMaxWidth,
        minWidth: _fieldMinWidth,
        maxHeight: 40,
        minHeight: 40,
      ),
      child: Material(
        // Against the app bar rather than the page, so it reads as chrome. A
        // filled surface plus a hairline is what makes it look like a field
        // somebody can type into rather than a label.
        color: colours.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colours.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: colours.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: colours.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // The shortcut, shown rather than hidden in a tooltip. This is
                // the only place it is advertised at all.
                _ShortcutHint(colours: colours),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the dialog. Also the target of the `Ctrl+K` shortcut in `main.dart`.
  void open(BuildContext context) {
    // ⚠️ Captured here, at press time, and passed down as a callback. This
    // context sits under the `DefaultTabController` — that is how the `const
    // TabBar` in `AppBar.bottom` finds it too — but the *dialog's* context does
    // not: a dialog route is a child of the root `Navigator`, which is above the
    // controller. Looking the controller up inside the dialog throws.
    final tabs = DefaultTabController.of(context);
    showSearchDialog(
      context,
      controller: controller,
      onOpen: onOpen ?? (hit) => openSearchHit(hit, tabs.animateTo),
    );
  }
}

/// The `Ctrl K` chip inside the field.
class _ShortcutHint extends StatelessWidget {
  const _ShortcutHint({required this.colours});

  final ColorScheme colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colours.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colours.outlineVariant),
      ),
      child: Text(
        'Ctrl K',
        style: context.text.labelSmall?.copyWith(
          color: colours.onSurfaceVariant,
          // The app's monospace face, because this is a key name.
          fontFamily: context.mono.fontFamily,
        ),
      ),
    );
  }
}
