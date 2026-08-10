import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_options_form.dart';
import 'package:flutter_test/flutter_test.dart';

/// The MIP design parameters, in and back out.
///
/// These 28 values decide what mipgen designs. Until now the load half and the
/// parse half were 50 lines apart in a `State` no test could reach, and they had
/// already drifted — see the first test.
void main() {
  late ProjectOptionsForm form;

  setUp(() => form = ProjectOptionsForm());
  tearDown(() => form.dispose());

  ProjectOptions serverDefaults() => ProjectOptions(
    minCaptureSize: 162,
    maxCaptureSize: 182,
    armLengthSums: '40,41,42,43,44,45',
    extMinLength: 16,
    extMaxLength: 18,
    ligMinLength: 18,
    tagSizes: '5,0',
    maskedArmThreshold: 0.5,
    targetArmCopy: 20,
    maxArmCopyProduct: 75,
    trf: true,
    featureFlank: 3,
    captureIncrement: 5,
    logisticHeuristic: true,
    maxMipOverlap: 30,
    startingMipOverlap: 1,
    checkCopyNumber: false,
    sealBothStrands: true,
    halfSealBothStrands: true,
    doubleTileStrandUnaware: true,
    doubleTileStrandsSeparately: true,
    scoreMethod: ScoreMethod.svr,
    logisticOptimalScore: 0.98,
    svrOptimalScore: 2.2,
    logisticPriorityScore: 0.9,
    svrPriorityScore: 1.5,
  );

  test('⚠️ ext max length survives the round trip', () {
    // The bug this file was written for. The parse read the *min* controller for
    // extMaxLength, so whatever was typed into "Ext max length" was discarded
    // and the min value sent twice — a silently different design, with nothing
    // anywhere reporting it.
    form.load(serverDefaults());
    form.extMinLength.text = '16';
    form.extMaxLength.text = '24';

    final options = form.toOptions();
    expect(options.extMinLength, 16);
    expect(options.extMaxLength, 24);
  });

  test('everything loaded comes back out unchanged', () {
    final defaults = serverDefaults();
    form.load(defaults);

    final round = form.toOptions();
    expect(round.minCaptureSize, defaults.minCaptureSize);
    expect(round.maxCaptureSize, defaults.maxCaptureSize);
    expect(round.armLengthSums, defaults.armLengthSums);
    expect(round.extMinLength, defaults.extMinLength);
    expect(round.extMaxLength, defaults.extMaxLength);
    expect(round.ligMinLength, defaults.ligMinLength);
    expect(round.tagSizes, defaults.tagSizes);
    expect(round.maskedArmThreshold, defaults.maskedArmThreshold);
    expect(round.targetArmCopy, defaults.targetArmCopy);
    expect(round.maxArmCopyProduct, defaults.maxArmCopyProduct);
    expect(round.featureFlank, defaults.featureFlank);
    expect(round.captureIncrement, defaults.captureIncrement);
    expect(round.maxMipOverlap, defaults.maxMipOverlap);
    expect(round.startingMipOverlap, defaults.startingMipOverlap);
    expect(round.logisticOptimalScore, defaults.logisticOptimalScore);
    expect(round.svrOptimalScore, defaults.svrOptimalScore);
    expect(round.logisticPriorityScore, defaults.logisticPriorityScore);
    expect(round.svrPriorityScore, defaults.svrPriorityScore);
  });

  test('every switch and the score method survive too', () {
    form.load(serverDefaults());
    final round = form.toOptions();

    expect(round.trf, isTrue);
    expect(round.logisticHeuristic, isTrue);
    expect(round.checkCopyNumber, isFalse);
    expect(round.sealBothStrands, isTrue);
    expect(round.halfSealBothStrands, isTrue);
    expect(round.doubleTileStrandUnaware, isTrue);
    expect(round.doubleTileStrandsSeparately, isTrue);
    expect(round.scoreMethod, ScoreMethod.svr);
  });

  test('⚠️ arm lengths are left empty rather than showing "null"', () {
    // It is the one optional parameter, and the server's default for it is null.
    form.load(serverDefaults());
    expect(form.armLengths.text, isEmpty);
    expect(form.toOptions().armLengths, isEmpty);
  });

  test('an arm length that is typed is kept', () {
    form.load(serverDefaults());
    form.armLengths.text = '16:24,16:25';
    expect(form.toOptions().armLengths, '16:24,16:25');
  });

  group('an emptied box falls back to the model default', () {
    // Only reachable by clearing a field — they accept digits only — but a
    // fallback that disagreed with the server would design against a parameter
    // nobody chose.
    test('integers', () {
      final blank = ProjectOptionsForm();
      addTearDown(blank.dispose);

      final options = blank.toOptions();
      expect(options.minCaptureSize, 162);
      expect(options.maxCaptureSize, 162);
      expect(options.extMinLength, 16);
      expect(options.extMaxLength, 18);
      expect(options.ligMinLength, 18);
      expect(options.targetArmCopy, 20);
      expect(options.maxArmCopyProduct, 75);
      expect(options.featureFlank, 0);
      expect(options.captureIncrement, 5);
      expect(options.maxMipOverlap, 30);
      expect(options.startingMipOverlap, 0);
    });

    test('decimals', () {
      final blank = ProjectOptionsForm();
      addTearDown(blank.dispose);

      final options = blank.toOptions();
      expect(options.maskedArmThreshold, 0.5);
      expect(options.logisticOptimalScore, 0.98);
      expect(options.svrOptimalScore, 2.2);
      expect(options.logisticPriorityScore, 0.9);
      expect(options.svrPriorityScore, 1.5);
    });

    test('and matches what the server itself would have used', () {
      // If a default here drifts from the model, this is what says so.
      final blank = ProjectOptionsForm();
      addTearDown(blank.dispose);
      final model = ProjectOptions();
      final parsed = blank.toOptions();

      expect(parsed.minCaptureSize, model.minCaptureSize);
      expect(parsed.extMinLength, model.extMinLength);
      expect(parsed.extMaxLength, model.extMaxLength);
      expect(parsed.ligMinLength, model.ligMinLength);
      expect(parsed.maskedArmThreshold, model.maskedArmThreshold);
      expect(parsed.targetArmCopy, model.targetArmCopy);
      expect(parsed.maxArmCopyProduct, model.maxArmCopyProduct);
      expect(parsed.captureIncrement, model.captureIncrement);
      expect(parsed.maxMipOverlap, model.maxMipOverlap);
      expect(parsed.logisticOptimalScore, model.logisticOptimalScore);
      expect(parsed.svrOptimalScore, model.svrOptimalScore);
      expect(parsed.logisticPriorityScore, model.logisticPriorityScore);
      expect(parsed.svrPriorityScore, model.svrPriorityScore);
      expect(parsed.scoreMethod, model.scoreMethod);
      expect(parsed.checkCopyNumber, model.checkCopyNumber);
    });
  });
}
