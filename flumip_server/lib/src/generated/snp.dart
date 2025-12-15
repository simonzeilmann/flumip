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

abstract class Snp implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Snp._({
    this.id,
    required this.name,
    String? description,
    required this.vcfPath,
    required this.tbiPath,
    required this.folder,
    required this.active,
    bool? private,
    int? size,
  }) : description = description ?? '',
       private = private ?? false,
       size = size ?? 0;

  factory Snp({
    int? id,
    required String name,
    String? description,
    required String vcfPath,
    required String tbiPath,
    required String folder,
    required bool active,
    bool? private,
    int? size,
  }) = _SnpImpl;

  factory Snp.fromJson(Map<String, dynamic> jsonSerialization) {
    return Snp(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      vcfPath: jsonSerialization['vcfPath'] as String,
      tbiPath: jsonSerialization['tbiPath'] as String,
      folder: jsonSerialization['folder'] as String,
      active: jsonSerialization['active'] as bool,
      private: jsonSerialization['private'] as bool,
      size: jsonSerialization['size'] as int,
    );
  }

  static final t = SnpTable();

  static const db = SnpRepository._();

  @override
  int? id;

  String name;

  String description;

  String vcfPath;

  String tbiPath;

  String folder;

  bool active;

  bool private;

  int size;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Snp copyWith({
    int? id,
    String? name,
    String? description,
    String? vcfPath,
    String? tbiPath,
    String? folder,
    bool? active,
    bool? private,
    int? size,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Snp',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'vcfPath': vcfPath,
      'tbiPath': tbiPath,
      'folder': folder,
      'active': active,
      'private': private,
      'size': size,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Snp',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'vcfPath': vcfPath,
      'tbiPath': tbiPath,
      'folder': folder,
      'active': active,
      'private': private,
      'size': size,
    };
  }

  static SnpInclude include() {
    return SnpInclude._();
  }

  static SnpIncludeList includeList({
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    SnpInclude? include,
  }) {
    return SnpIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Snp.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Snp.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SnpImpl extends Snp {
  _SnpImpl({
    int? id,
    required String name,
    String? description,
    required String vcfPath,
    required String tbiPath,
    required String folder,
    required bool active,
    bool? private,
    int? size,
  }) : super._(
         id: id,
         name: name,
         description: description,
         vcfPath: vcfPath,
         tbiPath: tbiPath,
         folder: folder,
         active: active,
         private: private,
         size: size,
       );

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Snp copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    String? vcfPath,
    String? tbiPath,
    String? folder,
    bool? active,
    bool? private,
    int? size,
  }) {
    return Snp(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      vcfPath: vcfPath ?? this.vcfPath,
      tbiPath: tbiPath ?? this.tbiPath,
      folder: folder ?? this.folder,
      active: active ?? this.active,
      private: private ?? this.private,
      size: size ?? this.size,
    );
  }
}

class SnpUpdateTable extends _i1.UpdateTable<SnpTable> {
  SnpUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> vcfPath(String value) => _i1.ColumnValue(
    table.vcfPath,
    value,
  );

  _i1.ColumnValue<String, String> tbiPath(String value) => _i1.ColumnValue(
    table.tbiPath,
    value,
  );

  _i1.ColumnValue<String, String> folder(String value) => _i1.ColumnValue(
    table.folder,
    value,
  );

  _i1.ColumnValue<bool, bool> active(bool value) => _i1.ColumnValue(
    table.active,
    value,
  );

  _i1.ColumnValue<bool, bool> private(bool value) => _i1.ColumnValue(
    table.private,
    value,
  );

  _i1.ColumnValue<int, int> size(int value) => _i1.ColumnValue(
    table.size,
    value,
  );
}

class SnpTable extends _i1.Table<int?> {
  SnpTable({super.tableRelation}) : super(tableName: 'snp') {
    updateTable = SnpUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
      hasDefault: true,
    );
    vcfPath = _i1.ColumnString(
      'vcfPath',
      this,
    );
    tbiPath = _i1.ColumnString(
      'tbiPath',
      this,
    );
    folder = _i1.ColumnString(
      'folder',
      this,
    );
    active = _i1.ColumnBool(
      'active',
      this,
    );
    private = _i1.ColumnBool(
      'private',
      this,
      hasDefault: true,
    );
    size = _i1.ColumnInt(
      'size',
      this,
      hasDefault: true,
    );
  }

  late final SnpUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString vcfPath;

  late final _i1.ColumnString tbiPath;

  late final _i1.ColumnString folder;

  late final _i1.ColumnBool active;

  late final _i1.ColumnBool private;

  late final _i1.ColumnInt size;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    description,
    vcfPath,
    tbiPath,
    folder,
    active,
    private,
    size,
  ];
}

class SnpInclude extends _i1.IncludeObject {
  SnpInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Snp.t;
}

class SnpIncludeList extends _i1.IncludeList {
  SnpIncludeList._({
    _i1.WhereExpressionBuilder<SnpTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Snp.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Snp.t;
}

class SnpRepository {
  const SnpRepository._();

  /// Returns a list of [Snp]s matching the given query parameters.
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
  Future<List<Snp>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Snp] matching the given query parameters.
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
  Future<Snp?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Snp] by its [id] or null if no such row exists.
  Future<Snp?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Snp>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Snp]s in the list and returns the inserted rows.
  ///
  /// The returned [Snp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Snp>> insert(
    _i1.Session session,
    List<Snp> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Snp>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Snp] and returns the inserted row.
  ///
  /// The returned [Snp] will have its `id` field set.
  Future<Snp> insertRow(
    _i1.Session session,
    Snp row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Snp>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Snp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Snp>> update(
    _i1.Session session,
    List<Snp> rows, {
    _i1.ColumnSelections<SnpTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Snp>(
      rows,
      columns: columns?.call(Snp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Snp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Snp> updateRow(
    _i1.Session session,
    Snp row, {
    _i1.ColumnSelections<SnpTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Snp>(
      row,
      columns: columns?.call(Snp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Snp] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Snp?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SnpUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Snp>(
      id,
      columnValues: columnValues(Snp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Snp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Snp>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SnpUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SnpTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Snp>(
      columnValues: columnValues(Snp.t.updateTable),
      where: where(Snp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Snp]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Snp>> delete(
    _i1.Session session,
    List<Snp> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Snp>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Snp].
  Future<Snp> deleteRow(
    _i1.Session session,
    Snp row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Snp>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Snp>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SnpTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Snp>(
      where: where(Snp.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Snp>(
      where: where?.call(Snp.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
