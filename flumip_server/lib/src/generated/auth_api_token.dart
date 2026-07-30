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

/// A short-lived bearer token minted from an AuthSession cookie.
///
/// The API server is on a different origin than the app, and Serverpod's
/// browser client sends no cookies (`withCredentials` is false and the server
/// replies `Access-Control-Allow-Origin: *`), so API calls have to authenticate
/// with an `Authorization` header instead. `/auth/session` mints one of these
/// from the cookie and the app keeps it in memory only.
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
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      created: jsonSerialization['created'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      expires: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
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
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuthApiToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
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
    _i1.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthApiTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    AuthApiTokenInclude? include,
  }) {
    return AuthApiTokenIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthApiToken.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AuthApiToken.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
  @_i1.useResult
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

class AuthApiTokenUpdateTable extends _i1.UpdateTable<AuthApiTokenTable> {
  AuthApiTokenUpdateTable(super.table);

  _i1.ColumnValue<int, int> authSessionId(int value) =>
      _i1.ColumnValue(table.authSessionId, value);

  _i1.ColumnValue<String, String> tokenHash(String value) =>
      _i1.ColumnValue(table.tokenHash, value);

  _i1.ColumnValue<String, String> email(String value) =>
      _i1.ColumnValue(table.email, value);

  _i1.ColumnValue<bool, bool> isAdmin(bool value) =>
      _i1.ColumnValue(table.isAdmin, value);

  _i1.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _i1.ColumnValue(table.created, value);

  _i1.ColumnValue<DateTime, DateTime> expires(DateTime value) =>
      _i1.ColumnValue(table.expires, value);
}

class AuthApiTokenTable extends _i1.Table<int?> {
  AuthApiTokenTable({super.tableRelation})
    : super(tableName: 'auth_api_token') {
    updateTable = AuthApiTokenUpdateTable(this);
    authSessionId = _i1.ColumnInt('authSessionId', this);
    tokenHash = _i1.ColumnString('tokenHash', this);
    email = _i1.ColumnString('email', this);
    isAdmin = _i1.ColumnBool('isAdmin', this, hasDefault: true);
    created = _i1.ColumnDateTime('created', this, hasDefault: true);
    expires = _i1.ColumnDateTime('expires', this);
  }

  late final AuthApiTokenUpdateTable updateTable;

  late final _i1.ColumnInt authSessionId;

  late final _i1.ColumnString tokenHash;

  late final _i1.ColumnString email;

  late final _i1.ColumnBool isAdmin;

  late final _i1.ColumnDateTime created;

  late final _i1.ColumnDateTime expires;

  @override
  List<_i1.Column> get columns => [
    id,
    authSessionId,
    tokenHash,
    email,
    isAdmin,
    created,
    expires,
  ];
}

class AuthApiTokenInclude extends _i1.IncludeObject {
  AuthApiTokenInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AuthApiToken.t;
}

class AuthApiTokenIncludeList extends _i1.IncludeList {
  AuthApiTokenIncludeList._({
    _i1.WhereExpressionBuilder<AuthApiTokenTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuthApiToken.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AuthApiToken.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthApiTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      orderDescending: orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? offset,
    _i1.OrderByBuilder<AuthApiTokenTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuthApiToken] by its [id] or null if no such row exists.
  Future<AuthApiToken?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
  Future<List<AuthApiToken>> insert(
    _i1.DatabaseSession session,
    List<AuthApiToken> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AuthApiToken>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AuthApiToken] and returns the inserted row.
  ///
  /// The returned [AuthApiToken] will have its `id` field set.
  Future<AuthApiToken> insertRow(
    _i1.DatabaseSession session,
    AuthApiToken row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuthApiToken>(row, transaction: transaction);
  }

  /// Updates all [AuthApiToken]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AuthApiToken>> update(
    _i1.DatabaseSession session,
    List<AuthApiToken> rows, {
    _i1.ColumnSelections<AuthApiTokenTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AuthApiToken>(
      rows,
      columns: columns?.call(AuthApiToken.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuthApiToken]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuthApiToken> updateRow(
    _i1.DatabaseSession session,
    AuthApiToken row, {
    _i1.ColumnSelections<AuthApiTokenTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AuthApiTokenUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AuthApiToken>(
      id,
      columnValues: columnValues(AuthApiToken.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuthApiToken]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AuthApiToken>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AuthApiTokenUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AuthApiTokenTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthApiTokenTable>? orderBy,
    _i1.OrderByListBuilder<AuthApiTokenTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AuthApiToken>(
      columnValues: columnValues(AuthApiToken.t.updateTable),
      where: where(AuthApiToken.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthApiToken.t),
      orderByList: orderByList?.call(AuthApiToken.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AuthApiToken]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AuthApiToken>> delete(
    _i1.DatabaseSession session,
    List<AuthApiToken> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AuthApiToken>(rows, transaction: transaction);
  }

  /// Deletes a single [AuthApiToken].
  Future<AuthApiToken> deleteRow(
    _i1.DatabaseSession session,
    AuthApiToken row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuthApiToken>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AuthApiToken>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuthApiTokenTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AuthApiToken>(
      where: where(AuthApiToken.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthApiTokenTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AuthApiToken>(
      where: where?.call(AuthApiToken.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuthApiToken] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuthApiTokenTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuthApiToken>(
      where: where(AuthApiToken.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
