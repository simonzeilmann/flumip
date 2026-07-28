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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:flumip_server/src/generated/protocol.dart' as _i2;

abstract class Project
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Project._({
    this.id,
    required this.name,
    this.folderName,
    String? description,
    this.genome,
    this.snp,
    this.tags,
    DateTime? created,
    this.owner,
    this.department,
    this.genes,
    bool? bedFileCreated,
    bool? active,
    this.pid,
    int? size,
    bool? emailNotification,
    required this.options,
    this.started,
    this.completedIn,
    String? error,
    bool? cleanup,
  }) : description = description ?? '',
       created = created ?? DateTime.now(),
       bedFileCreated = bedFileCreated ?? false,
       active = active ?? false,
       size = size ?? 0,
       emailNotification = emailNotification ?? false,
       error = error ?? '',
       cleanup = cleanup ?? false;

  factory Project({
    int? id,
    required String name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    required int options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    bool? cleanup,
  }) = _ProjectImpl;

  factory Project.fromJson(Map<String, dynamic> jsonSerialization) {
    return Project(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      folderName: jsonSerialization['folderName'] as String?,
      description: jsonSerialization['description'] as String?,
      genome: jsonSerialization['genome'] as int?,
      snp: jsonSerialization['snp'] as int?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      created: jsonSerialization['created'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      owner: jsonSerialization['owner'] as int?,
      department: jsonSerialization['department'] as int?,
      genes: jsonSerialization['genes'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['genes'],
            ),
      bedFileCreated: jsonSerialization['bedFileCreated'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['bedFileCreated']),
      active: jsonSerialization['active'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['active']),
      pid: jsonSerialization['pid'] as int?,
      size: jsonSerialization['size'] as int?,
      emailNotification: jsonSerialization['emailNotification'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['emailNotification'],
            ),
      options: jsonSerialization['options'] as int,
      started: jsonSerialization['started'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['started']),
      completedIn: jsonSerialization['completedIn'] == null
          ? null
          : _i1.DurationJsonExtension.fromJson(
              jsonSerialization['completedIn'],
            ),
      error: jsonSerialization['error'] as String?,
      cleanup: jsonSerialization['cleanup'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['cleanup']),
    );
  }

  static final t = ProjectTable();

  static const db = ProjectRepository._();

  @override
  int? id;

  String name;

  String? folderName;

  String description;

  int? genome;

  int? snp;

  List<String>? tags;

  DateTime created;

  int? owner;

  int? department;

  List<String>? genes;

  bool bedFileCreated;

  bool active;

  int? pid;

  int size;

  bool emailNotification;

  int options;

  DateTime? started;

  Duration? completedIn;

  String error;

  bool cleanup;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Project copyWith({
    int? id,
    String? name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    int? options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    bool? cleanup,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      if (folderName != null) 'folderName': folderName,
      'description': description,
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      if (tags != null) 'tags': tags?.toJson(),
      'created': created.toJson(),
      if (owner != null) 'owner': owner,
      if (department != null) 'department': department,
      if (genes != null) 'genes': genes?.toJson(),
      'bedFileCreated': bedFileCreated,
      'active': active,
      if (pid != null) 'pid': pid,
      'size': size,
      'emailNotification': emailNotification,
      'options': options,
      if (started != null) 'started': started?.toJson(),
      if (completedIn != null) 'completedIn': completedIn?.toJson(),
      'error': error,
      'cleanup': cleanup,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      if (tags != null) 'tags': tags?.toJson(),
      'created': created.toJson(),
      if (owner != null) 'owner': owner,
      if (department != null) 'department': department,
      if (genes != null) 'genes': genes?.toJson(),
      'bedFileCreated': bedFileCreated,
      'active': active,
      'size': size,
      'emailNotification': emailNotification,
      'options': options,
      if (started != null) 'started': started?.toJson(),
      if (completedIn != null) 'completedIn': completedIn?.toJson(),
      'error': error,
      'cleanup': cleanup,
    };
  }

  static ProjectInclude include() {
    return ProjectInclude._();
  }

  static ProjectIncludeList includeList({
    _i1.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectTable>? orderByList,
    ProjectInclude? include,
  }) {
    return ProjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Project.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectImpl extends Project {
  _ProjectImpl({
    int? id,
    required String name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    required int options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    bool? cleanup,
  }) : super._(
         id: id,
         name: name,
         folderName: folderName,
         description: description,
         genome: genome,
         snp: snp,
         tags: tags,
         created: created,
         owner: owner,
         department: department,
         genes: genes,
         bedFileCreated: bedFileCreated,
         active: active,
         pid: pid,
         size: size,
         emailNotification: emailNotification,
         options: options,
         started: started,
         completedIn: completedIn,
         error: error,
         cleanup: cleanup,
       );

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Project copyWith({
    Object? id = _Undefined,
    String? name,
    Object? folderName = _Undefined,
    String? description,
    Object? genome = _Undefined,
    Object? snp = _Undefined,
    Object? tags = _Undefined,
    DateTime? created,
    Object? owner = _Undefined,
    Object? department = _Undefined,
    Object? genes = _Undefined,
    bool? bedFileCreated,
    bool? active,
    Object? pid = _Undefined,
    int? size,
    bool? emailNotification,
    int? options,
    Object? started = _Undefined,
    Object? completedIn = _Undefined,
    String? error,
    bool? cleanup,
  }) {
    return Project(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      folderName: folderName is String? ? folderName : this.folderName,
      description: description ?? this.description,
      genome: genome is int? ? genome : this.genome,
      snp: snp is int? ? snp : this.snp,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      created: created ?? this.created,
      owner: owner is int? ? owner : this.owner,
      department: department is int? ? department : this.department,
      genes: genes is List<String>?
          ? genes
          : this.genes?.map((e0) => e0).toList(),
      bedFileCreated: bedFileCreated ?? this.bedFileCreated,
      active: active ?? this.active,
      pid: pid is int? ? pid : this.pid,
      size: size ?? this.size,
      emailNotification: emailNotification ?? this.emailNotification,
      options: options ?? this.options,
      started: started is DateTime? ? started : this.started,
      completedIn: completedIn is Duration? ? completedIn : this.completedIn,
      error: error ?? this.error,
      cleanup: cleanup ?? this.cleanup,
    );
  }
}

class ProjectUpdateTable extends _i1.UpdateTable<ProjectTable> {
  ProjectUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> folderName(String? value) => _i1.ColumnValue(
    table.folderName,
    value,
  );

  _i1.ColumnValue<String, String> description(String value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<int, int> genome(int? value) => _i1.ColumnValue(
    table.genome,
    value,
  );

  _i1.ColumnValue<int, int> snp(int? value) => _i1.ColumnValue(
    table.snp,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> tags(List<String>? value) =>
      _i1.ColumnValue(
        table.tags,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _i1.ColumnValue(
        table.created,
        value,
      );

  _i1.ColumnValue<int, int> owner(int? value) => _i1.ColumnValue(
    table.owner,
    value,
  );

  _i1.ColumnValue<int, int> department(int? value) => _i1.ColumnValue(
    table.department,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> genes(List<String>? value) =>
      _i1.ColumnValue(
        table.genes,
        value,
      );

  _i1.ColumnValue<bool, bool> bedFileCreated(bool value) => _i1.ColumnValue(
    table.bedFileCreated,
    value,
  );

  _i1.ColumnValue<bool, bool> active(bool value) => _i1.ColumnValue(
    table.active,
    value,
  );

  _i1.ColumnValue<int, int> pid(int? value) => _i1.ColumnValue(
    table.pid,
    value,
  );

  _i1.ColumnValue<int, int> size(int value) => _i1.ColumnValue(
    table.size,
    value,
  );

  _i1.ColumnValue<bool, bool> emailNotification(bool value) => _i1.ColumnValue(
    table.emailNotification,
    value,
  );

  _i1.ColumnValue<int, int> options(int value) => _i1.ColumnValue(
    table.options,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> started(DateTime? value) =>
      _i1.ColumnValue(
        table.started,
        value,
      );

  _i1.ColumnValue<Duration, Duration> completedIn(Duration? value) =>
      _i1.ColumnValue(
        table.completedIn,
        value,
      );

  _i1.ColumnValue<String, String> error(String value) => _i1.ColumnValue(
    table.error,
    value,
  );

  _i1.ColumnValue<bool, bool> cleanup(bool value) => _i1.ColumnValue(
    table.cleanup,
    value,
  );
}

class ProjectTable extends _i1.Table<int?> {
  ProjectTable({super.tableRelation}) : super(tableName: 'project') {
    updateTable = ProjectUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    folderName = _i1.ColumnString(
      'folderName',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
      hasDefault: true,
    );
    genome = _i1.ColumnInt(
      'genome',
      this,
    );
    snp = _i1.ColumnInt(
      'snp',
      this,
    );
    tags = _i1.ColumnSerializable<List<String>>(
      'tags',
      this,
    );
    created = _i1.ColumnDateTime(
      'created',
      this,
      hasDefault: true,
    );
    owner = _i1.ColumnInt(
      'owner',
      this,
    );
    department = _i1.ColumnInt(
      'department',
      this,
    );
    genes = _i1.ColumnSerializable<List<String>>(
      'genes',
      this,
    );
    bedFileCreated = _i1.ColumnBool(
      'bedFileCreated',
      this,
      hasDefault: true,
    );
    active = _i1.ColumnBool(
      'active',
      this,
      hasDefault: true,
    );
    pid = _i1.ColumnInt(
      'pid',
      this,
    );
    size = _i1.ColumnInt(
      'size',
      this,
      hasDefault: true,
    );
    emailNotification = _i1.ColumnBool(
      'emailNotification',
      this,
      hasDefault: true,
    );
    options = _i1.ColumnInt(
      'options',
      this,
    );
    started = _i1.ColumnDateTime(
      'started',
      this,
    );
    completedIn = _i1.ColumnDuration(
      'completedIn',
      this,
    );
    error = _i1.ColumnString(
      'error',
      this,
      hasDefault: true,
    );
    cleanup = _i1.ColumnBool(
      'cleanup',
      this,
      hasDefault: true,
    );
  }

  late final ProjectUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString folderName;

  late final _i1.ColumnString description;

  late final _i1.ColumnInt genome;

  late final _i1.ColumnInt snp;

  late final _i1.ColumnSerializable<List<String>> tags;

  late final _i1.ColumnDateTime created;

  late final _i1.ColumnInt owner;

  late final _i1.ColumnInt department;

  late final _i1.ColumnSerializable<List<String>> genes;

  late final _i1.ColumnBool bedFileCreated;

  late final _i1.ColumnBool active;

  late final _i1.ColumnInt pid;

  late final _i1.ColumnInt size;

  late final _i1.ColumnBool emailNotification;

  late final _i1.ColumnInt options;

  late final _i1.ColumnDateTime started;

  late final _i1.ColumnDuration completedIn;

  late final _i1.ColumnString error;

  late final _i1.ColumnBool cleanup;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    folderName,
    description,
    genome,
    snp,
    tags,
    created,
    owner,
    department,
    genes,
    bedFileCreated,
    active,
    pid,
    size,
    emailNotification,
    options,
    started,
    completedIn,
    error,
    cleanup,
  ];
}

class ProjectInclude extends _i1.IncludeObject {
  ProjectInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Project.t;
}

class ProjectIncludeList extends _i1.IncludeList {
  ProjectIncludeList._({
    _i1.WhereExpressionBuilder<ProjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Project.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Project.t;
}

class ProjectRepository {
  const ProjectRepository._();

  /// Returns a list of [Project]s matching the given query parameters.
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
  Future<List<Project>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Project] matching the given query parameters.
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
  Future<Project?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ProjectTable>? where,
    int? offset,
    _i1.OrderByBuilder<ProjectTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ProjectTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Project] by its [id] or null if no such row exists.
  Future<Project?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Project>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Project]s in the list and returns the inserted rows.
  ///
  /// The returned [Project]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Project>> insert(
    _i1.DatabaseSession session,
    List<Project> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Project>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Project] and returns the inserted row.
  ///
  /// The returned [Project] will have its `id` field set.
  Future<Project> insertRow(
    _i1.DatabaseSession session,
    Project row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Project>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Project]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Project>> update(
    _i1.DatabaseSession session,
    List<Project> rows, {
    _i1.ColumnSelections<ProjectTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Project>(
      rows,
      columns: columns?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Project]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Project> updateRow(
    _i1.DatabaseSession session,
    Project row, {
    _i1.ColumnSelections<ProjectTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Project>(
      row,
      columns: columns?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Project] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Project?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Project>(
      id,
      columnValues: columnValues(Project.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Project]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Project>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ProjectTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ProjectTable>? orderBy,
    _i1.OrderByListBuilder<ProjectTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Project>(
      columnValues: columnValues(Project.t.updateTable),
      where: where(Project.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Project]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Project>> delete(
    _i1.DatabaseSession session,
    List<Project> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Project>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Project].
  Future<Project> deleteRow(
    _i1.DatabaseSession session,
    Project row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Project>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Project>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ProjectTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Project>(
      where: where(Project.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Project>(
      where: where?.call(Project.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Project] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ProjectTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Project>(
      where: where(Project.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
