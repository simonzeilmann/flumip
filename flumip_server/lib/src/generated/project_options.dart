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
import 'package:serverpod/serverpod.dart' as _is;
import 'score_method.dart' as _iootg8bv;

abstract class ProjectOptions
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    _iootg8bv.ScoreMethod? scoreMethod,
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
       scoreMethod = scoreMethod ?? _iootg8bv.ScoreMethod.logistic,
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
    _iootg8bv.ScoreMethod? scoreMethod,
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
          : _is.BoolJsonExtension.fromJson(jsonSerialization['trf']),
      genomeDir: jsonSerialization['genomeDir'] as String?,
      featureFlank: jsonSerialization['featureFlank'] as int?,
      captureIncrement: jsonSerialization['captureIncrement'] as int?,
      logisticHeuristic: jsonSerialization['logisticHeuristic'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['logisticHeuristic'],
            ),
      maxMipOverlap: jsonSerialization['maxMipOverlap'] as int?,
      startingMipOverlap: jsonSerialization['startingMipOverlap'] as int?,
      checkCopyNumber: jsonSerialization['checkCopyNumber'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['checkCopyNumber'],
            ),
      sealBothStrands: jsonSerialization['sealBothStrands'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['sealBothStrands'],
            ),
      halfSealBothStrands: jsonSerialization['halfSealBothStrands'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['halfSealBothStrands'],
            ),
      doubleTileStrandUnaware:
          jsonSerialization['doubleTileStrandUnaware'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['doubleTileStrandUnaware'],
            ),
      doubleTileStrandsSeparately:
          jsonSerialization['doubleTileStrandsSeparately'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['doubleTileStrandsSeparately'],
            ),
      scoreMethod: jsonSerialization['scoreMethod'] == null
          ? null
          : _iootg8bv.ScoreMethod.fromJson(
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
          : _is.BoolJsonExtension.fromJson(jsonSerialization['silentMode']),
      bwaThreads: jsonSerialization['bwaThreads'] as int?,
    );
  }

  static final t = ProjectOptionsTable();

  static const db = ProjectOptionsRepository._();

  @override
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

  _iootg8bv.ScoreMethod scoreMethod;

  double logisticOptimalScore;

  double svrOptimalScore;

  double logisticPriorityScore;

  double svrPriorityScore;

  bool silentMode;

  int bwaThreads;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ProjectOptions]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    _iootg8bv.ScoreMethod? scoreMethod,
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
  Map<String, dynamic> toJsonForProtocol() {
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

  static ProjectOptionsInclude include() {
    return ProjectOptionsInclude._();
  }

  static ProjectOptionsIncludeList includeList({
    _is.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    ProjectOptionsInclude? include,
  }) {
    return ProjectOptionsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    _iootg8bv.ScoreMethod? scoreMethod,
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
  @_is.useResult
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
    _iootg8bv.ScoreMethod? scoreMethod,
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

class ProjectOptionsUpdateTable extends _is.UpdateTable<ProjectOptionsTable> {
  ProjectOptionsUpdateTable(super.table);

  _is.ColumnValue<int, int> minCaptureSize(int value) =>
      _is.ColumnValue(table.minCaptureSize, value);

  _is.ColumnValue<int, int> maxCaptureSize(int value) =>
      _is.ColumnValue(table.maxCaptureSize, value);

  _is.ColumnValue<String, String> armLengths(String? value) =>
      _is.ColumnValue(table.armLengths, value);

  _is.ColumnValue<String, String> armLengthSums(String value) =>
      _is.ColumnValue(table.armLengthSums, value);

  _is.ColumnValue<int, int> extMinLength(int value) =>
      _is.ColumnValue(table.extMinLength, value);

  _is.ColumnValue<int, int> extMaxLength(int value) =>
      _is.ColumnValue(table.extMaxLength, value);

  _is.ColumnValue<int, int> ligMinLength(int value) =>
      _is.ColumnValue(table.ligMinLength, value);

  _is.ColumnValue<String, String> tagSizes(String value) =>
      _is.ColumnValue(table.tagSizes, value);

  _is.ColumnValue<double, double> maskedArmThreshold(double value) =>
      _is.ColumnValue(table.maskedArmThreshold, value);

  _is.ColumnValue<int, int> targetArmCopy(int value) =>
      _is.ColumnValue(table.targetArmCopy, value);

  _is.ColumnValue<int, int> maxArmCopyProduct(int value) =>
      _is.ColumnValue(table.maxArmCopyProduct, value);

  _is.ColumnValue<bool, bool> trf(bool value) =>
      _is.ColumnValue(table.trf, value);

  _is.ColumnValue<String, String> genomeDir(String? value) =>
      _is.ColumnValue(table.genomeDir, value);

  _is.ColumnValue<int, int> featureFlank(int value) =>
      _is.ColumnValue(table.featureFlank, value);

  _is.ColumnValue<int, int> captureIncrement(int value) =>
      _is.ColumnValue(table.captureIncrement, value);

  _is.ColumnValue<bool, bool> logisticHeuristic(bool value) =>
      _is.ColumnValue(table.logisticHeuristic, value);

  _is.ColumnValue<int, int> maxMipOverlap(int value) =>
      _is.ColumnValue(table.maxMipOverlap, value);

  _is.ColumnValue<int, int> startingMipOverlap(int value) =>
      _is.ColumnValue(table.startingMipOverlap, value);

  _is.ColumnValue<bool, bool> checkCopyNumber(bool value) =>
      _is.ColumnValue(table.checkCopyNumber, value);

  _is.ColumnValue<bool, bool> sealBothStrands(bool value) =>
      _is.ColumnValue(table.sealBothStrands, value);

  _is.ColumnValue<bool, bool> halfSealBothStrands(bool value) =>
      _is.ColumnValue(table.halfSealBothStrands, value);

  _is.ColumnValue<bool, bool> doubleTileStrandUnaware(bool value) =>
      _is.ColumnValue(table.doubleTileStrandUnaware, value);

  _is.ColumnValue<bool, bool> doubleTileStrandsSeparately(bool value) =>
      _is.ColumnValue(table.doubleTileStrandsSeparately, value);

  _is.ColumnValue<_iootg8bv.ScoreMethod, _iootg8bv.ScoreMethod> scoreMethod(
    _iootg8bv.ScoreMethod value,
  ) => _is.ColumnValue(table.scoreMethod, value);

  _is.ColumnValue<double, double> logisticOptimalScore(double value) =>
      _is.ColumnValue(table.logisticOptimalScore, value);

  _is.ColumnValue<double, double> svrOptimalScore(double value) =>
      _is.ColumnValue(table.svrOptimalScore, value);

  _is.ColumnValue<double, double> logisticPriorityScore(double value) =>
      _is.ColumnValue(table.logisticPriorityScore, value);

  _is.ColumnValue<double, double> svrPriorityScore(double value) =>
      _is.ColumnValue(table.svrPriorityScore, value);

  _is.ColumnValue<bool, bool> silentMode(bool value) =>
      _is.ColumnValue(table.silentMode, value);

  _is.ColumnValue<int, int> bwaThreads(int value) =>
      _is.ColumnValue(table.bwaThreads, value);
}

class ProjectOptionsTable extends _is.Table<int?> {
  ProjectOptionsTable({super.tableRelation})
    : super(tableName: 'project_options') {
    updateTable = ProjectOptionsUpdateTable(this);
    minCaptureSize = _is.ColumnInt('minCaptureSize', this, hasDefault: true);
    maxCaptureSize = _is.ColumnInt('maxCaptureSize', this, hasDefault: true);
    armLengths = _is.ColumnString('armLengths', this);
    armLengthSums = _is.ColumnString('armLengthSums', this, hasDefault: true);
    extMinLength = _is.ColumnInt('extMinLength', this, hasDefault: true);
    extMaxLength = _is.ColumnInt('extMaxLength', this, hasDefault: true);
    ligMinLength = _is.ColumnInt('ligMinLength', this, hasDefault: true);
    tagSizes = _is.ColumnString('tagSizes', this, hasDefault: true);
    maskedArmThreshold = _is.ColumnDouble(
      'maskedArmThreshold',
      this,
      hasDefault: true,
    );
    targetArmCopy = _is.ColumnInt('targetArmCopy', this, hasDefault: true);
    maxArmCopyProduct = _is.ColumnInt(
      'maxArmCopyProduct',
      this,
      hasDefault: true,
    );
    trf = _is.ColumnBool('trf', this, hasDefault: true);
    genomeDir = _is.ColumnString('genomeDir', this);
    featureFlank = _is.ColumnInt('featureFlank', this, hasDefault: true);
    captureIncrement = _is.ColumnInt(
      'captureIncrement',
      this,
      hasDefault: true,
    );
    logisticHeuristic = _is.ColumnBool(
      'logisticHeuristic',
      this,
      hasDefault: true,
    );
    maxMipOverlap = _is.ColumnInt('maxMipOverlap', this, hasDefault: true);
    startingMipOverlap = _is.ColumnInt(
      'startingMipOverlap',
      this,
      hasDefault: true,
    );
    checkCopyNumber = _is.ColumnBool('checkCopyNumber', this, hasDefault: true);
    sealBothStrands = _is.ColumnBool('sealBothStrands', this, hasDefault: true);
    halfSealBothStrands = _is.ColumnBool(
      'halfSealBothStrands',
      this,
      hasDefault: true,
    );
    doubleTileStrandUnaware = _is.ColumnBool(
      'doubleTileStrandUnaware',
      this,
      hasDefault: true,
    );
    doubleTileStrandsSeparately = _is.ColumnBool(
      'doubleTileStrandsSeparately',
      this,
      hasDefault: true,
    );
    scoreMethod = _is.ColumnEnum(
      'scoreMethod',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    logisticOptimalScore = _is.ColumnDouble(
      'logisticOptimalScore',
      this,
      hasDefault: true,
    );
    svrOptimalScore = _is.ColumnDouble(
      'svrOptimalScore',
      this,
      hasDefault: true,
    );
    logisticPriorityScore = _is.ColumnDouble(
      'logisticPriorityScore',
      this,
      hasDefault: true,
    );
    svrPriorityScore = _is.ColumnDouble(
      'svrPriorityScore',
      this,
      hasDefault: true,
    );
    silentMode = _is.ColumnBool('silentMode', this, hasDefault: true);
    bwaThreads = _is.ColumnInt('bwaThreads', this, hasDefault: true);
  }

  late final ProjectOptionsUpdateTable updateTable;

  late final _is.ColumnInt minCaptureSize;

  late final _is.ColumnInt maxCaptureSize;

  late final _is.ColumnString armLengths;

  late final _is.ColumnString armLengthSums;

  late final _is.ColumnInt extMinLength;

  late final _is.ColumnInt extMaxLength;

  late final _is.ColumnInt ligMinLength;

  late final _is.ColumnString tagSizes;

  late final _is.ColumnDouble maskedArmThreshold;

  late final _is.ColumnInt targetArmCopy;

  late final _is.ColumnInt maxArmCopyProduct;

  late final _is.ColumnBool trf;

  late final _is.ColumnString genomeDir;

  late final _is.ColumnInt featureFlank;

  late final _is.ColumnInt captureIncrement;

  late final _is.ColumnBool logisticHeuristic;

  late final _is.ColumnInt maxMipOverlap;

  late final _is.ColumnInt startingMipOverlap;

  late final _is.ColumnBool checkCopyNumber;

  late final _is.ColumnBool sealBothStrands;

  late final _is.ColumnBool halfSealBothStrands;

  late final _is.ColumnBool doubleTileStrandUnaware;

  late final _is.ColumnBool doubleTileStrandsSeparately;

  late final _is.ColumnEnum<_iootg8bv.ScoreMethod> scoreMethod;

  late final _is.ColumnDouble logisticOptimalScore;

  late final _is.ColumnDouble svrOptimalScore;

  late final _is.ColumnDouble logisticPriorityScore;

  late final _is.ColumnDouble svrPriorityScore;

  late final _is.ColumnBool silentMode;

  late final _is.ColumnInt bwaThreads;

  @override
  List<_is.Column> get columns => [
    id,
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
    trf,
    genomeDir,
    featureFlank,
    captureIncrement,
    logisticHeuristic,
    maxMipOverlap,
    startingMipOverlap,
    checkCopyNumber,
    sealBothStrands,
    halfSealBothStrands,
    doubleTileStrandUnaware,
    doubleTileStrandsSeparately,
    scoreMethod,
    logisticOptimalScore,
    svrOptimalScore,
    logisticPriorityScore,
    svrPriorityScore,
    silentMode,
    bwaThreads,
  ];
}

class ProjectOptionsInclude extends _is.IncludeObject {
  ProjectOptionsInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ProjectOptions.t;
}

class ProjectOptionsIncludeList extends _is.IncludeList {
  ProjectOptionsIncludeList._({
    _is.WhereExpressionBuilder<ProjectOptionsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProjectOptions.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ProjectOptions.t;
}

class ProjectOptionsRepository {
  const ProjectOptionsRepository._();

  /// Returns a list of [ProjectOptions]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ProjectOptions>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ProjectOptions] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ProjectOptions?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? offset,
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ProjectOptions] by its [id] or null if no such row exists.
  Future<ProjectOptions?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ProjectOptions>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ProjectOptions]s in the list and returns the inserted rows.
  ///
  /// The returned [ProjectOptions]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> insert(
    _is.DatabaseSession session,
    List<ProjectOptions> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ProjectOptions>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ProjectOptions] and returns the inserted row.
  ///
  /// The returned [ProjectOptions] will have its `id` field set.
  Future<ProjectOptions> insertRow(
    _is.DatabaseSession session,
    ProjectOptions row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProjectOptions>(row, transaction: transaction);
  }

  /// Upserts all [ProjectOptions]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [ProjectOptions]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> upsert(
    _is.DatabaseSession session,
    List<ProjectOptions> rows, {
    required _is.ColumnSelections<ProjectOptionsTable> conflictColumns,
    _is.ColumnSelections<ProjectOptionsTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectOptionsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ProjectOptions>(
      rows,
      conflictColumns: conflictColumns(ProjectOptions.t),
      updateColumns: updateColumns?.call(ProjectOptions.t),
      updateWhere: updateWhere?.call(ProjectOptions.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ProjectOptions] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [ProjectOptions] will have its `id` field set.
  Future<ProjectOptions?> upsertRow(
    _is.DatabaseSession session,
    ProjectOptions row, {
    required _is.ColumnSelections<ProjectOptionsTable> conflictColumns,
    _is.ColumnSelections<ProjectOptionsTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectOptionsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ProjectOptions>(
      row,
      conflictColumns: conflictColumns(ProjectOptions.t),
      updateColumns: updateColumns?.call(ProjectOptions.t),
      updateWhere: updateWhere?.call(ProjectOptions.t),
      transaction: transaction,
    );
  }

  /// Updates all [ProjectOptions]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> update(
    _is.DatabaseSession session,
    List<ProjectOptions> rows, {
    _is.ColumnSelections<ProjectOptionsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ProjectOptions>(
      rows,
      columns: columns?.call(ProjectOptions.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ProjectOptions]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProjectOptions> updateRow(
    _is.DatabaseSession session,
    ProjectOptions row, {
    _is.ColumnSelections<ProjectOptionsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProjectOptions>(
      row,
      columns: columns?.call(ProjectOptions.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProjectOptions] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ProjectOptions?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProjectOptionsUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ProjectOptions>(
      id,
      columnValues: columnValues(ProjectOptions.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ProjectOptions]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProjectOptionsUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ProjectOptionsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ProjectOptions>(
      columnValues: columnValues(ProjectOptions.t.updateTable),
      where: where(ProjectOptions.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ProjectOptions]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> delete(
    _is.DatabaseSession session,
    List<ProjectOptions> rows, {
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ProjectOptions>(
      rows,
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ProjectOptions].
  Future<ProjectOptions> deleteRow(
    _is.DatabaseSession session,
    ProjectOptions row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProjectOptions>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectOptions>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectOptionsTable> where,
    _is.OrderByBuilder<ProjectOptionsTable>? orderBy,
    _is.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ProjectOptions>(
      where: where(ProjectOptions.t),
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ProjectOptions] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectOptionsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ProjectOptions>(
      where: where(ProjectOptions.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
