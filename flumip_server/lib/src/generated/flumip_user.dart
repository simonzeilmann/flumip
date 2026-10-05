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
import 'package:flumip_server/src/generated/protocol.dart' as _ijyeyqvr;
import 'package:serverpod/serverpod.dart' as _is;

/// An identity that has signed in through the configured OIDC provider.
///
/// Created on first sign-in and reused afterwards. `issuer` + `subject` is the
/// identity key, because that is the only pair the spec guarantees to be stable
/// and unique; `email` is treated as a mutable attribute and is deliberately
/// *not* unique, so that moving an install to a different IdP does not fail on
/// a constraint the first time a known user signs in against the new one.
///
/// serverOnly: nothing here is client-facing. The app receives AuthUserDto.
abstract class FlumipUser
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  FlumipUser._({
    this.id,
    required this.email,
    required this.subject,
    required this.issuer,
    String? displayName,
    this.departments,
    DateTime? created,
    DateTime? lastLogin,
  }) : displayName = displayName ?? '',
       created = created ?? DateTime.now(),
       lastLogin = lastLogin ?? DateTime.now();

  factory FlumipUser({
    int? id,
    required String email,
    required String subject,
    required String issuer,
    String? displayName,
    List<String>? departments,
    DateTime? created,
    DateTime? lastLogin,
  }) = _FlumipUserImpl;

  factory FlumipUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return FlumipUser(
      id: jsonSerialization['id'] as int?,
      email: jsonSerialization['email'] as String,
      subject: jsonSerialization['subject'] as String,
      issuer: jsonSerialization['issuer'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      departments: jsonSerialization['departments'] == null
          ? null
          : _ijyeyqvr.Protocol().deserialize<List<String>>(
              jsonSerialization['departments'],
            ),
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      lastLogin: jsonSerialization['lastLogin'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['lastLogin']),
    );
  }

  static final t = FlumipUserTable();

  static const db = FlumipUserRepository._();

  @override
  int? id;

  String email;

  String subject;

  String issuer;

  String displayName;

  /// The groups the identity provider reported at the last sign-in.
  ///
  /// Null on every row that predates this, and on every install where
  /// `Settings.oidcDepartmentClaim` is empty. Refreshed on each sign-in, so a
  /// change in the provider takes effect the next time somebody signs in —
  /// the same rule `AuthSession.isAdmin` already follows.
  List<String>? departments;

  DateTime created;

  DateTime lastLogin;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [FlumipUser]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FlumipUser copyWith({
    int? id,
    String? email,
    String? subject,
    String? issuer,
    String? displayName,
    List<String>? departments,
    DateTime? created,
    DateTime? lastLogin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FlumipUser',
      if (id != null) 'id': id,
      'email': email,
      'subject': subject,
      'issuer': issuer,
      'displayName': displayName,
      if (departments != null) 'departments': departments?.toJson(),
      'created': created.toJson(),
      'lastLogin': lastLogin.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static FlumipUserInclude include() {
    return FlumipUserInclude._();
  }

  static FlumipUserIncludeList includeList({
    _is.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    FlumipUserInclude? include,
  }) {
    return FlumipUserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FlumipUserImpl extends FlumipUser {
  _FlumipUserImpl({
    int? id,
    required String email,
    required String subject,
    required String issuer,
    String? displayName,
    List<String>? departments,
    DateTime? created,
    DateTime? lastLogin,
  }) : super._(
         id: id,
         email: email,
         subject: subject,
         issuer: issuer,
         displayName: displayName,
         departments: departments,
         created: created,
         lastLogin: lastLogin,
       );

  /// Returns a shallow copy of this [FlumipUser]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FlumipUser copyWith({
    Object? id = _Undefined,
    String? email,
    String? subject,
    String? issuer,
    String? displayName,
    Object? departments = _Undefined,
    DateTime? created,
    DateTime? lastLogin,
  }) {
    return FlumipUser(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      issuer: issuer ?? this.issuer,
      displayName: displayName ?? this.displayName,
      departments: departments is List<String>?
          ? departments
          : this.departments?.map((e0) => e0).toList(),
      created: created ?? this.created,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

class FlumipUserUpdateTable extends _is.UpdateTable<FlumipUserTable> {
  FlumipUserUpdateTable(super.table);

  _is.ColumnValue<String, String> email(String value) =>
      _is.ColumnValue(table.email, value);

  _is.ColumnValue<String, String> subject(String value) =>
      _is.ColumnValue(table.subject, value);

  _is.ColumnValue<String, String> issuer(String value) =>
      _is.ColumnValue(table.issuer, value);

  _is.ColumnValue<String, String> displayName(String value) =>
      _is.ColumnValue(table.displayName, value);

  _is.ColumnValue<List<String>, List<String>> departments(
    List<String>? value,
  ) => _is.ColumnValue(table.departments, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);

  _is.ColumnValue<DateTime, DateTime> lastLogin(DateTime value) =>
      _is.ColumnValue(table.lastLogin, value);
}

class FlumipUserTable extends _is.Table<int?> {
  FlumipUserTable({super.tableRelation}) : super(tableName: 'flumip_user') {
    updateTable = FlumipUserUpdateTable(this);
    email = _is.ColumnString('email', this);
    subject = _is.ColumnString('subject', this);
    issuer = _is.ColumnString('issuer', this);
    displayName = _is.ColumnString('displayName', this, hasDefault: true);
    departments = _is.ColumnSerializable<List<String>>('departments', this);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
    lastLogin = _is.ColumnDateTime('lastLogin', this, hasDefault: true);
  }

  late final FlumipUserUpdateTable updateTable;

  late final _is.ColumnString email;

  late final _is.ColumnString subject;

  late final _is.ColumnString issuer;

  late final _is.ColumnString displayName;

  /// The groups the identity provider reported at the last sign-in.
  ///
  /// Null on every row that predates this, and on every install where
  /// `Settings.oidcDepartmentClaim` is empty. Refreshed on each sign-in, so a
  /// change in the provider takes effect the next time somebody signs in —
  /// the same rule `AuthSession.isAdmin` already follows.
  late final _is.ColumnSerializable<List<String>> departments;

  late final _is.ColumnDateTime created;

  late final _is.ColumnDateTime lastLogin;

  @override
  List<_is.Column> get columns => [
    id,
    email,
    subject,
    issuer,
    displayName,
    departments,
    created,
    lastLogin,
  ];
}

class FlumipUserInclude extends _is.IncludeObject {
  FlumipUserInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => FlumipUser.t;
}

class FlumipUserIncludeList extends _is.IncludeList {
  FlumipUserIncludeList._({
    _is.WhereExpressionBuilder<FlumipUserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FlumipUser.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => FlumipUser.t;
}

class FlumipUserRepository {
  const FlumipUserRepository._();

  /// Returns a list of [FlumipUser]s matching the given query parameters.
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
  Future<List<FlumipUser>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FlumipUser>(
      where: where?.call(FlumipUser.t),
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FlumipUser] matching the given query parameters.
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
  Future<FlumipUser?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FlumipUserTable>? where,
    int? offset,
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FlumipUser>(
      where: where?.call(FlumipUser.t),
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FlumipUser] by its [id] or null if no such row exists.
  Future<FlumipUser?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FlumipUser>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FlumipUser]s in the list and returns the inserted rows.
  ///
  /// The returned [FlumipUser]s will have their `id` fields set.
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
  Future<List<FlumipUser>> insert(
    _is.DatabaseSession session,
    List<FlumipUser> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FlumipUser>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FlumipUser] and returns the inserted row.
  ///
  /// The returned [FlumipUser] will have its `id` field set.
  Future<FlumipUser> insertRow(
    _is.DatabaseSession session,
    FlumipUser row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FlumipUser>(row, transaction: transaction);
  }

  /// Upserts all [FlumipUser]s in the list and returns the resulting rows.
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
  /// The returned [FlumipUser]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FlumipUser>> upsert(
    _is.DatabaseSession session,
    List<FlumipUser> rows, {
    required _is.ColumnSelections<FlumipUserTable> conflictColumns,
    _is.ColumnSelections<FlumipUserTable>? updateColumns,
    _is.WhereExpressionBuilder<FlumipUserTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FlumipUser>(
      rows,
      conflictColumns: conflictColumns(FlumipUser.t),
      updateColumns: updateColumns?.call(FlumipUser.t),
      updateWhere: updateWhere?.call(FlumipUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FlumipUser] and returns the resulting row.
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
  /// The returned [FlumipUser] will have its `id` field set.
  Future<FlumipUser?> upsertRow(
    _is.DatabaseSession session,
    FlumipUser row, {
    required _is.ColumnSelections<FlumipUserTable> conflictColumns,
    _is.ColumnSelections<FlumipUserTable>? updateColumns,
    _is.WhereExpressionBuilder<FlumipUserTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FlumipUser>(
      row,
      conflictColumns: conflictColumns(FlumipUser.t),
      updateColumns: updateColumns?.call(FlumipUser.t),
      updateWhere: updateWhere?.call(FlumipUser.t),
      transaction: transaction,
    );
  }

  /// Updates all [FlumipUser]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FlumipUser>> update(
    _is.DatabaseSession session,
    List<FlumipUser> rows, {
    _is.ColumnSelections<FlumipUserTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FlumipUser>(
      rows,
      columns: columns?.call(FlumipUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FlumipUser]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FlumipUser> updateRow(
    _is.DatabaseSession session,
    FlumipUser row, {
    _is.ColumnSelections<FlumipUserTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FlumipUser>(
      row,
      columns: columns?.call(FlumipUser.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FlumipUser] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FlumipUser?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FlumipUserUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FlumipUser>(
      id,
      columnValues: columnValues(FlumipUser.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FlumipUser]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FlumipUser>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FlumipUserUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FlumipUserTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FlumipUser>(
      columnValues: columnValues(FlumipUser.t.updateTable),
      where: where(FlumipUser.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FlumipUser]s in the list and returns the deleted rows.
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
  Future<List<FlumipUser>> delete(
    _is.DatabaseSession session,
    List<FlumipUser> rows, {
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FlumipUser>(
      rows,
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FlumipUser].
  Future<FlumipUser> deleteRow(
    _is.DatabaseSession session,
    FlumipUser row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FlumipUser>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FlumipUser>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FlumipUserTable> where,
    _is.OrderByBuilder<FlumipUserTable>? orderBy,
    _is.OrderByListBuilder<FlumipUserTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FlumipUser>(
      where: where(FlumipUser.t),
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FlumipUser>(
      where: where?.call(FlumipUser.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FlumipUser] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FlumipUserTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FlumipUser>(
      where: where(FlumipUser.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
