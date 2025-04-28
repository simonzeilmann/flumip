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

abstract class Settings
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Settings._({
    this.id,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
  })  : baseDir = baseDir ?? '/opt/flumip',
        projectDir = projectDir ?? '/opt/flumip/projects',
        genomeDir = genomeDir ?? '/opt/flumip/data/genomes',
        customSnpDir = customSnpDir ?? '/opt/flumip/data/custom_snp',
        toolsDir = toolsDir ?? '/opt/flumip/tools',
        mipgenExecutable = mipgenExecutable ?? '/opt/flumip/MIPGEN/mipgen',
        exonExtractScript = exonExtractScript ??
            '/opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh',
        ucscTrackGenerator = ucscTrackGenerator ??
            '/opt/flumip/MIPGEN/tools/generate_ucsc_track.py',
        binCreationScript = binCreationScript ??
            '/opt/flumip/MIPGEN/tools/add_bins_to_refgene.py',
        bigGenePredToGenePredExecutable = bigGenePredToGenePredExecutable ??
            '/opt/flumip/tools/bigGenePredToGenePred',
        mailActive = mailActive ?? false,
        smtpServer = smtpServer ?? '',
        smtpPort = smtpPort ?? 25,
        smtpUser = smtpUser ?? '',
        smtpPassword = smtpPassword ?? '',
        smtpFrom = smtpFrom ?? 'flumip@yourdomain.com',
        startTLS = startTLS ?? true,
        loginRequired = loginRequired ?? false,
        settingsPassword = settingsPassword ?? 'changeme';

  factory Settings({
    int? id,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
  }) = _SettingsImpl;

  factory Settings.fromJson(Map<String, dynamic> jsonSerialization) {
    return Settings(
      id: jsonSerialization['id'] as int?,
      baseDir: jsonSerialization['baseDir'] as String,
      projectDir: jsonSerialization['projectDir'] as String,
      genomeDir: jsonSerialization['genomeDir'] as String,
      customSnpDir: jsonSerialization['customSnpDir'] as String,
      toolsDir: jsonSerialization['toolsDir'] as String,
      mipgenExecutable: jsonSerialization['mipgenExecutable'] as String,
      exonExtractScript: jsonSerialization['exonExtractScript'] as String,
      ucscTrackGenerator: jsonSerialization['ucscTrackGenerator'] as String,
      binCreationScript: jsonSerialization['binCreationScript'] as String,
      bigGenePredToGenePredExecutable:
          jsonSerialization['bigGenePredToGenePredExecutable'] as String,
      mailActive: jsonSerialization['mailActive'] as bool,
      smtpServer: jsonSerialization['smtpServer'] as String,
      smtpPort: jsonSerialization['smtpPort'] as int,
      smtpUser: jsonSerialization['smtpUser'] as String,
      smtpPassword: jsonSerialization['smtpPassword'] as String,
      smtpFrom: jsonSerialization['smtpFrom'] as String,
      startTLS: jsonSerialization['startTLS'] as bool,
      loginRequired: jsonSerialization['loginRequired'] as bool,
      settingsPassword: jsonSerialization['settingsPassword'] as String,
    );
  }

  static final t = SettingsTable();

  static const db = SettingsRepository._();

  @override
  int? id;

  String baseDir;

  String projectDir;

  String genomeDir;

  String customSnpDir;

  String toolsDir;

  String mipgenExecutable;

  String exonExtractScript;

  String ucscTrackGenerator;

  String binCreationScript;

  String bigGenePredToGenePredExecutable;

  bool mailActive;

  String smtpServer;

  int smtpPort;

  String smtpUser;

  String smtpPassword;

  String smtpFrom;

  bool startTLS;

  bool loginRequired;

  String settingsPassword;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Settings copyWith({
    int? id,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'baseDir': baseDir,
      'projectDir': projectDir,
      'genomeDir': genomeDir,
      'customSnpDir': customSnpDir,
      'toolsDir': toolsDir,
      'mipgenExecutable': mipgenExecutable,
      'exonExtractScript': exonExtractScript,
      'ucscTrackGenerator': ucscTrackGenerator,
      'binCreationScript': binCreationScript,
      'bigGenePredToGenePredExecutable': bigGenePredToGenePredExecutable,
      'mailActive': mailActive,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'smtpUser': smtpUser,
      'smtpPassword': smtpPassword,
      'smtpFrom': smtpFrom,
      'startTLS': startTLS,
      'loginRequired': loginRequired,
      'settingsPassword': settingsPassword,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      if (id != null) 'id': id,
      'baseDir': baseDir,
      'projectDir': projectDir,
      'genomeDir': genomeDir,
      'customSnpDir': customSnpDir,
      'toolsDir': toolsDir,
      'mipgenExecutable': mipgenExecutable,
      'exonExtractScript': exonExtractScript,
      'ucscTrackGenerator': ucscTrackGenerator,
      'binCreationScript': binCreationScript,
      'bigGenePredToGenePredExecutable': bigGenePredToGenePredExecutable,
      'mailActive': mailActive,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'smtpUser': smtpUser,
      'smtpPassword': smtpPassword,
      'smtpFrom': smtpFrom,
      'startTLS': startTLS,
      'loginRequired': loginRequired,
      'settingsPassword': settingsPassword,
    };
  }

  static SettingsInclude include() {
    return SettingsInclude._();
  }

  static SettingsIncludeList includeList({
    _i1.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SettingsTable>? orderByList,
    SettingsInclude? include,
  }) {
    return SettingsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Settings.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Settings.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SettingsImpl extends Settings {
  _SettingsImpl({
    int? id,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
  }) : super._(
          id: id,
          baseDir: baseDir,
          projectDir: projectDir,
          genomeDir: genomeDir,
          customSnpDir: customSnpDir,
          toolsDir: toolsDir,
          mipgenExecutable: mipgenExecutable,
          exonExtractScript: exonExtractScript,
          ucscTrackGenerator: ucscTrackGenerator,
          binCreationScript: binCreationScript,
          bigGenePredToGenePredExecutable: bigGenePredToGenePredExecutable,
          mailActive: mailActive,
          smtpServer: smtpServer,
          smtpPort: smtpPort,
          smtpUser: smtpUser,
          smtpPassword: smtpPassword,
          smtpFrom: smtpFrom,
          startTLS: startTLS,
          loginRequired: loginRequired,
          settingsPassword: settingsPassword,
        );

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Settings copyWith({
    Object? id = _Undefined,
    String? baseDir,
    String? projectDir,
    String? genomeDir,
    String? customSnpDir,
    String? toolsDir,
    String? mipgenExecutable,
    String? exonExtractScript,
    String? ucscTrackGenerator,
    String? binCreationScript,
    String? bigGenePredToGenePredExecutable,
    bool? mailActive,
    String? smtpServer,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? smtpFrom,
    bool? startTLS,
    bool? loginRequired,
    String? settingsPassword,
  }) {
    return Settings(
      id: id is int? ? id : this.id,
      baseDir: baseDir ?? this.baseDir,
      projectDir: projectDir ?? this.projectDir,
      genomeDir: genomeDir ?? this.genomeDir,
      customSnpDir: customSnpDir ?? this.customSnpDir,
      toolsDir: toolsDir ?? this.toolsDir,
      mipgenExecutable: mipgenExecutable ?? this.mipgenExecutable,
      exonExtractScript: exonExtractScript ?? this.exonExtractScript,
      ucscTrackGenerator: ucscTrackGenerator ?? this.ucscTrackGenerator,
      binCreationScript: binCreationScript ?? this.binCreationScript,
      bigGenePredToGenePredExecutable: bigGenePredToGenePredExecutable ??
          this.bigGenePredToGenePredExecutable,
      mailActive: mailActive ?? this.mailActive,
      smtpServer: smtpServer ?? this.smtpServer,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUser: smtpUser ?? this.smtpUser,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
      startTLS: startTLS ?? this.startTLS,
      loginRequired: loginRequired ?? this.loginRequired,
      settingsPassword: settingsPassword ?? this.settingsPassword,
    );
  }
}

class SettingsTable extends _i1.Table<int?> {
  SettingsTable({super.tableRelation}) : super(tableName: 'settings') {
    baseDir = _i1.ColumnString(
      'baseDir',
      this,
      hasDefault: true,
    );
    projectDir = _i1.ColumnString(
      'projectDir',
      this,
      hasDefault: true,
    );
    genomeDir = _i1.ColumnString(
      'genomeDir',
      this,
      hasDefault: true,
    );
    customSnpDir = _i1.ColumnString(
      'customSnpDir',
      this,
      hasDefault: true,
    );
    toolsDir = _i1.ColumnString(
      'toolsDir',
      this,
      hasDefault: true,
    );
    mipgenExecutable = _i1.ColumnString(
      'mipgenExecutable',
      this,
      hasDefault: true,
    );
    exonExtractScript = _i1.ColumnString(
      'exonExtractScript',
      this,
      hasDefault: true,
    );
    ucscTrackGenerator = _i1.ColumnString(
      'ucscTrackGenerator',
      this,
      hasDefault: true,
    );
    binCreationScript = _i1.ColumnString(
      'binCreationScript',
      this,
      hasDefault: true,
    );
    bigGenePredToGenePredExecutable = _i1.ColumnString(
      'bigGenePredToGenePredExecutable',
      this,
      hasDefault: true,
    );
    mailActive = _i1.ColumnBool(
      'mailActive',
      this,
      hasDefault: true,
    );
    smtpServer = _i1.ColumnString(
      'smtpServer',
      this,
      hasDefault: true,
    );
    smtpPort = _i1.ColumnInt(
      'smtpPort',
      this,
      hasDefault: true,
    );
    smtpUser = _i1.ColumnString(
      'smtpUser',
      this,
      hasDefault: true,
    );
    smtpPassword = _i1.ColumnString(
      'smtpPassword',
      this,
      hasDefault: true,
    );
    smtpFrom = _i1.ColumnString(
      'smtpFrom',
      this,
      hasDefault: true,
    );
    startTLS = _i1.ColumnBool(
      'startTLS',
      this,
      hasDefault: true,
    );
    loginRequired = _i1.ColumnBool(
      'loginRequired',
      this,
      hasDefault: true,
    );
    settingsPassword = _i1.ColumnString(
      'settingsPassword',
      this,
      hasDefault: true,
    );
  }

  late final _i1.ColumnString baseDir;

  late final _i1.ColumnString projectDir;

  late final _i1.ColumnString genomeDir;

  late final _i1.ColumnString customSnpDir;

  late final _i1.ColumnString toolsDir;

  late final _i1.ColumnString mipgenExecutable;

  late final _i1.ColumnString exonExtractScript;

  late final _i1.ColumnString ucscTrackGenerator;

  late final _i1.ColumnString binCreationScript;

  late final _i1.ColumnString bigGenePredToGenePredExecutable;

  late final _i1.ColumnBool mailActive;

  late final _i1.ColumnString smtpServer;

  late final _i1.ColumnInt smtpPort;

  late final _i1.ColumnString smtpUser;

  late final _i1.ColumnString smtpPassword;

  late final _i1.ColumnString smtpFrom;

  late final _i1.ColumnBool startTLS;

  late final _i1.ColumnBool loginRequired;

  late final _i1.ColumnString settingsPassword;

  @override
  List<_i1.Column> get columns => [
        id,
        baseDir,
        projectDir,
        genomeDir,
        customSnpDir,
        toolsDir,
        mipgenExecutable,
        exonExtractScript,
        ucscTrackGenerator,
        binCreationScript,
        bigGenePredToGenePredExecutable,
        mailActive,
        smtpServer,
        smtpPort,
        smtpUser,
        smtpPassword,
        smtpFrom,
        startTLS,
        loginRequired,
        settingsPassword,
      ];
}

class SettingsInclude extends _i1.IncludeObject {
  SettingsInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Settings.t;
}

class SettingsIncludeList extends _i1.IncludeList {
  SettingsIncludeList._({
    _i1.WhereExpressionBuilder<SettingsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Settings.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Settings.t;
}

class SettingsRepository {
  const SettingsRepository._();

  /// Returns a list of [Settings]s matching the given query parameters.
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
  Future<List<Settings>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SettingsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Settings>(
      where: where?.call(Settings.t),
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Settings] matching the given query parameters.
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
  Future<Settings?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SettingsTable>? where,
    int? offset,
    _i1.OrderByBuilder<SettingsTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SettingsTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Settings>(
      where: where?.call(Settings.t),
      orderBy: orderBy?.call(Settings.t),
      orderByList: orderByList?.call(Settings.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Settings] by its [id] or null if no such row exists.
  Future<Settings?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Settings>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Settings]s in the list and returns the inserted rows.
  ///
  /// The returned [Settings]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Settings>> insert(
    _i1.Session session,
    List<Settings> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Settings>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Settings] and returns the inserted row.
  ///
  /// The returned [Settings] will have its `id` field set.
  Future<Settings> insertRow(
    _i1.Session session,
    Settings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Settings>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Settings]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Settings>> update(
    _i1.Session session,
    List<Settings> rows, {
    _i1.ColumnSelections<SettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Settings>(
      rows,
      columns: columns?.call(Settings.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Settings]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Settings> updateRow(
    _i1.Session session,
    Settings row, {
    _i1.ColumnSelections<SettingsTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Settings>(
      row,
      columns: columns?.call(Settings.t),
      transaction: transaction,
    );
  }

  /// Deletes all [Settings]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Settings>> delete(
    _i1.Session session,
    List<Settings> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Settings>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Settings].
  Future<Settings> deleteRow(
    _i1.Session session,
    Settings row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Settings>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Settings>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SettingsTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Settings>(
      where: where(Settings.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SettingsTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Settings>(
      where: where?.call(Settings.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
