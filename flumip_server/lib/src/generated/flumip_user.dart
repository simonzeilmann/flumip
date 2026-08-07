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
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  FlumipUser._({
    this.id,
    required this.email,
    required this.subject,
    required this.issuer,
    String? displayName,
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
      created: jsonSerialization['created'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      lastLogin: jsonSerialization['lastLogin'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastLogin']),
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

  DateTime created;

  DateTime lastLogin;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [FlumipUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FlumipUser copyWith({
    int? id,
    String? email,
    String? subject,
    String? issuer,
    String? displayName,
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
    _i1.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FlumipUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FlumipUserTable>? orderByList,
    FlumipUserInclude? include,
  }) {
    return FlumipUserIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FlumipUser.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FlumipUser.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
    DateTime? created,
    DateTime? lastLogin,
  }) : super._(
         id: id,
         email: email,
         subject: subject,
         issuer: issuer,
         displayName: displayName,
         created: created,
         lastLogin: lastLogin,
       );

  /// Returns a shallow copy of this [FlumipUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FlumipUser copyWith({
    Object? id = _Undefined,
    String? email,
    String? subject,
    String? issuer,
    String? displayName,
    DateTime? created,
    DateTime? lastLogin,
  }) {
    return FlumipUser(
      id: id is int? ? id : this.id,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      issuer: issuer ?? this.issuer,
      displayName: displayName ?? this.displayName,
      created: created ?? this.created,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

class FlumipUserUpdateTable extends _i1.UpdateTable<FlumipUserTable> {
  FlumipUserUpdateTable(super.table);

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> subject(String value) => _i1.ColumnValue(
    table.subject,
    value,
  );

  _i1.ColumnValue<String, String> issuer(String value) => _i1.ColumnValue(
    table.issuer,
    value,
  );

  _i1.ColumnValue<String, String> displayName(String value) => _i1.ColumnValue(
    table.displayName,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _i1.ColumnValue(
        table.created,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastLogin(DateTime value) =>
      _i1.ColumnValue(
        table.lastLogin,
        value,
      );
}

class FlumipUserTable extends _i1.Table<int?> {
  FlumipUserTable({super.tableRelation}) : super(tableName: 'flumip_user') {
    updateTable = FlumipUserUpdateTable(this);
    email = _i1.ColumnString(
      'email',
      this,
    );
    subject = _i1.ColumnString(
      'subject',
      this,
    );
    issuer = _i1.ColumnString(
      'issuer',
      this,
    );
    displayName = _i1.ColumnString(
      'displayName',
      this,
      hasDefault: true,
    );
    created = _i1.ColumnDateTime(
      'created',
      this,
      hasDefault: true,
    );
    lastLogin = _i1.ColumnDateTime(
      'lastLogin',
      this,
      hasDefault: true,
    );
  }

  late final FlumipUserUpdateTable updateTable;

  late final _i1.ColumnString email;

  late final _i1.ColumnString subject;

  late final _i1.ColumnString issuer;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnDateTime created;

  late final _i1.ColumnDateTime lastLogin;

  @override
  List<_i1.Column> get columns => [
    id,
    email,
    subject,
    issuer,
    displayName,
    created,
    lastLogin,
  ];
}

class FlumipUserInclude extends _i1.IncludeObject {
  FlumipUserInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => FlumipUser.t;
}

class FlumipUserIncludeList extends _i1.IncludeList {
  FlumipUserIncludeList._({
    _i1.WhereExpressionBuilder<FlumipUserTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FlumipUser.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => FlumipUser.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FlumipUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FlumipUserTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FlumipUser>(
      where: where?.call(FlumipUser.t),
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      orderDescending: orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FlumipUserTable>? where,
    int? offset,
    _i1.OrderByBuilder<FlumipUserTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FlumipUserTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FlumipUser>(
      where: where?.call(FlumipUser.t),
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FlumipUser] by its [id] or null if no such row exists.
  Future<FlumipUser?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
  Future<List<FlumipUser>> insert(
    _i1.DatabaseSession session,
    List<FlumipUser> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<FlumipUser>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [FlumipUser] and returns the inserted row.
  ///
  /// The returned [FlumipUser] will have its `id` field set.
  Future<FlumipUser> insertRow(
    _i1.DatabaseSession session,
    FlumipUser row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FlumipUser>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FlumipUser]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FlumipUser>> update(
    _i1.DatabaseSession session,
    List<FlumipUser> rows, {
    _i1.ColumnSelections<FlumipUserTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FlumipUser>(
      rows,
      columns: columns?.call(FlumipUser.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FlumipUser]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FlumipUser> updateRow(
    _i1.DatabaseSession session,
    FlumipUser row, {
    _i1.ColumnSelections<FlumipUserTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<FlumipUserUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<FlumipUser>(
      id,
      columnValues: columnValues(FlumipUser.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FlumipUser]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<FlumipUser>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<FlumipUserUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<FlumipUserTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FlumipUserTable>? orderBy,
    _i1.OrderByListBuilder<FlumipUserTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<FlumipUser>(
      columnValues: columnValues(FlumipUser.t.updateTable),
      where: where(FlumipUser.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FlumipUser.t),
      orderByList: orderByList?.call(FlumipUser.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [FlumipUser]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FlumipUser>> delete(
    _i1.DatabaseSession session,
    List<FlumipUser> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FlumipUser>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FlumipUser].
  Future<FlumipUser> deleteRow(
    _i1.DatabaseSession session,
    FlumipUser row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FlumipUser>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FlumipUser>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FlumipUserTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FlumipUser>(
      where: where(FlumipUser.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<FlumipUserTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FlumipUser>(
      where: where?.call(FlumipUser.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FlumipUser] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<FlumipUserTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FlumipUser>(
      where: where(FlumipUser.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
