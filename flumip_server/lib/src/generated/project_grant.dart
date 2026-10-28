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

/// Access to a project granted by its share link.
///
/// Redeeming a link (`ProjectEndpoint.redeemShareLink`) writes one of these for
/// the caller, and from then on the project is in their list exactly as if they
/// owned it — see `projectIsAccessible`. That is what lets a guest get back to a
/// project from a second browser, and lets anybody share one with a colleague.
///
/// Cascades on both sides: a grant means nothing once the project or the
/// identity holding it is gone.
abstract class ProjectGrant
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ProjectGrant._({
    this.id,
    required this.projectId,
    required this.userId,
    DateTime? created,
  }) : created = created ?? DateTime.now();

  factory ProjectGrant({
    int? id,
    required int projectId,
    required int userId,
    DateTime? created,
  }) = _ProjectGrantImpl;

  factory ProjectGrant.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectGrant(
      id: jsonSerialization['id'] as int?,
      projectId: jsonSerialization['projectId'] as int,
      userId: jsonSerialization['userId'] as int,
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
    );
  }

  static final t = ProjectGrantTable();

  static const db = ProjectGrantRepository._();

  @override
  int? id;

  int projectId;

  int userId;

  DateTime created;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ProjectGrant]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProjectGrant copyWith({
    int? id,
    int? projectId,
    int? userId,
    DateTime? created,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectGrant',
      if (id != null) 'id': id,
      'projectId': projectId,
      'userId': userId,
      'created': created.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ProjectGrantInclude include() {
    return ProjectGrantInclude._();
  }

  static ProjectGrantIncludeList includeList({
    _is.WhereExpressionBuilder<ProjectGrantTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    ProjectGrantInclude? include,
  }) {
    return ProjectGrantIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectGrantImpl extends ProjectGrant {
  _ProjectGrantImpl({
    int? id,
    required int projectId,
    required int userId,
    DateTime? created,
  }) : super._(id: id, projectId: projectId, userId: userId, created: created);

  /// Returns a shallow copy of this [ProjectGrant]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProjectGrant copyWith({
    Object? id = _Undefined,
    int? projectId,
    int? userId,
    DateTime? created,
  }) {
    return ProjectGrant(
      id: id is int? ? id : this.id,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      created: created ?? this.created,
    );
  }
}

class ProjectGrantUpdateTable extends _is.UpdateTable<ProjectGrantTable> {
  ProjectGrantUpdateTable(super.table);

  _is.ColumnValue<int, int> projectId(int value) =>
      _is.ColumnValue(table.projectId, value);

  _is.ColumnValue<int, int> userId(int value) =>
      _is.ColumnValue(table.userId, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);
}

class ProjectGrantTable extends _is.Table<int?> {
  ProjectGrantTable({super.tableRelation}) : super(tableName: 'project_grant') {
    updateTable = ProjectGrantUpdateTable(this);
    projectId = _is.ColumnInt('projectId', this);
    userId = _is.ColumnInt('userId', this);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
  }

  late final ProjectGrantUpdateTable updateTable;

  late final _is.ColumnInt projectId;

  late final _is.ColumnInt userId;

  late final _is.ColumnDateTime created;

  @override
  List<_is.Column> get columns => [id, projectId, userId, created];
}

class ProjectGrantInclude extends _is.IncludeObject {
  ProjectGrantInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ProjectGrant.t;
}

class ProjectGrantIncludeList extends _is.IncludeList {
  ProjectGrantIncludeList._({
    _is.WhereExpressionBuilder<ProjectGrantTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ProjectGrant.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ProjectGrant.t;
}

class ProjectGrantRepository {
  const ProjectGrantRepository._();

  /// Returns a list of [ProjectGrant]s matching the given query parameters.
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
  Future<List<ProjectGrant>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectGrantTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ProjectGrant>(
      where: where?.call(ProjectGrant.t),
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ProjectGrant] matching the given query parameters.
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
  Future<ProjectGrant?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectGrantTable>? where,
    int? offset,
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ProjectGrant>(
      where: where?.call(ProjectGrant.t),
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ProjectGrant] by its [id] or null if no such row exists.
  Future<ProjectGrant?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ProjectGrant>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ProjectGrant]s in the list and returns the inserted rows.
  ///
  /// The returned [ProjectGrant]s will have their `id` fields set.
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
  Future<List<ProjectGrant>> insert(
    _is.DatabaseSession session,
    List<ProjectGrant> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ProjectGrant>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ProjectGrant] and returns the inserted row.
  ///
  /// The returned [ProjectGrant] will have its `id` field set.
  Future<ProjectGrant> insertRow(
    _is.DatabaseSession session,
    ProjectGrant row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ProjectGrant>(row, transaction: transaction);
  }

  /// Upserts all [ProjectGrant]s in the list and returns the resulting rows.
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
  /// The returned [ProjectGrant]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectGrant>> upsert(
    _is.DatabaseSession session,
    List<ProjectGrant> rows, {
    required _is.ColumnSelections<ProjectGrantTable> conflictColumns,
    _is.ColumnSelections<ProjectGrantTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectGrantTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ProjectGrant>(
      rows,
      conflictColumns: conflictColumns(ProjectGrant.t),
      updateColumns: updateColumns?.call(ProjectGrant.t),
      updateWhere: updateWhere?.call(ProjectGrant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ProjectGrant] and returns the resulting row.
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
  /// The returned [ProjectGrant] will have its `id` field set.
  Future<ProjectGrant?> upsertRow(
    _is.DatabaseSession session,
    ProjectGrant row, {
    required _is.ColumnSelections<ProjectGrantTable> conflictColumns,
    _is.ColumnSelections<ProjectGrantTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectGrantTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ProjectGrant>(
      row,
      conflictColumns: conflictColumns(ProjectGrant.t),
      updateColumns: updateColumns?.call(ProjectGrant.t),
      updateWhere: updateWhere?.call(ProjectGrant.t),
      transaction: transaction,
    );
  }

  /// Updates all [ProjectGrant]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectGrant>> update(
    _is.DatabaseSession session,
    List<ProjectGrant> rows, {
    _is.ColumnSelections<ProjectGrantTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ProjectGrant>(
      rows,
      columns: columns?.call(ProjectGrant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ProjectGrant]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ProjectGrant> updateRow(
    _is.DatabaseSession session,
    ProjectGrant row, {
    _is.ColumnSelections<ProjectGrantTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ProjectGrant>(
      row,
      columns: columns?.call(ProjectGrant.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ProjectGrant] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ProjectGrant?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProjectGrantUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ProjectGrant>(
      id,
      columnValues: columnValues(ProjectGrant.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ProjectGrant]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectGrant>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProjectGrantUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ProjectGrantTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ProjectGrant>(
      columnValues: columnValues(ProjectGrant.t.updateTable),
      where: where(ProjectGrant.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ProjectGrant]s in the list and returns the deleted rows.
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
  Future<List<ProjectGrant>> delete(
    _is.DatabaseSession session,
    List<ProjectGrant> rows, {
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ProjectGrant>(
      rows,
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ProjectGrant].
  Future<ProjectGrant> deleteRow(
    _is.DatabaseSession session,
    ProjectGrant row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ProjectGrant>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ProjectGrant>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectGrantTable> where,
    _is.OrderByBuilder<ProjectGrantTable>? orderBy,
    _is.OrderByListBuilder<ProjectGrantTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ProjectGrant>(
      where: where(ProjectGrant.t),
      orderBy: orderBy?.call(ProjectGrant.t),
      orderByList: orderByList?.call(ProjectGrant.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectGrantTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ProjectGrant>(
      where: where?.call(ProjectGrant.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ProjectGrant] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectGrantTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ProjectGrant>(
      where: where(ProjectGrant.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
