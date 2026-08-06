import 'package:flutter/material.dart';

import 'status_colors.dart';

/// The seed the whole colour scheme is derived from.
///
/// Blue, because the app has always meant to be blue: the accent icons, the
/// selection tints and the link colours were all written as `Colors.blue`.
///
/// ⚠️ **What it looked like before was not blue.** The only theme in the app was
/// `ThemeData(primarySwatch: Colors.blue)`, and under Material 3 — on by default
/// since Flutter 3.16 — `primarySwatch` does not feed the colour scheme at all.
/// `ThemeData`'s constructor does `colorScheme ??= _colorSchemeLightM3`, whose
/// primary is `0xFF6750A4`: Material's baseline **purple**. So the app bar, tab
/// indicator, buttons and checkboxes rendered purple while every hand-written
/// accent was blue. Nobody chose that; it is what this file exists to end.
const Color seedColour = Color(0xFF1565C0); // Blue 800

/// The one theme for the app.
///
/// Everything visual should be reachable from here. A `Colors.something` written
/// inside a widget is a bug in waiting: it cannot respond to the scheme, it
/// cannot be checked for contrast, and it drifts from its neighbours the moment
/// somebody copies the widget.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: seedColour);

  return ThemeData(
    colorScheme: scheme,

    // ⚠️ Not a tightening. `ThemeData` already resolves this to `compact` on a
    // desktop browser, because `defaultDensityForPlatform` returns compact for
    // linux, macOS and windows. It is pinned here so the app stops *depending*
    // on that: a browser whose operating system Flutter does not recognise falls
    // back to `android`, i.e. `standard`, and so does `flutter test` — which
    // would make any size assertion written later disagree with production.
    visualDensity: VisualDensity.compact,

    // The highest-leverage entry in this file by a distance: 53 `TextField`s.
    // The underline default plus tight spacing is most of why the settings form
    // reads as a wall of text rather than a set of fields.
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(),
      isDense: true,
      // Fields that need more say so on the instance; this is the floor, not a
      // cap, and it stops a two-line helper from resizing its neighbour.
      helperMaxLines: 3,
    ),

    // Lets the selectable cards in the genome tab express selection as colour
    // alone, instead of each hand-rolling elevation, radius and border.
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),

    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),

    // Floating, so a snack bar never covers the sticky save bar in settings.
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // No `chipTheme`: there is not one Material `Chip` in the app. Every chip is
    // `StatusPill`, which is deliberately smaller than Material's — see
    // `ui/status_pill.dart`.

    // No `textTheme` override either. M3's Typography.material2021 is fine, and
    // a hand-edited TextTheme is a liability. The one real gap is monospace,
    // which is `context.mono` below.
    extensions: const [StatusColors.light],
  );
}

/// Theme lookups that would otherwise be written with a `!` at every call site.
extension ThemeAccess on BuildContext {
  ColorScheme get colours => Theme.of(this).colorScheme;

  TextTheme get text => Theme.of(this).textTheme;

  /// The semantic roles Material 3 does not define. See [StatusColors].
  ///
  /// Non-null by construction: [buildAppTheme] always registers the extension.
  /// A widget pumped in a test under a bare `MaterialApp` would not have it, so
  /// this falls back rather than throwing — a missing accent colour is not worth
  /// failing a test that is checking something else.
  StatusColors get status =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;

  /// For paths, URIs and anything else where the characters matter one by one.
  ///
  /// A redirect URI or an `/opt/flumip/...` path is read to be compared, not to
  /// be scanned, and proportional digits and a proportional `l`/`1` make that
  /// harder than it needs to be.
  TextStyle get mono =>
      (text.bodyMedium ?? const TextStyle()).copyWith(fontFamily: 'monospace');
}
