/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'score_method.dart' as _i2;

abstract class ProjectOptions implements _i1.SerializableModel {
  ProjectOptions._({
    this.id,
    int? minCaptureSize,
    int? maxCaptureSize,
    this.armLengths,
    String? armLengthSums,
    int? extMinLength,
    int? extMaxLength,
    int? ligMinLength,
    String? tagSizes,
    double? maskedArmThreshold,
    int? targetArmCopy,
    int? maxArmCopyProduct,
    bool? trf,
    this.genomeDir,
    int? featureFlank,
    int? captureIncrement,
    bool? logisticHeuristic,
    int? maxMipOverlap,
    int? startingMipOverlap,
    bool? checkCopyNumber,
    bool? sealBothStrands,
    bool? halfSealBothStrands,
    bool? doubleTileStrandUnaware,
    bool? doubleTileStrandsSeparately,
    _i2.ScoreMethod? scoreMethod,
    double? logisticOptimalScore,
    double? svrOptimalScore,
    double? logisticPriorityScore,
    double? svrPriorityScore,
    bool? silentMode,
    int? bwaThreads,
  }) : minCaptureSize = minCaptureSize ?? 162,
       maxCaptureSize = maxCaptureSize ?? 162,
       armLengthSums = armLengthSums ?? '40,41,42,43,44,45',
       extMinLength = extMinLength ?? 16,
       extMaxLength = extMaxLength ?? 18,
       ligMinLength = ligMinLength ?? 18,
       tagSizes = tagSizes ?? '5,0',
       maskedArmThreshold = maskedArmThreshold ?? 0.5,
       targetArmCopy = targetArmCopy ?? 20,
       maxArmCopyProduct = maxArmCopyProduct ?? 75,
       trf = trf ?? false,
       featureFlank = featureFlank ?? 0,
       captureIncrement = captureIncrement ?? 5,
       logisticHeuristic = logisticHeuristic ?? false,
       maxMipOverlap = maxMipOverlap ?? 30,
       startingMipOverlap = startingMipOverlap ?? 0,
       checkCopyNumber = checkCopyNumber ?? true,
       sealBothStrands = sealBothStrands ?? false,
       halfSealBothStrands = halfSealBothStrands ?? false,
       doubleTileStrandUnaware = doubleTileStrandUnaware ?? false,
       doubleTileStrandsSeparately = doubleTileStrandsSeparately ?? false,
       scoreMethod = scoreMethod ?? _i2.ScoreMethod.logistic,
       logisticOptimalScore = logisticOptimalScore ?? 0.98,
       svrOptimalScore = svrOptimalScore ?? 2.2,
       logisticPriorityScore = logisticPriorityScore ?? 0.9,
       svrPriorityScore = svrPriorityScore ?? 1.5,
       silentMode = silentMode ?? false,
       bwaThreads = bwaThreads ?? 1;

  factory ProjectOptions({
    int? id,
    int? minCaptureSize,
    int? maxCaptureSize,
    String? armLengths,
    String? armLengthSums,
    int? extMinLength,
    int? extMaxLength,
    int? ligMinLength,
    String? tagSizes,
    double? maskedArmThreshold,
    int? targetArmCopy,
    int? maxArmCopyProduct,
    bool? trf,
    String? genomeDir,
    int? featureFlank,
    int? captureIncrement,
    bool? logisticHeuristic,
    int? maxMipOverlap,
    int? startingMipOverlap,
    bool? checkCopyNumber,
    bool? sealBothStrands,
    bool? halfSealBothStrands,
    bool? doubleTileStrandUnaware,
    bool? doubleTileStrandsSeparately,
    _i2.ScoreMethod? scoreMethod,
    double? logisticOptimalScore,
    double? svrOptimalScore,
    double? logisticPriorityScore,
    double? svrPriorityScore,
    bool? silentMode,
    int? bwaThreads,
  }) = _ProjectOptionsImpl;

  factory ProjectOptions.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectOptions(
      id: jsonSerialization['id'] as int?,
      minCaptureSize: jsonSerialization['minCaptureSize'] as int?,
      maxCaptureSize: jsonSerialization['maxCaptureSize'] as int?,
      armLengths: jsonSerialization['armLengths'] as String?,
      armLengthSums: jsonSerialization['armLengthSums'] as String?,
      extMinLength: jsonSerialization['extMinLength'] as int?,
      extMaxLength: jsonSerialization['extMaxLength'] as int?,
      ligMinLength: jsonSerialization['ligMinLength'] as int?,
      tagSizes: jsonSerialization['tagSizes'] as String?,
      maskedArmThreshold: (jsonSerialization['maskedArmThreshold'] as num?)
          ?.toDouble(),
      targetArmCopy: jsonSerialization['targetArmCopy'] as int?,
      maxArmCopyProduct: jsonSerialization['maxArmCopyProduct'] as int?,
      trf: jsonSerialization['trf'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['trf']),
      genomeDir: jsonSerialization['genomeDir'] as String?,
      featureFlank: jsonSerialization['featureFlank'] as int?,
      captureIncrement: jsonSerialization['captureIncrement'] as int?,
      logisticHeuristic: jsonSerialization['logisticHeuristic'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['logisticHeuristic'],
            ),
      maxMipOverlap: jsonSerialization['maxMipOverlap'] as int?,
      startingMipOverlap: jsonSerialization['startingMipOverlap'] as int?,
      checkCopyNumber: jsonSerialization['checkCopyNumber'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['checkCopyNumber'],
            ),
      sealBothStrands: jsonSerialization['sealBothStrands'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['sealBothStrands'],
            ),
      halfSealBothStrands: jsonSerialization['halfSealBothStrands'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['halfSealBothStrands'],
            ),
      doubleTileStrandUnaware:
          jsonSerialization['doubleTileStrandUnaware'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['doubleTileStrandUnaware'],
            ),
      doubleTileStrandsSeparately:
          jsonSerialization['doubleTileStrandsSeparately'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['doubleTileStrandsSeparately'],
            ),
      scoreMethod: jsonSerialization['scoreMethod'] == null
          ? null
          : _i2.ScoreMethod.fromJson(
              (jsonSerialization['scoreMethod'] as String),
            ),
      logisticOptimalScore: (jsonSerialization['logisticOptimalScore'] as num?)
          ?.toDouble(),
      svrOptimalScore: (jsonSerialization['svrOptimalScore'] as num?)
          ?.toDouble(),
      logisticPriorityScore:
          (jsonSerialization['logisticPriorityScore'] as num?)?.toDouble(),
      svrPriorityScore: (jsonSerialization['svrPriorityScore'] as num?)
          ?.toDouble(),
      silentMode: jsonSerialization['silentMode'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['silentMode']),
      bwaThreads: jsonSerialization['bwaThreads'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int minCaptureSize;

  int maxCaptureSize;

  String? armLengths;

  String armLengthSums;

  int extMinLength;

  int extMaxLength;

  int ligMinLength;

  String tagSizes;

  double maskedArmThreshold;

  int targetArmCopy;

  int maxArmCopyProduct;

  bool trf;

  String? genomeDir;

  int featureFlank;

  int captureIncrement;

  bool logisticHeuristic;

  int maxMipOverlap;

  int startingMipOverlap;

  bool checkCopyNumber;

  bool sealBothStrands;

  bool halfSealBothStrands;

  bool doubleTileStrandUnaware;

  bool doubleTileStrandsSeparately;

  _i2.ScoreMethod scoreMethod;

  double logisticOptimalScore;

  double svrOptimalScore;

  double logisticPriorityScore;

  double svrPriorityScore;

  bool silentMode;

  int bwaThreads;

  /// Returns a shallow copy of this [ProjectOptions]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProjectOptions copyWith({
    int? id,
    int? minCaptureSize,
    int? maxCaptureSize,
    String? armLengths,
    String? armLengthSums,
    int? extMinLength,
    int? extMaxLength,
    int? ligMinLength,
    String? tagSizes,
    double? maskedArmThreshold,
    int? targetArmCopy,
    int? maxArmCopyProduct,
    bool? trf,
    String? genomeDir,
    int? featureFlank,
    int? captureIncrement,
    bool? logisticHeuristic,
    int? maxMipOverlap,
    int? startingMipOverlap,
    bool? checkCopyNumber,
    bool? sealBothStrands,
    bool? halfSealBothStrands,
    bool? doubleTileStrandUnaware,
    bool? doubleTileStrandsSeparately,
    _i2.ScoreMethod? scoreMethod,
    double? logisticOptimalScore,
    double? svrOptimalScore,
    double? logisticPriorityScore,
    double? svrPriorityScore,
    bool? silentMode,
    int? bwaThreads,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectOptions',
      if (id != null) 'id': id,
      'minCaptureSize': minCaptureSize,
      'maxCaptureSize': maxCaptureSize,
      if (armLengths != null) 'armLengths': armLengths,
      'armLengthSums': armLengthSums,
      'extMinLength': extMinLength,
      'extMaxLength': extMaxLength,
      'ligMinLength': ligMinLength,
      'tagSizes': tagSizes,
      'maskedArmThreshold': maskedArmThreshold,
      'targetArmCopy': targetArmCopy,
      'maxArmCopyProduct': maxArmCopyProduct,
      'trf': trf,
      if (genomeDir != null) 'genomeDir': genomeDir,
      'featureFlank': featureFlank,
      'captureIncrement': captureIncrement,
      'logisticHeuristic': logisticHeuristic,
      'maxMipOverlap': maxMipOverlap,
      'startingMipOverlap': startingMipOverlap,
      'checkCopyNumber': checkCopyNumber,
      'sealBothStrands': sealBothStrands,
      'halfSealBothStrands': halfSealBothStrands,
      'doubleTileStrandUnaware': doubleTileStrandUnaware,
      'doubleTileStrandsSeparately': doubleTileStrandsSeparately,
      'scoreMethod': scoreMethod.toJson(),
      'logisticOptimalScore': logisticOptimalScore,
      'svrOptimalScore': svrOptimalScore,
      'logisticPriorityScore': logisticPriorityScore,
      'svrPriorityScore': svrPriorityScore,
      'silentMode': silentMode,
      'bwaThreads': bwaThreads,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectOptionsImpl extends ProjectOptions {
  _ProjectOptionsImpl({
    int? id,
    int? minCaptureSize,
    int? maxCaptureSize,
    String? armLengths,
    String? armLengthSums,
    int? extMinLength,
    int? extMaxLength,
    int? ligMinLength,
    String? tagSizes,
    double? maskedArmThreshold,
    int? targetArmCopy,
    int? maxArmCopyProduct,
    bool? trf,
    String? genomeDir,
    int? featureFlank,
    int? captureIncrement,
    bool? logisticHeuristic,
    int? maxMipOverlap,
    int? startingMipOverlap,
    bool? checkCopyNumber,
    bool? sealBothStrands,
    bool? halfSealBothStrands,
    bool? doubleTileStrandUnaware,
    bool? doubleTileStrandsSeparately,
    _i2.ScoreMethod? scoreMethod,
    double? logisticOptimalScore,
    double? svrOptimalScore,
    double? logisticPriorityScore,
    double? svrPriorityScore,
    bool? silentMode,
    int? bwaThreads,
  }) : super._(
         id: id,
         minCaptureSize: minCaptureSize,
         maxCaptureSize: maxCaptureSize,
         armLengths: armLengths,
         armLengthSums: armLengthSums,
         extMinLength: extMinLength,
         extMaxLength: extMaxLength,
         ligMinLength: ligMinLength,
         tagSizes: tagSizes,
         maskedArmThreshold: maskedArmThreshold,
         targetArmCopy: targetArmCopy,
         maxArmCopyProduct: maxArmCopyProduct,
         trf: trf,
         genomeDir: genomeDir,
         featureFlank: featureFlank,
         captureIncrement: captureIncrement,
         logisticHeuristic: logisticHeuristic,
         maxMipOverlap: maxMipOverlap,
         startingMipOverlap: startingMipOverlap,
         checkCopyNumber: checkCopyNumber,
         sealBothStrands: sealBothStrands,
         halfSealBothStrands: halfSealBothStrands,
         doubleTileStrandUnaware: doubleTileStrandUnaware,
         doubleTileStrandsSeparately: doubleTileStrandsSeparately,
         scoreMethod: scoreMethod,
         logisticOptimalScore: logisticOptimalScore,
         svrOptimalScore: svrOptimalScore,
         logisticPriorityScore: logisticPriorityScore,
         svrPriorityScore: svrPriorityScore,
         silentMode: silentMode,
         bwaThreads: bwaThreads,
       );

  /// Returns a shallow copy of this [ProjectOptions]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProjectOptions copyWith({
    Object? id = _Undefined,
    int? minCaptureSize,
    int? maxCaptureSize,
    Object? armLengths = _Undefined,
    String? armLengthSums,
    int? extMinLength,
    int? extMaxLength,
    int? ligMinLength,
    String? tagSizes,
    double? maskedArmThreshold,
    int? targetArmCopy,
    int? maxArmCopyProduct,
    bool? trf,
    Object? genomeDir = _Undefined,
    int? featureFlank,
    int? captureIncrement,
    bool? logisticHeuristic,
    int? maxMipOverlap,
    int? startingMipOverlap,
    bool? checkCopyNumber,
    bool? sealBothStrands,
    bool? halfSealBothStrands,
    bool? doubleTileStrandUnaware,
    bool? doubleTileStrandsSeparately,
    _i2.ScoreMethod? scoreMethod,
    double? logisticOptimalScore,
    double? svrOptimalScore,
    double? logisticPriorityScore,
    double? svrPriorityScore,
    bool? silentMode,
    int? bwaThreads,
  }) {
    return ProjectOptions(
      id: id is int? ? id : this.id,
      minCaptureSize: minCaptureSize ?? this.minCaptureSize,
      maxCaptureSize: maxCaptureSize ?? this.maxCaptureSize,
      armLengths: armLengths is String? ? armLengths : this.armLengths,
      armLengthSums: armLengthSums ?? this.armLengthSums,
      extMinLength: extMinLength ?? this.extMinLength,
      extMaxLength: extMaxLength ?? this.extMaxLength,
      ligMinLength: ligMinLength ?? this.ligMinLength,
      tagSizes: tagSizes ?? this.tagSizes,
      maskedArmThreshold: maskedArmThreshold ?? this.maskedArmThreshold,
      targetArmCopy: targetArmCopy ?? this.targetArmCopy,
      maxArmCopyProduct: maxArmCopyProduct ?? this.maxArmCopyProduct,
      trf: trf ?? this.trf,
      genomeDir: genomeDir is String? ? genomeDir : this.genomeDir,
      featureFlank: featureFlank ?? this.featureFlank,
      captureIncrement: captureIncrement ?? this.captureIncrement,
      logisticHeuristic: logisticHeuristic ?? this.logisticHeuristic,
      maxMipOverlap: maxMipOverlap ?? this.maxMipOverlap,
      startingMipOverlap: startingMipOverlap ?? this.startingMipOverlap,
      checkCopyNumber: checkCopyNumber ?? this.checkCopyNumber,
      sealBothStrands: sealBothStrands ?? this.sealBothStrands,
      halfSealBothStrands: halfSealBothStrands ?? this.halfSealBothStrands,
      doubleTileStrandUnaware:
          doubleTileStrandUnaware ?? this.doubleTileStrandUnaware,
      doubleTileStrandsSeparately:
          doubleTileStrandsSeparately ?? this.doubleTileStrandsSeparately,
      scoreMethod: scoreMethod ?? this.scoreMethod,
      logisticOptimalScore: logisticOptimalScore ?? this.logisticOptimalScore,
      svrOptimalScore: svrOptimalScore ?? this.svrOptimalScore,
      logisticPriorityScore:
          logisticPriorityScore ?? this.logisticPriorityScore,
      svrPriorityScore: svrPriorityScore ?? this.svrPriorityScore,
      silentMode: silentMode ?? this.silentMode,
      bwaThreads: bwaThreads ?? this.bwaThreads,
    );
  }
}
