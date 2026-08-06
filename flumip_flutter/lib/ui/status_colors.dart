import 'package:flutter/material.dart';

/// The colour roles Material 3 does not have.
///
/// M3 ships `error`/`onError`/`errorContainer` and nothing else semantic. This
/// app needs more than that: an SNP set is queued, downloading, indexing, ready
/// or failed, and a genome is indexed, indexing or not indexed. Five states have
/// to be distinguishable at a glance, so "success" and "warning" have to come
/// from somewhere.
///
/// They used to come from `Colors.green` and `Colors.orange` written at each
/// call site — which is why the same orange appeared both as a chip fill and as
/// body text on white, where it is barely legible. Putting them here makes them
/// one decision, checked once.
///
/// ⚠️ Deliberately const-constructible and free of `BuildContext`. `statusColour`
/// in `snp/snp_status.dart` takes one of these rather than a context, which is
/// what keeps that file testable on the Dart VM — where every test in this app
/// runs.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.neutral,
  });

  /// Finished, and finished well: an indexed genome, a ready SNP set.
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Working, or worth a second look: indexing, sign-in configured but not
  /// enforced.
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// In flight and unremarkable: a download running normally.
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  /// Nothing has happened yet — queued.
  final Color neutral;

  /// Tuned for legibility on a light surface rather than for vividness.
  ///
  /// The `on*` values are the text colour to use *on* the matching container,
  /// and are dark enough to clear WCAG AA at the 11px the status pills use.
  /// `test/ui/status_colors_test.dart` holds that line.
  static const light = StatusColors(
    success: Color(0xFF1B7B3A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFD7F0DE),
    onSuccessContainer: Color(0xFF0A4520),
    warning: Color(0xFF8A5300),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFDE7C7),
    onWarningContainer: Color(0xFF4A2C00),
    info: Color(0xFF1565C0),
    infoContainer: Color(0xFFD9E7F8),
    onInfoContainer: Color(0xFF0B3D75),
    neutral: Color(0xFF5F6368),
  );

  @override
  StatusColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? neutral,
  }) {
    return StatusColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}
