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

/// One in-progress OIDC authorization-code exchange.
///
/// Holds the PKCE code verifier and the nonce between the redirect to the
/// provider and its callback. A table rather than a signed cookie because
/// deleting the row on redemption gives single-use `state` and `nonce` replay
/// protection for free — a TTL cache cannot, since Serverpod's
/// `invalidateKey` does not report whether the key existed, so there is no
/// atomic consume.
abstract class AuthFlow
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      expires: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expires']),
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
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuthFlow]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
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
    _i1.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthFlowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthFlowTable>? orderByList,
    AuthFlowInclude? include,
  }) {
    return AuthFlowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthFlow.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AuthFlow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
  @_i1.useResult
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

class AuthFlowUpdateTable extends _i1.UpdateTable<AuthFlowTable> {
  AuthFlowUpdateTable(super.table);

  _i1.ColumnValue<String, String> state(String value) =>
      _i1.ColumnValue(table.state, value);

  _i1.ColumnValue<String, String> codeVerifier(String value) =>
      _i1.ColumnValue(table.codeVerifier, value);

  _i1.ColumnValue<String, String> nonce(String value) =>
      _i1.ColumnValue(table.nonce, value);

  _i1.ColumnValue<String, String> redirectUri(String value) =>
      _i1.ColumnValue(table.redirectUri, value);

  _i1.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _i1.ColumnValue(table.created, value);

  _i1.ColumnValue<DateTime, DateTime> expires(DateTime value) =>
      _i1.ColumnValue(table.expires, value);
}

class AuthFlowTable extends _i1.Table<int?> {
  AuthFlowTable({super.tableRelation}) : super(tableName: 'auth_flow') {
    updateTable = AuthFlowUpdateTable(this);
    state = _i1.ColumnString('state', this);
    codeVerifier = _i1.ColumnString('codeVerifier', this);
    nonce = _i1.ColumnString('nonce', this);
    redirectUri = _i1.ColumnString('redirectUri', this);
    created = _i1.ColumnDateTime('created', this, hasDefault: true);
    expires = _i1.ColumnDateTime('expires', this);
  }

  late final AuthFlowUpdateTable updateTable;

  late final _i1.ColumnString state;

  late final _i1.ColumnString codeVerifier;

  late final _i1.ColumnString nonce;

  late final _i1.ColumnString redirectUri;

  late final _i1.ColumnDateTime created;

  late final _i1.ColumnDateTime expires;

  @override
  List<_i1.Column> get columns => [
    id,
    state,
    codeVerifier,
    nonce,
    redirectUri,
    created,
    expires,
  ];
}

class AuthFlowInclude extends _i1.IncludeObject {
  AuthFlowInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AuthFlow.t;
}

class AuthFlowIncludeList extends _i1.IncludeList {
  AuthFlowIncludeList._({
    _i1.WhereExpressionBuilder<AuthFlowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuthFlow.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AuthFlow.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthFlowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthFlowTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuthFlow>(
      where: where?.call(AuthFlow.t),
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      orderDescending: orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthFlowTable>? where,
    int? offset,
    _i1.OrderByBuilder<AuthFlowTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AuthFlowTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuthFlow>(
      where: where?.call(AuthFlow.t),
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuthFlow] by its [id] or null if no such row exists.
  Future<AuthFlow?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
  Future<List<AuthFlow>> insert(
    _i1.DatabaseSession session,
    List<AuthFlow> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AuthFlow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AuthFlow] and returns the inserted row.
  ///
  /// The returned [AuthFlow] will have its `id` field set.
  Future<AuthFlow> insertRow(
    _i1.DatabaseSession session,
    AuthFlow row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuthFlow>(row, transaction: transaction);
  }

  /// Updates all [AuthFlow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AuthFlow>> update(
    _i1.DatabaseSession session,
    List<AuthFlow> rows, {
    _i1.ColumnSelections<AuthFlowTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AuthFlow>(
      rows,
      columns: columns?.call(AuthFlow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuthFlow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuthFlow> updateRow(
    _i1.DatabaseSession session,
    AuthFlow row, {
    _i1.ColumnSelections<AuthFlowTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AuthFlowUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AuthFlow>(
      id,
      columnValues: columnValues(AuthFlow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuthFlow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AuthFlow>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AuthFlowUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AuthFlowTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AuthFlowTable>? orderBy,
    _i1.OrderByListBuilder<AuthFlowTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AuthFlow>(
      columnValues: columnValues(AuthFlow.t.updateTable),
      where: where(AuthFlow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuthFlow.t),
      orderByList: orderByList?.call(AuthFlow.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AuthFlow]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AuthFlow>> delete(
    _i1.DatabaseSession session,
    List<AuthFlow> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AuthFlow>(rows, transaction: transaction);
  }

  /// Deletes a single [AuthFlow].
  Future<AuthFlow> deleteRow(
    _i1.DatabaseSession session,
    AuthFlow row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuthFlow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AuthFlow>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuthFlowTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AuthFlow>(
      where: where(AuthFlow.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AuthFlowTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AuthFlow>(
      where: where?.call(AuthFlow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuthFlow] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AuthFlowTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuthFlow>(
      where: where(AuthFlow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
