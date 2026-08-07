import 'dart:math' as math;

import 'package:flumip_flutter/ui/status_colors.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrast, checked once here instead of by eye at every call site.
///
/// This exists because the colours it replaces were genuinely hard to read:
/// `Colors.orange` was used as *body text* on a white surface in two places,
/// where it clears a ratio of about 2.1 — well under any threshold. Semantic
/// colour is the one thing not moving to `ColorScheme`, so it needs its own
/// guard.
void main() {
  /// WCAG relative luminance.
  double luminance(Color c) {
    double channel(double v) {
      v = v / 255.0;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(c.r * 255) +
        0.7152 * channel(c.g * 255) +
        0.0722 * channel(c.b * 255);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  const palette = StatusColors.light;

  group('text on its own container clears WCAG AA', () {
    // 4.5:1 is AA for normal text. The pills render at 11px, so this is the
    // right threshold rather than the 3:1 allowed for large text.
    final pairs = <String, (Color, Color)>{
      'success': (palette.onSuccessContainer, palette.successContainer),
      'warning': (palette.onWarningContainer, palette.warningContainer),
      'info': (palette.onInfoContainer, palette.infoContainer),
    };

    pairs.forEach((name, pair) {
      test(name, () {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '$name text is not legible on its own container',
        );
      });
    });
  });

  group('the base roles are legible on a light surface', () {
    // These are used as icon and text colours directly — a StatusPill draws its
    // label in the base colour over a 12%-alpha wash of it, which is very nearly
    // the surface.
    const surface = Color(0xFFFFFFFF);
    final roles = <String, Color>{
      'success': palette.success,
      'warning': palette.warning,
      'info': palette.info,
      'neutral': palette.neutral,
    };

    roles.forEach((name, colour) {
      test(name, () {
        expect(
          contrast(colour, surface),
          greaterThanOrEqualTo(4.5),
          reason: '$name is not legible as text on white',
        );
      });
    });
  });

  test('on-colours are legible on their solid roles', () {
    expect(contrast(palette.onSuccess, palette.success),
        greaterThanOrEqualTo(4.5));
    expect(contrast(palette.onWarning, palette.warning),
        greaterThanOrEqualTo(4.5));
  });

  test('the four states are told apart by hue, not just by brightness', () {
    // Contrast ratio is the wrong tool here — it is a luminance comparison, and
    // a green and an amber of similar darkness score near 1.0 while looking
    // nothing alike. Hue distance is what a reader actually uses. (Someone with
    // deuteranopia uses neither, which is why every pill also carries an icon.)
    double hue(Color c) => HSLColor.fromColor(c).hue;
    double apart(Color a, Color b) {
      final d = (hue(a) - hue(b)).abs();
      return d > 180 ? 360 - d : d;
    }

    expect(apart(palette.success, palette.warning), greaterThan(60));
    expect(apart(palette.success, palette.info), greaterThan(60));
    expect(apart(palette.warning, palette.info), greaterThan(60));
  });

  test('the theme registers the extension', () {
    // `context.status` falls back rather than throwing, so a missing
    // registration would be invisible until something looked wrong on screen.
    expect(buildAppTheme().extension<StatusColors>(), isNotNull);
  });
}
