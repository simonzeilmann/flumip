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

/// A signed-in browser session, keyed by the `flumip_auth` cookie.
///
/// This is the durable half of the credential. The cookie is HttpOnly, so the
/// Flutter app cannot read it; the app trades it for a short-lived bearer at
/// `/auth/session` (see AuthApiToken). Only the sha256 of the cookie value is
/// stored, so a database dump does not yield usable credentials.
///
/// `email` and `isAdmin` are denormalised from FlumipUser and the allowlist as
/// they stood at sign-in time, so that authenticating a request needs no join.
/// Changing the admin list therefore takes effect on the next sign-in.
abstract class AuthSession
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AuthSession._({
    this.id,
    required this.userId,
    required this.cookieHash,
    required this.email,
    bool? isAdmin,
    DateTime? created,
    required this.expires,
    DateTime? lastSeen,
  }) : isAdmin = isAdmin ?? false,
       created = created ?? DateTime.now(),
       lastSeen = lastSeen ?? DateTime.now();

  factory AuthSession({
    int? id,
    required int userId,
    required String cookieHash,
    required String email,
    bool? isAdmin,
    DateTime? created,
    required DateTime expires,
    DateTime? lastSeen,
  }) = _AuthSessionImpl;

  factory AuthSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      cookieHash: jsonSerialization['cookieHash'] as String,
      email: jsonSerialization['email'] as String,
      isAdmin: jsonSerialization['isAdmin'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      expires: _is.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
      lastSeen: jsonSerialization['lastSeen'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeen']),
    );
  }

  static final t = AuthSessionTable();

  static const db = AuthSessionRepository._();

  @override
  int? id;

  int userId;

  String cookieHash;

  String email;

  bool isAdmin;

  DateTime created;

  DateTime expires;

  DateTime lastSeen;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuthSession]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuthSession copyWith({
    int? id,
    int? userId,
    String? cookieHash,
    String? email,
    bool? isAdmin,
    DateTime? created,
    DateTime? expires,
    DateTime? lastSeen,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthSession',
      if (id != null) 'id': id,
      'userId': userId,
      'cookieHash': cookieHash,
      'email': email,
      'isAdmin': isAdmin,
      'created': created.toJson(),
      'expires': expires.toJson(),
      'lastSeen': lastSeen.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AuthSessionInclude include() {
    return AuthSessionInclude._();
  }

  static AuthSessionIncludeList includeList({
    _is.WhereExpressionBuilder<AuthSessionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    AuthSessionInclude? include,
  }) {
    return AuthSessionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthSessionImpl extends AuthSession {
  _AuthSessionImpl({
    int? id,
    required int userId,
    required String cookieHash,
    required String email,
    bool? isAdmin,
    DateTime? created,
    required DateTime expires,
    DateTime? lastSeen,
  }) : super._(
         id: id,
         userId: userId,
         cookieHash: cookieHash,
         email: email,
         isAdmin: isAdmin,
         created: created,
         expires: expires,
         lastSeen: lastSeen,
       );

  /// Returns a shallow copy of this [AuthSession]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuthSession copyWith({
    Object? id = _Undefined,
    int? userId,
    String? cookieHash,
    String? email,
    bool? isAdmin,
    DateTime? created,
    DateTime? expires,
    DateTime? lastSeen,
  }) {
    return AuthSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      cookieHash: cookieHash ?? this.cookieHash,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      created: created ?? this.created,
      expires: expires ?? this.expires,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

class AuthSessionUpdateTable extends _is.UpdateTable<AuthSessionTable> {
  AuthSessionUpdateTable(super.table);

  _is.ColumnValue<int, int> userId(int value) =>
      _is.ColumnValue(table.userId, value);

  _is.ColumnValue<String, String> cookieHash(String value) =>
      _is.ColumnValue(table.cookieHash, value);

  _is.ColumnValue<String, String> email(String value) =>
      _is.ColumnValue(table.email, value);

  _is.ColumnValue<bool, bool> isAdmin(bool value) =>
      _is.ColumnValue(table.isAdmin, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);

  _is.ColumnValue<DateTime, DateTime> expires(DateTime value) =>
      _is.ColumnValue(table.expires, value);

  _is.ColumnValue<DateTime, DateTime> lastSeen(DateTime value) =>
      _is.ColumnValue(table.lastSeen, value);
}

class AuthSessionTable extends _is.Table<int?> {
  AuthSessionTable({super.tableRelation}) : super(tableName: 'auth_session') {
    updateTable = AuthSessionUpdateTable(this);
    userId = _is.ColumnInt('userId', this);
    cookieHash = _is.ColumnString('cookieHash', this);
    email = _is.ColumnString('email', this);
    isAdmin = _is.ColumnBool('isAdmin', this, hasDefault: true);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
    expires = _is.ColumnDateTime('expires', this);
    lastSeen = _is.ColumnDateTime('lastSeen', this, hasDefault: true);
  }

  late final AuthSessionUpdateTable updateTable;

  late final _is.ColumnInt userId;

  late final _is.ColumnString cookieHash;

  late final _is.ColumnString email;

  late final _is.ColumnBool isAdmin;

  late final _is.ColumnDateTime created;

  late final _is.ColumnDateTime expires;

  late final _is.ColumnDateTime lastSeen;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    cookieHash,
    email,
    isAdmin,
    created,
    expires,
    lastSeen,
  ];
}

class AuthSessionInclude extends _is.IncludeObject {
  AuthSessionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AuthSession.t;
}

class AuthSessionIncludeList extends _is.IncludeList {
  AuthSessionIncludeList._({
    _is.WhereExpressionBuilder<AuthSessionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuthSession.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AuthSession.t;
}

class AuthSessionRepository {
  const AuthSessionRepository._();

  /// Returns a list of [AuthSession]s matching the given query parameters.
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
  Future<List<AuthSession>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthSessionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuthSession>(
      where: where?.call(AuthSession.t),
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuthSession] matching the given query parameters.
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
  Future<AuthSession?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthSessionTable>? where,
    int? offset,
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuthSession>(
      where: where?.call(AuthSession.t),
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuthSession] by its [id] or null if no such row exists.
  Future<AuthSession?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuthSession>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuthSession]s in the list and returns the inserted rows.
  ///
  /// The returned [AuthSession]s will have their `id` fields set.
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
  Future<List<AuthSession>> insert(
    _is.DatabaseSession session,
    List<AuthSession> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AuthSession>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AuthSession] and returns the inserted row.
  ///
  /// The returned [AuthSession] will have its `id` field set.
  Future<AuthSession> insertRow(
    _is.DatabaseSession session,
    AuthSession row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuthSession>(row, transaction: transaction);
  }

  /// Upserts all [AuthSession]s in the list and returns the resulting rows.
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
  /// The returned [AuthSession]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthSession>> upsert(
    _is.DatabaseSession session,
    List<AuthSession> rows, {
    required _is.ColumnSelections<AuthSessionTable> conflictColumns,
    _is.ColumnSelections<AuthSessionTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthSessionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AuthSession>(
      rows,
      conflictColumns: conflictColumns(AuthSession.t),
      updateColumns: updateColumns?.call(AuthSession.t),
      updateWhere: updateWhere?.call(AuthSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AuthSession] and returns the resulting row.
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
  /// The returned [AuthSession] will have its `id` field set.
  Future<AuthSession?> upsertRow(
    _is.DatabaseSession session,
    AuthSession row, {
    required _is.ColumnSelections<AuthSessionTable> conflictColumns,
    _is.ColumnSelections<AuthSessionTable>? updateColumns,
    _is.WhereExpressionBuilder<AuthSessionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AuthSession>(
      row,
      conflictColumns: conflictColumns(AuthSession.t),
      updateColumns: updateColumns?.call(AuthSession.t),
      updateWhere: updateWhere?.call(AuthSession.t),
      transaction: transaction,
    );
  }

  /// Updates all [AuthSession]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthSession>> update(
    _is.DatabaseSession session,
    List<AuthSession> rows, {
    _is.ColumnSelections<AuthSessionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AuthSession>(
      rows,
      columns: columns?.call(AuthSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AuthSession]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuthSession> updateRow(
    _is.DatabaseSession session,
    AuthSession row, {
    _is.ColumnSelections<AuthSessionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuthSession>(
      row,
      columns: columns?.call(AuthSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuthSession] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuthSession?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AuthSessionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AuthSession>(
      id,
      columnValues: columnValues(AuthSession.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuthSession]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthSession>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AuthSessionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AuthSessionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AuthSession>(
      columnValues: columnValues(AuthSession.t.updateTable),
      where: where(AuthSession.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AuthSession]s in the list and returns the deleted rows.
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
  Future<List<AuthSession>> delete(
    _is.DatabaseSession session,
    List<AuthSession> rows, {
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AuthSession>(
      rows,
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AuthSession].
  Future<AuthSession> deleteRow(
    _is.DatabaseSession session,
    AuthSession row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuthSession>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuthSession>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthSessionTable> where,
    _is.OrderByBuilder<AuthSessionTable>? orderBy,
    _is.OrderByListBuilder<AuthSessionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AuthSession>(
      where: where(AuthSession.t),
      orderBy: orderBy?.call(AuthSession.t),
      orderByList: orderByList?.call(AuthSession.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuthSessionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AuthSession>(
      where: where?.call(AuthSession.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuthSession] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuthSessionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuthSession>(
      where: where(AuthSession.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
