import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

/// The 28 MIP design parameters, as editable text.
///
/// A bundle rather than 28 fields on a `State`, for three reasons that were all
/// visible in the widget this came out of:
///
///  1. **Nothing disposed them.** `CreateProjectWidgetState` declared 24
///     `TextEditingController`s and had no `dispose` at all, so every time the
///     create form was opened and closed it left the lot behind. One `dispose`
///     here is one thing to remember instead of 24.
///  2. **The two halves could not be checked against each other.** Loading the
///     server's defaults in and parsing the user's answer back out were 50 lines
///     apart in a class no test can reach, and they had already drifted: the
///     `extMaxLength` parse read `_extMinLengthController`, so whatever was typed
///     into "Ext max length" was thrown away and the min value sent twice. See
///     the round-trip test.
///  3. Every parse carries a fallback, and a fallback that disagrees with the
///     server's own default is a silent wrong answer rather than an error.
///
/// Pure Dart plus `TextEditingController` — no client, no `BuildContext`.
class ProjectOptionsForm {
  final minCaptureSize = TextEditingController();
  final maxCaptureSize = TextEditingController();
  final armLengths = TextEditingController();
  final armLengthSums = TextEditingController();
  final extMinLength = TextEditingController();
  final extMaxLength = TextEditingController();
  final ligMinLength = TextEditingController();
  final tagSizes = TextEditingController();
  final maskedArmThreshold = TextEditingController();
  final targetArmCopy = TextEditingController();
  final maxArmCopyProduct = TextEditingController();
  final featureFlank = TextEditingController();
  final captureIncrement = TextEditingController();
  final maxMipOverlap = TextEditingController();
  final startingMipOverlap = TextEditingController();
  final logisticOptimalScore = TextEditingController();
  final svrOptimalScore = TextEditingController();
  final logisticPriorityScore = TextEditingController();
  final svrPriorityScore = TextEditingController();

  bool trf = false;
  bool logisticHeuristic = false;
  bool checkCopyNumber = true;
  bool sealBothStrands = false;
  bool halfSealBothStrands = false;
  bool doubleTileStrandUnaware = false;
  bool doubleTileStrandsSeparately = false;
  ScoreMethod scoreMethod = ScoreMethod.logistic;

  /// Fills the form from the server's defaults.
  ///
  /// ⚠️ [ProjectOptions.armLengths] is deliberately not loaded. It is the one
  /// optional parameter, the server's default for it is null, and rendering
  /// "null" into a text box is worse than an empty one.
  void load(ProjectOptions options) {
    minCaptureSize.text = '${options.minCaptureSize}';
    maxCaptureSize.text = '${options.maxCaptureSize}';
    armLengths.text = '';
    armLengthSums.text = options.armLengthSums;
    extMinLength.text = '${options.extMinLength}';
    extMaxLength.text = '${options.extMaxLength}';
    ligMinLength.text = '${options.ligMinLength}';
    tagSizes.text = options.tagSizes;
    maskedArmThreshold.text = '${options.maskedArmThreshold}';
    targetArmCopy.text = '${options.targetArmCopy}';
    maxArmCopyProduct.text = '${options.maxArmCopyProduct}';
    featureFlank.text = '${options.featureFlank}';
    captureIncrement.text = '${options.captureIncrement}';
    maxMipOverlap.text = '${options.maxMipOverlap}';
    startingMipOverlap.text = '${options.startingMipOverlap}';
    logisticOptimalScore.text = '${options.logisticOptimalScore}';
    svrOptimalScore.text = '${options.svrOptimalScore}';
    logisticPriorityScore.text = '${options.logisticPriorityScore}';
    svrPriorityScore.text = '${options.svrPriorityScore}';

    trf = options.trf;
    logisticHeuristic = options.logisticHeuristic;
    checkCopyNumber = options.checkCopyNumber;
    sealBothStrands = options.sealBothStrands;
    halfSealBothStrands = options.halfSealBothStrands;
    doubleTileStrandUnaware = options.doubleTileStrandUnaware;
    doubleTileStrandsSeparately = options.doubleTileStrandsSeparately;
    scoreMethod = options.scoreMethod;
  }

  /// What the form currently says, as the object the server stores.
  ///
  /// ⚠️ Every fallback here matches the model's own default. They are only ever
  /// reached by a box that has been emptied — the fields accept digits only — and
  /// a fallback that disagreed with the server would design against a parameter
  /// nobody chose and nothing reported.
  ProjectOptions toOptions() => ProjectOptions(
    minCaptureSize: int.tryParse(minCaptureSize.text) ?? 162,
    maxCaptureSize: int.tryParse(maxCaptureSize.text) ?? 162,
    armLengths: armLengths.text,
    armLengthSums: armLengthSums.text,
    extMinLength: int.tryParse(extMinLength.text) ?? 16,
    extMaxLength: int.tryParse(extMaxLength.text) ?? 18,
    ligMinLength: int.tryParse(ligMinLength.text) ?? 18,
    tagSizes: tagSizes.text,
    maskedArmThreshold: double.tryParse(maskedArmThreshold.text) ?? 0.5,
    targetArmCopy: int.tryParse(targetArmCopy.text) ?? 20,
    maxArmCopyProduct: int.tryParse(maxArmCopyProduct.text) ?? 75,
    trf: trf,
    featureFlank: int.tryParse(featureFlank.text) ?? 0,
    captureIncrement: int.tryParse(captureIncrement.text) ?? 5,
    logisticHeuristic: logisticHeuristic,
    maxMipOverlap: int.tryParse(maxMipOverlap.text) ?? 30,
    startingMipOverlap: int.tryParse(startingMipOverlap.text) ?? 0,
    checkCopyNumber: checkCopyNumber,
    sealBothStrands: sealBothStrands,
    halfSealBothStrands: halfSealBothStrands,
    doubleTileStrandUnaware: doubleTileStrandUnaware,
    doubleTileStrandsSeparately: doubleTileStrandsSeparately,
    scoreMethod: scoreMethod,
    logisticOptimalScore: double.tryParse(logisticOptimalScore.text) ?? 0.98,
    svrOptimalScore: double.tryParse(svrOptimalScore.text) ?? 2.2,
    logisticPriorityScore: double.tryParse(logisticPriorityScore.text) ?? 0.9,
    svrPriorityScore: double.tryParse(svrPriorityScore.text) ?? 1.5,
  );

  void dispose() {
    for (final controller in [
      minCaptureSize,
      maxCaptureSize,
      armLengths,
      armLengthSums,
      extMinLength,
      extMaxLength,
      ligMinLength,
      tagSizes,
      maskedArmThreshold,
      targetArmCopy,
      maxArmCopyProduct,
      featureFlank,
      captureIncrement,
      maxMipOverlap,
      startingMipOverlap,
      logisticOptimalScore,
      svrOptimalScore,
      logisticPriorityScore,
      svrPriorityScore,
    ]) {
      controller.dispose();
    }
  }
}
