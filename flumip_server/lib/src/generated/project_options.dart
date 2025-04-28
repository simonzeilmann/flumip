/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'score_method.dart' as _i2;

abstract class ProjectOptions
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
  })  : minCaptureSize = minCaptureSize ?? 162,
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
      minCaptureSize: jsonSerialization['minCaptureSize'] as int,
      maxCaptureSize: jsonSerialization['maxCaptureSize'] as int,
      armLengths: jsonSerialization['armLengths'] as String?,
      armLengthSums: jsonSerialization['armLengthSums'] as String,
      extMinLength: jsonSerialization['extMinLength'] as int,
      extMaxLength: jsonSerialization['extMaxLength'] as int,
      ligMinLength: jsonSerialization['ligMinLength'] as int,
      tagSizes: jsonSerialization['tagSizes'] as String,
      maskedArmThreshold:
          (jsonSerialization['maskedArmThreshold'] as num).toDouble(),
      targetArmCopy: jsonSerialization['targetArmCopy'] as int,
      maxArmCopyProduct: jsonSerialization['maxArmCopyProduct'] as int,
      trf: jsonSerialization['trf'] as bool,
      genomeDir: jsonSerialization['genomeDir'] as String?,
      featureFlank: jsonSerialization['featureFlank'] as int,
      captureIncrement: jsonSerialization['captureIncrement'] as int,
      logisticHeuristic: jsonSerialization['logisticHeuristic'] as bool,
      maxMipOverlap: jsonSerialization['maxMipOverlap'] as int,
      startingMipOverlap: jsonSerialization['startingMipOverlap'] as int,
      checkCopyNumber: jsonSerialization['checkCopyNumber'] as bool,
      sealBothStrands: jsonSerialization['sealBothStrands'] as bool,
      halfSealBothStrands: jsonSerialization['halfSealBothStrands'] as bool,
      doubleTileStrandUnaware:
          jsonSerialization['doubleTileStrandUnaware'] as bool,
      doubleTileStrandsSeparately:
          jsonSerialization['doubleTileStrandsSeparately'] as bool,
      scoreMethod: _i2.ScoreMethod.fromJson(
          (jsonSerialization['scoreMethod'] as String)),
      logisticOptimalScore:
          (jsonSerialization['logisticOptimalScore'] as num).toDouble(),
      svrOptimalScore: (jsonSerialization['svrOptimalScore'] as num).toDouble(),
      logisticPriorityScore:
          (jsonSerialization['logisticPriorityScore'] as num).toDouble(),
      svrPriorityScore:
          (jsonSerialization['svrPriorityScore'] as num).toDouble(),
      silentMode: jsonSerialization['silentMode'] as bool,
      bwaThreads: jsonSerialization['bwaThreads'] as int,
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

  _i2.ScoreMethod scoreMethod;

  double logisticOptimalScore;

  double svrOptimalScore;

  double logisticPriorityScore;

  double svrPriorityScore;

  bool silentMode;

  int bwaThreads;

  @override
  _i1.Table<int?> get table => t;

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
    _i1.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProjectOptionsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    ProjectOptionsInclude? include,
  }) {
    return ProjectOptionsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProjectOptions.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ProjectOptions.t),
      include: include,
    );
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

class ProjectOptionsTable extends _i1.Table<int?> {
  ProjectOptionsTable({super.tableRelation})
      : super(tableName: 'project_options') {
    minCaptureSize = _i1.ColumnInt(
      'minCaptureSize',
      this,
      hasDefault: true,
    );
    maxCaptureSize = _i1.ColumnInt(
      'maxCaptureSize',
      this,
      hasDefault: true,
    );
    armLengths = _i1.ColumnString(
      'armLengths',
      this,
    );
    armLengthSums = _i1.ColumnString(
      'armLengthSums',
      this,
      hasDefault: true,
    );
    extMinLength = _i1.ColumnInt(
      'extMinLength',
      this,
      hasDefault: true,
    );
    extMaxLength = _i1.ColumnInt(
      'extMaxLength',
      this,
      hasDefault: true,
    );
    ligMinLength = _i1.ColumnInt(
      'ligMinLength',
      this,
      hasDefault: true,
    );
    tagSizes = _i1.ColumnString(
      'tagSizes',
      this,
      hasDefault: true,
    );
    maskedArmThreshold = _i1.ColumnDouble(
      'maskedArmThreshold',
      this,
      hasDefault: true,
    );
    targetArmCopy = _i1.ColumnInt(
      'targetArmCopy',
      this,
      hasDefault: true,
    );
    maxArmCopyProduct = _i1.ColumnInt(
      'maxArmCopyProduct',
      this,
      hasDefault: true,
    );
    trf = _i1.ColumnBool(
      'trf',
      this,
      hasDefault: true,
    );
    genomeDir = _i1.ColumnString(
      'genomeDir',
      this,
    );
    featureFlank = _i1.ColumnInt(
      'featureFlank',
      this,
      hasDefault: true,
    );
    captureIncrement = _i1.ColumnInt(
      'captureIncrement',
      this,
      hasDefault: true,
    );
    logisticHeuristic = _i1.ColumnBool(
      'logisticHeuristic',
      this,
      hasDefault: true,
    );
    maxMipOverlap = _i1.ColumnInt(
      'maxMipOverlap',
      this,
      hasDefault: true,
    );
    startingMipOverlap = _i1.ColumnInt(
      'startingMipOverlap',
      this,
      hasDefault: true,
    );
    checkCopyNumber = _i1.ColumnBool(
      'checkCopyNumber',
      this,
      hasDefault: true,
    );
    sealBothStrands = _i1.ColumnBool(
      'sealBothStrands',
      this,
      hasDefault: true,
    );
    halfSealBothStrands = _i1.ColumnBool(
      'halfSealBothStrands',
      this,
      hasDefault: true,
    );
    doubleTileStrandUnaware = _i1.ColumnBool(
      'doubleTileStrandUnaware',
      this,
      hasDefault: true,
    );
    doubleTileStrandsSeparately = _i1.ColumnBool(
      'doubleTileStrandsSeparately',
      this,
      hasDefault: true,
    );
    scoreMethod = _i1.ColumnEnum(
      'scoreMethod',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    logisticOptimalScore = _i1.ColumnDouble(
      'logisticOptimalScore',
      this,
      hasDefault: true,
    );
    svrOptimalScore = _i1.ColumnDouble(
      'svrOptimalScore',
      this,
      hasDefault: true,
    );
    logisticPriorityScore = _i1.ColumnDouble(
      'logisticPriorityScore',
      this,
      hasDefault: true,
    );
    svrPriorityScore = _i1.ColumnDouble(
      'svrPriorityScore',
      this,
      hasDefault: true,
    );
    silentMode = _i1.ColumnBool(
      'silentMode',
      this,
      hasDefault: true,
    );
    bwaThreads = _i1.ColumnInt(
      'bwaThreads',
      this,
      hasDefault: true,
    );
  }

  late final _i1.ColumnInt minCaptureSize;

  late final _i1.ColumnInt maxCaptureSize;

  late final _i1.ColumnString armLengths;

  late final _i1.ColumnString armLengthSums;

  late final _i1.ColumnInt extMinLength;

  late final _i1.ColumnInt extMaxLength;

  late final _i1.ColumnInt ligMinLength;

  late final _i1.ColumnString tagSizes;

  late final _i1.ColumnDouble maskedArmThreshold;

  late final _i1.ColumnInt targetArmCopy;

  late final _i1.ColumnInt maxArmCopyProduct;

  late final _i1.ColumnBool trf;

  late final _i1.ColumnString genomeDir;

  late final _i1.ColumnInt featureFlank;

  late final _i1.ColumnInt captureIncrement;

  late final _i1.ColumnBool logisticHeuristic;

  late final _i1.ColumnInt maxMipOverlap;

  late final _i1.ColumnInt startingMipOverlap;

  late final _i1.ColumnBool checkCopyNumber;

  late final _i1.ColumnBool sealBothStrands;

  late final _i1.ColumnBool halfSealBothStrands;

  late final _i1.ColumnBool doubleTileStrandUnaware;

  late final _i1.ColumnBool doubleTileStrandsSeparately;

  late final _i1.ColumnEnum<_i2.ScoreMethod> scoreMethod;

  late final _i1.ColumnDouble logisticOptimalScore;

  late final _i1.ColumnDouble svrOptimalScore;

  late final _i1.ColumnDouble logisticPriorityScore;

  late final _i1.ColumnDouble svrPriorityScore;

  late final _i1.ColumnBool silentMode;

  late final _i1.ColumnInt bwaThreads;

  @override
  List<_i1.Column> get columns => [
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

class ProjectOptionsInclude extends _i1.IncludeObject {
  ProjectOptionsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ProjectOptions.t;
}

class ProjectOptionsIncludeList extends _i1.IncludeList {
  ProjectOptionsIncludeList._({
    _i1.WhereExpressionBuilder<ProjectOptionsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProjectOptions.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ProjectOptions.t;
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
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProjectOptionsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
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
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? offset,
    _i1.OrderByBuilder<ProjectOptionsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectOptionsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      orderBy: orderBy?.call(ProjectOptions.t),
      orderByList: orderByList?.call(ProjectOptions.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [ProjectOptions] by its [id] or null if no such row exists.
  Future<ProjectOptions?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<ProjectOptions>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [ProjectOptions]s in the list and returns the inserted rows.
  ///
  /// The returned [ProjectOptions]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<ProjectOptions>> insert(
    _i1.Session session,
    List<ProjectOptions> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<ProjectOptions>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [ProjectOptions] and returns the inserted row.
  ///
  /// The returned [ProjectOptions] will have its `id` field set.
  Future<ProjectOptions> insertRow(
    _i1.Session session,
    ProjectOptions row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProjectOptions>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ProjectOptions]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ProjectOptions>> update(
    _i1.Session session,
    List<ProjectOptions> rows, {
    _i1.ColumnSelections<ProjectOptionsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ProjectOptions>(
      rows,
      columns: columns?.call(ProjectOptions.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProjectOptions]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProjectOptions> updateRow(
    _i1.Session session,
    ProjectOptions row, {
    _i1.ColumnSelections<ProjectOptionsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProjectOptions>(
      row,
      columns: columns?.call(ProjectOptions.t),
      transaction: transaction,
    );
  }

  /// Deletes all [ProjectOptions]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ProjectOptions>> delete(
    _i1.Session session,
    List<ProjectOptions> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ProjectOptions>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ProjectOptions].
  Future<ProjectOptions> deleteRow(
    _i1.Session session,
    ProjectOptions row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProjectOptions>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ProjectOptions>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ProjectOptionsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ProjectOptions>(
      where: where(ProjectOptions.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ProjectOptionsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ProjectOptions>(
      where: where?.call(ProjectOptions.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
