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

/// One in-progress OIDC authorization-code exchange.
///
/// Holds the PKCE code verifier and the nonce between the redirect to the
/// provider and its callback. A table rather than a signed cookie because
/// deleting the row on redemption gives single-use `state` and `nonce` replay
/// protection for free — a TTL cache cannot, since Serverpod's
/// `invalidateKey` does not report whether the key existed, so there is no
/// atomic consume.
abstract class AuthFlow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AuthFlow._({
    this.id,
    required this.state,
    required this.codeVerifier,
    required this.nonce,
    required this.redirectUri,
    DateTime? created,
    required this.expires,
  }) : created = created ?? DateTime.now();

  factory AuthFlow({
    int? id,
    required String state,
    required String codeVerifier,
    required String nonce,
    required String redirectUri,
    DateTime? created,
    required DateTime expires,
  }) = _AuthFlowImpl;

  factory AuthFlow.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthFlow(
      id: jsonSerialization['id'] as int?,
      state: jsonSerialization['state'] as String,
      codeVerifier: jsonSerialization['codeVerifier'] as String,
      nonce: jsonSerialization['nonce'] as String,
      redirectUri: jsonSerialization['redirectUri'] as String,
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      expires: _is.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
    );
  }

  static final t = AuthFlowTable();

  static const db = AuthFlowRepository._();

  @override
  int? id;

  String state;

  String codeVerifier;

  String nonce;

  String redirectUri;

  DateTime created;

  DateTime expires;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuthFlow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuthFlow copyWith({
    int? id,
    String? state,
    String? codeVerifier,
    String? nonce,
    String? redirectUri,
    DateTime? created,
    DateTime? expires,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthFlow',
      if (id != null) 'id': id,
      'state': state,
      'codeVerifier': codeVerifier,
      'nonce': nonce,
      'redirectUri': redirectUri,
      'created': created.toJson(),
      'expires': expires.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AuthFlowInclude include() {
    return AuthFlowInclude._();
  }

  static AuthFlowIncludeList includeList({
    _is.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    AuthFlowInclude? include,
  }) {
    return AuthFlowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthFlowImpl extends AuthFlow {
  _AuthFlowImpl({
    int? id,
    required String state,
    required String codeVerifier,
    required String nonce,
    required String redirectUri,
    DateTime? created,
    required DateTime expires,
  }) : super._(
         id: id,
         state: state,
         codeVerifier: codeVerifier,
         nonce: nonce,
         redirectUri: redirectUri,
         created: created,
         expires: expires,
       );

  /// Returns a shallow copy of this [AuthFlow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuthFlow copyWith({
    Object? id = _Undefined,
    String? state,
    String? codeVerifier,
    String? nonce,
    String? redirectUri,
    DateTime? created,
    DateTime? expires,
  }) {
    return AuthFlow(
      id: id is int? ? id : this.id,
      state: state ?? this.state,
      codeVerifier: codeVerifier ?? this.codeVerifier,
      nonce: nonce ?? this.nonce,
      redirectUri: redirectUri ?? this.redirectUri,
      created: created ?? this.created,
      expires: expires ?? this.expires,
    );
  }
}

class AuthFlowUpdateTable extends _is.UpdateTable<AuthFlowTable> {
  AuthFlowUpdateTable(super.table);

  _is.ColumnValue<String, String> state(String value) =>
      _is.ColumnValue(table.state, value);

  _is.ColumnValue<String, String> codeVerifier(String value) =>
      _is.ColumnValue(table.codeVerifier, value);

  _is.ColumnValue<String, String> nonce(String value) =>
      _is.ColumnValue(table.nonce, value);

  _is.ColumnValue<String, String> redirectUri(String value) =>
      _is.ColumnValue(table.redirectUri, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);

  _is.ColumnValue<DateTime, DateTime> expires(DateTime value) =>
      _is.ColumnValue(table.expires, value);
}

class AuthFlowTable extends _is.Table<int?> {
  AuthFlowTable({super.tableRelation}) : super(tableName: 'auth_flow') {
    updateTable = AuthFlowUpdateTable(this);
    state = _is.ColumnString('state', this);
    codeVerifier = _is.ColumnString('codeVerifier', this);
    nonce = _is.ColumnString('nonce', this);
    redirectUri = _is.ColumnString('redirectUri', this);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
    expires = _is.ColumnDateTime('expires', this);
  }

  late final AuthFlowUpdateTable updateTable;

  late final _is.ColumnString state;

  late final _is.ColumnString codeVerifier;

  late final _is.ColumnString nonce;

  late final _is.ColumnString redirectUri;

  late final _is.ColumnDateTime created;

  late final _is.ColumnDateTime expires;

  @override
  List<_is.Column> get columns => [
    id,
    state,
    codeVerifier,
    nonce,
    redirectUri,
    created,
    expires,
  ];
}

class AuthFlowInclude extends _is.IncludeObject {
  AuthFlowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AuthFlow.t;
}

class AuthFlowIncludeList extends _is.IncludeList {
  AuthFlowIncludeList._({
    _is.WhereExpressionBuilder<AuthFlowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuthFlow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AuthFlow.t;
}

class AuthFlowRepository {
  const AuthFlowRepository._();

  /// Returns a list of [AuthFlow]s matching the given query parameters.
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
  Future<List<AuthFlow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuthFlow>(
      where: where?.call(AuthFlow.t),
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuthFlow] matching the given query parameters.
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
  Future<AuthFlow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthFlowTable>? where,
    int? offset,
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuthFlow>(
      where: where?.call(AuthFlow.t),
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuthFlow] by its [id] or null if no such row exists.
  Future<AuthFlow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuthFlow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuthFlow]s in the list and returns the inserted rows.
  ///
  /// The returned [AuthFlow]s will have their `id` fields set.
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
  Future<List<AuthFlow>> insert(
    _is.DatabaseSession session,
    List<AuthFlow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AuthFlow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AuthFlow] and returns the inserted row.
  ///
  /// The returned [AuthFlow] will have its `id` field set.
  Future<AuthFlow> insertRow(
    _is.DatabaseSession session,
    AuthFlow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuthFlow>(row, transaction: transaction);
  }

  /// Upserts all [AuthFlow]s in the list and returns the resulting rows.
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
  /// The returned [AuthFlow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthFlow>> upsert(
    _is.DatabaseSession session,
    List<AuthFlow> rows, {
    required _is.ColumnSelections<AuthFlowTable> conflictColumns,
    _is.ColumnSelections<AuthFlowTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthFlowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AuthFlow>(
      rows,
      conflictColumns: conflictColumns(AuthFlow.t),
      updateColumns: updateColumns?.call(AuthFlow.t),
      updateWhere: updateWhere?.call(AuthFlow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AuthFlow] and returns the resulting row.
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
  /// The returned [AuthFlow] will have its `id` field set.
  Future<AuthFlow?> upsertRow(
    _is.DatabaseSession session,
    AuthFlow row, {
    required _is.ColumnSelections<AuthFlowTable> conflictColumns,
    _is.ColumnSelections<AuthFlowTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthFlowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AuthFlow>(
      row,
      conflictColumns: conflictColumns(AuthFlow.t),
      updateColumns: updateColumns?.call(AuthFlow.t),
      updateWhere: updateWhere?.call(AuthFlow.t),
      transaction: transaction,
    );
  }

  /// Updates all [AuthFlow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthFlow>> update(
    _is.DatabaseSession session,
    List<AuthFlow> rows, {
    _is.ColumnSelections<AuthFlowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AuthFlow>(
      rows,
      columns: columns?.call(AuthFlow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AuthFlow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuthFlow> updateRow(
    _is.DatabaseSession session,
    AuthFlow row, {
    _is.ColumnSelections<AuthFlowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuthFlow>(
      row,
      columns: columns?.call(AuthFlow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuthFlow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuthFlow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AuthFlowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AuthFlow>(
      id,
      columnValues: columnValues(AuthFlow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuthFlow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthFlow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AuthFlowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AuthFlowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AuthFlow>(
      columnValues: columnValues(AuthFlow.t.updateTable),
      where: where(AuthFlow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AuthFlow]s in the list and returns the deleted rows.
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
  Future<List<AuthFlow>> delete(
    _is.DatabaseSession session,
    List<AuthFlow> rows, {
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AuthFlow>(
      rows,
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AuthFlow].
  Future<AuthFlow> deleteRow(
    _is.DatabaseSession session,
    AuthFlow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuthFlow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthFlow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthFlowTable> where,
    _is.OrderByBuilder<AuthFlowTable>? orderBy,
    _is.OrderByListBuilder<AuthFlowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AuthFlow>(
      where: where(AuthFlow.t),
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AuthFlow>(
      where: where?.call(AuthFlow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuthFlow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthFlowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuthFlow>(
      where: where(AuthFlow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
