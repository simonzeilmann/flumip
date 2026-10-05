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

/// A short-lived bearer token minted from an AuthSession cookie.
///
/// API calls authenticate with an `Authorization` header, not the session
/// cookie. The API is same-origin with the app (the web server answers it under
/// `/api`), so the browser does send the cookie along — but Serverpod's cookie
/// authentication is not configured and ignores it. That is deliberate: a header
/// is never attached by the browser on its own, so no other site can make a
/// signed-in browser call the API. `/auth/session` mints one of these from the
/// cookie and the app keeps it in memory only.
///
/// Why a separate table rather than a `tokenHash` column on AuthSession: two
/// browser tabs both call `/auth/session`, and a single column would mean the
/// second mint invalidates the first tab's token. That tab would then refresh,
/// invalidating the second — a ping-pong that never settles. One row per mint
/// lets every tab hold its own token, and deleting the AuthSession cascades to
/// all of them so revocation stays a single operation.
///
/// `email` and `isAdmin` are denormalised from AuthSession so that the
/// authentication handler needs exactly one indexed lookup per request.
abstract class AuthApiToken
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AuthApiToken._({
    this.id,
    required this.authSessionId,
    required this.tokenHash,
    required this.email,
    bool? isAdmin,
    DateTime? created,
    required this.expires,
  }) : isAdmin = isAdmin ?? false,
       created = created ?? DateTime.now();

  factory AuthApiToken({
    int? id,
    required int authSessionId,
    required String tokenHash,
    required String email,
    bool? isAdmin,
    DateTime? created,
    required DateTime expires,
  }) = _AuthApiTokenImpl;

  factory AuthApiToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthApiToken(
      id: jsonSerialization['id'] as int?,
      authSessionId: jsonSerialization['authSessionId'] as int,
      tokenHash: jsonSerialization['tokenHash'] as String,
      email: jsonSerialization['email'] as String,
      isAdmin: jsonSerialization['isAdmin'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      expires: _is.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
    );
  }

  static final t = AuthApiTokenTable();

  static const db = AuthApiTokenRepository._();

  @override
  int? id;

  int authSessionId;

  String tokenHash;

  String email;

  bool isAdmin;

  DateTime created;

  DateTime expires;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuthApiToken]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuthApiToken copyWith({
    int? id,
    int? authSessionId,
    String? tokenHash,
    String? email,
    bool? isAdmin,
    DateTime? created,
    DateTime? expires,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthApiToken',
      if (id != null) 'id': id,
      'authSessionId': authSessionId,
      'tokenHash': tokenHash,
      'email': email,
      'isAdmin': isAdmin,
      'created': created.toJson(),
      'expires': expires.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AuthApiTokenInclude include() {
    return AuthApiTokenInclude._();
  }

  static AuthApiTokenIncludeList includeList({
    _is.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    AuthApiTokenInclude? include,
  }) {
    return AuthApiTokenIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthApiTokenImpl extends AuthApiToken {
  _AuthApiTokenImpl({
    int? id,
    required int authSessionId,
    required String tokenHash,
    required String email,
    bool? isAdmin,
    DateTime? created,
    required DateTime expires,
  }) : super._(
         id: id,
         authSessionId: authSessionId,
         tokenHash: tokenHash,
         email: email,
         isAdmin: isAdmin,
         created: created,
         expires: expires,
       );

  /// Returns a shallow copy of this [AuthApiToken]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuthApiToken copyWith({
    Object? id = _Undefined,
    int? authSessionId,
    String? tokenHash,
    String? email,
    bool? isAdmin,
    DateTime? created,
    DateTime? expires,
  }) {
    return AuthApiToken(
      id: id is int? ? id : this.id,
      authSessionId: authSessionId ?? this.authSessionId,
      tokenHash: tokenHash ?? this.tokenHash,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      created: created ?? this.created,
      expires: expires ?? this.expires,
    );
  }
}

class AuthApiTokenUpdateTable extends _is.UpdateTable<AuthApiTokenTable> {
  AuthApiTokenUpdateTable(super.table);

  _is.ColumnValue<int, int> authSessionId(int value) =>
      _is.ColumnValue(table.authSessionId, value);

  _is.ColumnValue<String, String> tokenHash(String value) =>
      _is.ColumnValue(table.tokenHash, value);

  _is.ColumnValue<String, String> email(String value) =>
      _is.ColumnValue(table.email, value);

  _is.ColumnValue<bool, bool> isAdmin(bool value) =>
      _is.ColumnValue(table.isAdmin, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);

  _is.ColumnValue<DateTime, DateTime> expires(DateTime value) =>
      _is.ColumnValue(table.expires, value);
}

class AuthApiTokenTable extends _is.Table<int?> {
  AuthApiTokenTable({super.tableRelation})
    : super(tableName: 'auth_api_token') {
    updateTable = AuthApiTokenUpdateTable(this);
    authSessionId = _is.ColumnInt('authSessionId', this);
    tokenHash = _is.ColumnString('tokenHash', this);
    email = _is.ColumnString('email', this);
    isAdmin = _is.ColumnBool('isAdmin', this, hasDefault: true);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
    expires = _is.ColumnDateTime('expires', this);
  }

  late final AuthApiTokenUpdateTable updateTable;

  late final _is.ColumnInt authSessionId;

  late final _is.ColumnString tokenHash;

  late final _is.ColumnString email;

  late final _is.ColumnBool isAdmin;

  late final _is.ColumnDateTime created;

  late final _is.ColumnDateTime expires;

  @override
  List<_is.Column> get columns => [
    id,
    authSessionId,
    tokenHash,
    email,
    isAdmin,
    created,
    expires,
  ];
}

class AuthApiTokenInclude extends _is.IncludeObject {
  AuthApiTokenInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AuthApiToken.t;
}

class AuthApiTokenIncludeList extends _is.IncludeList {
  AuthApiTokenIncludeList._({
    _is.WhereExpressionBuilder<AuthApiTokenTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuthApiToken.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AuthApiToken.t;
}

class AuthApiTokenRepository {
  const AuthApiTokenRepository._();

  /// Returns a list of [AuthApiToken]s matching the given query parameters.
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
  Future<List<AuthApiToken>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuthApiToken] matching the given query parameters.
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
  Future<AuthApiToken?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? offset,
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuthApiToken] by its [id] or null if no such row exists.
  Future<AuthApiToken?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuthApiToken>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuthApiToken]s in the list and returns the inserted rows.
  ///
  /// The returned [AuthApiToken]s will have their `id` fields set.
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
  Future<List<AuthApiToken>> insert(
    _is.DatabaseSession session,
    List<AuthApiToken> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AuthApiToken>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AuthApiToken] and returns the inserted row.
  ///
  /// The returned [AuthApiToken] will have its `id` field set.
  Future<AuthApiToken> insertRow(
    _is.DatabaseSession session,
    AuthApiToken row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuthApiToken>(row, transaction: transaction);
  }

  /// Upserts all [AuthApiToken]s in the list and returns the resulting rows.
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
  /// The returned [AuthApiToken]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthApiToken>> upsert(
    _is.DatabaseSession session,
    List<AuthApiToken> rows, {
    required _is.ColumnSelections<AuthApiTokenTable> conflictColumns,
    _is.ColumnSelections<AuthApiTokenTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthApiTokenTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AuthApiToken>(
      rows,
      conflictColumns: conflictColumns(AuthApiToken.t),
      updateColumns: updateColumns?.call(AuthApiToken.t),
      updateWhere: updateWhere?.call(AuthApiToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AuthApiToken] and returns the resulting row.
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
  /// The returned [AuthApiToken] will have its `id` field set.
  Future<AuthApiToken?> upsertRow(
    _is.DatabaseSession session,
    AuthApiToken row, {
    required _is.ColumnSelections<AuthApiTokenTable> conflictColumns,
    _is.ColumnSelections<AuthApiTokenTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthApiTokenTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AuthApiToken>(
      row,
      conflictColumns: conflictColumns(AuthApiToken.t),
      updateColumns: updateColumns?.call(AuthApiToken.t),
      updateWhere: updateWhere?.call(AuthApiToken.t),
      transaction: transaction,
    );
  }

  /// Updates all [AuthApiToken]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthApiToken>> update(
    _is.DatabaseSession session,
    List<AuthApiToken> rows, {
    _is.ColumnSelections<AuthApiTokenTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AuthApiToken>(
      rows,
      columns: columns?.call(AuthApiToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AuthApiToken]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuthApiToken> updateRow(
    _is.DatabaseSession session,
    AuthApiToken row, {
    _is.ColumnSelections<AuthApiTokenTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuthApiToken>(
      row,
      columns: columns?.call(AuthApiToken.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuthApiToken] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuthApiToken?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AuthApiTokenUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AuthApiToken>(
      id,
      columnValues: columnValues(AuthApiToken.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuthApiToken]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthApiToken>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AuthApiTokenUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AuthApiTokenTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AuthApiToken>(
      columnValues: columnValues(AuthApiToken.t.updateTable),
      where: where(AuthApiToken.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AuthApiToken]s in the list and returns the deleted rows.
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
  Future<List<AuthApiToken>> delete(
    _is.DatabaseSession session,
    List<AuthApiToken> rows, {
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AuthApiToken>(
      rows,
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AuthApiToken].
  Future<AuthApiToken> deleteRow(
    _is.DatabaseSession session,
    AuthApiToken row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuthApiToken>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthApiToken>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthApiTokenTable> where,
    _is.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _is.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AuthApiToken>(
      where: where(AuthApiToken.t),
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuthApiToken] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthApiTokenTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuthApiToken>(
      where: where(AuthApiToken.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
