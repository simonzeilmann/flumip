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
import 'package:serverpod/protocol.dart' as _i2;
import 'project.dart' as _i3;
import 'project_options.dart' as _i4;
import 'score_method.dart' as _i5;
import 'package:flumip_server/src/generated/project.dart' as _i6;
export 'project.dart';
export 'project_options.dart';
export 'score_method.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'project',
      dartName: 'Project',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'project_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'folderName',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'tags',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'created',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'owner',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'department',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'genes',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'bedFileCreated',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'active',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'pid',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'size',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'emailNotification',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'options',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'started',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'completedIn',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'Duration?',
        ),
        _i2.ColumnDefinition(
          name: 'error',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'cleanup',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'project_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        )
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'project_options',
      dartName: 'ProjectOptions',
      schema: 'public',
      module: 'flumip',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'project_options_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'fasta',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'snp',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'minCaptureSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _i2.ColumnDefinition(
          name: 'maxCaptureSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '162',
        ),
        _i2.ColumnDefinition(
          name: 'armLengths',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'armLengthSums',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'40,41,42,43,44,45\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'extMinLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '16',
        ),
        _i2.ColumnDefinition(
          name: 'extMaxLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _i2.ColumnDefinition(
          name: 'ligMinLength',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '18',
        ),
        _i2.ColumnDefinition(
          name: 'tagSizes',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '5.0',
        ),
        _i2.ColumnDefinition(
          name: 'maskedArmThreshold',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.5',
        ),
        _i2.ColumnDefinition(
          name: 'targetArmCopy',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '20',
        ),
        _i2.ColumnDefinition(
          name: 'maxArmCopyProduct',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '75',
        ),
        _i2.ColumnDefinition(
          name: 'trf',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'genomeDir',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'featureFlank',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'captureIncrement',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '5',
        ),
        _i2.ColumnDefinition(
          name: 'logisticHeuristic',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'maxMipOverlap',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '30',
        ),
        _i2.ColumnDefinition(
          name: 'startingMipOverlap',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'checkCopyNumber',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'sealBothStrands',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'halfSealBothStrands',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'doubleTileStrandUnaware',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'doubleTileStrandsSeparately',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'scoreMethod',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ScoreMethod',
          columnDefault: '\'logistic\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'logisticOptimalScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.98',
        ),
        _i2.ColumnDefinition(
          name: 'svrOptimalScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '2.2',
        ),
        _i2.ColumnDefinition(
          name: 'logisticPriorityScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.9',
        ),
        _i2.ColumnDefinition(
          name: 'svrPriorityScore',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '1.5',
        ),
        _i2.ColumnDefinition(
          name: 'silentMode',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'bwaThreads',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'project_options_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            )
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        )
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i3.Project) {
      return _i3.Project.fromJson(data) as T;
    }
    if (t == _i4.ProjectOptions) {
      return _i4.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i5.ScoreMethod) {
      return _i5.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.Project?>()) {
      return (data != null ? _i3.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ProjectOptions?>()) {
      return (data != null ? _i4.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ScoreMethod?>()) {
      return (data != null ? _i5.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<String>(e)).toList()
          : null) as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<String>(e)).toList()
          : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i6.Project>) {
      return (data as List).map((e) => deserialize<_i6.Project>(e)).toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i3.Project) {
      return 'Project';
    }
    if (data is _i4.ProjectOptions) {
      return 'ProjectOptions';
    }
    if (data is _i5.ScoreMethod) {
      return 'ScoreMethod';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i3.Project>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i4.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i5.ScoreMethod>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i3.Project:
        return _i3.Project.t;
      case _i4.ProjectOptions:
        return _i4.ProjectOptions.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'flumip';
}
