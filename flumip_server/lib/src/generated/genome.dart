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

abstract class Genome implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Genome._({
    this.id,
    required this.name,
    String? description,
    this.path,
    this.fastaPath,
    this.refPath,
    this.snpFolder,
    this.category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) : description = description ?? '',
       active = active ?? true,
       indexed = indexed ?? false,
       indexing = indexing ?? false,
       indexPID = indexPID ?? 0,
       indexResults = indexResults ?? 0,
       size = size ?? 0;

  factory Genome({
    int? id,
    required String name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) = _GenomeImpl;

  factory Genome.fromJson(Map<String, dynamic> jsonSerialization) {
    return Genome(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      path: jsonSerialization['path'] as String?,
      fastaPath: jsonSerialization['fastaPath'] as String?,
      refPath: jsonSerialization['refPath'] as String?,
      snpFolder: jsonSerialization['snpFolder'] as String?,
      category: jsonSerialization['category'] as String?,
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      indexed: jsonSerialization['indexed'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['indexed']),
      indexing: jsonSerialization['indexing'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['indexing']),
      indexPID: jsonSerialization['indexPID'] as int?,
      indexResults: jsonSerialization['indexResults'] as int?,
      size: jsonSerialization['size'] as int?,
    );
  }

  static final t = GenomeTable();

  static const db = GenomeRepository._();

  @override
  int? id;

  String name;

  String description;

  String? path;

  String? fastaPath;

  String? refPath;

  String? snpFolder;

  String? category;

  bool active;

  bool indexed;

  bool indexing;

  int indexPID;

  int indexResults;

  int size;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Genome]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Genome copyWith({
    int? id,
    String? name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Genome',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (path != null) 'path': path,
      if (fastaPath != null) 'fastaPath': fastaPath,
      if (refPath != null) 'refPath': refPath,
      if (snpFolder != null) 'snpFolder': snpFolder,
      if (category != null) 'category': category,
      'active': active,
      'indexed': indexed,
      'indexing': indexing,
      'indexPID': indexPID,
      'indexResults': indexResults,
      'size': size,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Genome',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (path != null) 'path': path,
      if (fastaPath != null) 'fastaPath': fastaPath,
      if (refPath != null) 'refPath': refPath,
      if (snpFolder != null) 'snpFolder': snpFolder,
      if (category != null) 'category': category,
      'active': active,
      'indexed': indexed,
      'indexing': indexing,
      'indexPID': indexPID,
      'indexResults': indexResults,
      'size': size,
    };
  }

  static GenomeInclude include() {
    return GenomeInclude._();
  }

  static GenomeIncludeList includeList({
    _is.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    GenomeInclude? include,
  }) {
    return GenomeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GenomeImpl extends Genome {
  _GenomeImpl({
    int? id,
    required String name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) : super._(
         id: id,
         name: name,
         description: description,
         path: path,
         fastaPath: fastaPath,
         refPath: refPath,
         snpFolder: snpFolder,
         category: category,
         active: active,
         indexed: indexed,
         indexing: indexing,
         indexPID: indexPID,
         indexResults: indexResults,
         size: size,
       );

  /// Returns a shallow copy of this [Genome]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Genome copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    Object? path = _Undefined,
    Object? fastaPath = _Undefined,
    Object? refPath = _Undefined,
    Object? snpFolder = _Undefined,
    Object? category = _Undefined,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) {
    return Genome(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      path: path is String? ? path : this.path,
      fastaPath: fastaPath is String? ? fastaPath : this.fastaPath,
      refPath: refPath is String? ? refPath : this.refPath,
      snpFolder: snpFolder is String? ? snpFolder : this.snpFolder,
      category: category is String? ? category : this.category,
      active: active ?? this.active,
      indexed: indexed ?? this.indexed,
      indexing: indexing ?? this.indexing,
      indexPID: indexPID ?? this.indexPID,
      indexResults: indexResults ?? this.indexResults,
      size: size ?? this.size,
    );
  }
}

class GenomeUpdateTable extends _is.UpdateTable<GenomeTable> {
  GenomeUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> description(String value) =>
      _is.ColumnValue(table.description, value);

  _is.ColumnValue<String, String> path(String? value) =>
      _is.ColumnValue(table.path, value);

  _is.ColumnValue<String, String> fastaPath(String? value) =>
      _is.ColumnValue(table.fastaPath, value);

  _is.ColumnValue<String, String> refPath(String? value) =>
      _is.ColumnValue(table.refPath, value);

  _is.ColumnValue<String, String> snpFolder(String? value) =>
      _is.ColumnValue(table.snpFolder, value);

  _is.ColumnValue<String, String> category(String? value) =>
      _is.ColumnValue(table.category, value);

  _is.ColumnValue<bool, bool> active(bool value) =>
      _is.ColumnValue(table.active, value);

  _is.ColumnValue<bool, bool> indexed(bool value) =>
      _is.ColumnValue(table.indexed, value);

  _is.ColumnValue<bool, bool> indexing(bool value) =>
      _is.ColumnValue(table.indexing, value);

  _is.ColumnValue<int, int> indexPID(int value) =>
      _is.ColumnValue(table.indexPID, value);

  _is.ColumnValue<int, int> indexResults(int value) =>
      _is.ColumnValue(table.indexResults, value);

  _is.ColumnValue<int, int> size(int value) =>
      _is.ColumnValue(table.size, value);
}

class GenomeTable extends _is.Table<int?> {
  GenomeTable({super.tableRelation}) : super(tableName: 'genome') {
    updateTable = GenomeUpdateTable(this);
    name = _is.ColumnString('name', this);
    description = _is.ColumnString('description', this, hasDefault: true);
    path = _is.ColumnString('path', this);
    fastaPath = _is.ColumnString('fastaPath', this);
    refPath = _is.ColumnString('refPath', this);
    snpFolder = _is.ColumnString('snpFolder', this);
    category = _is.ColumnString('category', this);
    active = _is.ColumnBool('active', this, hasDefault: true);
    indexed = _is.ColumnBool('indexed', this, hasDefault: true);
    indexing = _is.ColumnBool('indexing', this, hasDefault: true);
    indexPID = _is.ColumnInt('indexPID', this, hasDefault: true);
    indexResults = _is.ColumnInt('indexResults', this, hasDefault: true);
    size = _is.ColumnInt('size', this, hasDefault: true);
  }

  late final GenomeUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  late final _is.ColumnString path;

  late final _is.ColumnString fastaPath;

  late final _is.ColumnString refPath;

  late final _is.ColumnString snpFolder;

  late final _is.ColumnString category;

  late final _is.ColumnBool active;

  late final _is.ColumnBool indexed;

  late final _is.ColumnBool indexing;

  late final _is.ColumnInt indexPID;

  late final _is.ColumnInt indexResults;

  late final _is.ColumnInt size;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    description,
    path,
    fastaPath,
    refPath,
    snpFolder,
    category,
    active,
    indexed,
    indexing,
    indexPID,
    indexResults,
    size,
  ];
}

class GenomeInclude extends _is.IncludeObject {
  GenomeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Genome.t;
}

class GenomeIncludeList extends _is.IncludeList {
  GenomeIncludeList._({
    _is.WhereExpressionBuilder<GenomeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Genome.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Genome.t;
}

class GenomeRepository {
  const GenomeRepository._();

  /// Returns a list of [Genome]s matching the given query parameters.
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
  Future<List<Genome>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Genome>(
      where: where?.call(Genome.t),
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Genome] matching the given query parameters.
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
  Future<Genome?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GenomeTable>? where,
    int? offset,
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Genome>(
      where: where?.call(Genome.t),
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Genome] by its [id] or null if no such row exists.
  Future<Genome?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Genome>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Genome]s in the list and returns the inserted rows.
  ///
  /// The returned [Genome]s will have their `id` fields set.
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
  Future<List<Genome>> insert(
    _is.DatabaseSession session,
    List<Genome> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Genome>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Genome] and returns the inserted row.
  ///
  /// The returned [Genome] will have its `id` field set.
  Future<Genome> insertRow(
    _is.DatabaseSession session,
    Genome row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Genome>(row, transaction: transaction);
  }

  /// Upserts all [Genome]s in the list and returns the resulting rows.
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
  /// The returned [Genome]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Genome>> upsert(
    _is.DatabaseSession session,
    List<Genome> rows, {
    required _is.ColumnSelections<GenomeTable> conflictColumns,
    _is.ColumnSelections<GenomeTable>? updateColumns,
    _is.WhereExpressionBuilder<GenomeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Genome>(
      rows,
      conflictColumns: conflictColumns(Genome.t),
      updateColumns: updateColumns?.call(Genome.t),
      updateWhere: updateWhere?.call(Genome.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Genome] and returns the resulting row.
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
  /// The returned [Genome] will have its `id` field set.
  Future<Genome?> upsertRow(
    _is.DatabaseSession session,
    Genome row, {
    required _is.ColumnSelections<GenomeTable> conflictColumns,
    _is.ColumnSelections<GenomeTable>? updateColumns,
    _is.WhereExpressionBuilder<GenomeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Genome>(
      row,
      conflictColumns: conflictColumns(Genome.t),
      updateColumns: updateColumns?.call(Genome.t),
      updateWhere: updateWhere?.call(Genome.t),
      transaction: transaction,
    );
  }

  /// Updates all [Genome]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Genome>> update(
    _is.DatabaseSession session,
    List<Genome> rows, {
    _is.ColumnSelections<GenomeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Genome>(
      rows,
      columns: columns?.call(Genome.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Genome]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Genome> updateRow(
    _is.DatabaseSession session,
    Genome row, {
    _is.ColumnSelections<GenomeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Genome>(
      row,
      columns: columns?.call(Genome.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Genome] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Genome?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<GenomeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Genome>(
      id,
      columnValues: columnValues(Genome.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Genome]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Genome>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<GenomeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<GenomeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Genome>(
      columnValues: columnValues(Genome.t.updateTable),
      where: where(Genome.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Genome]s in the list and returns the deleted rows.
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
  Future<List<Genome>> delete(
    _is.DatabaseSession session,
    List<Genome> rows, {
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Genome>(
      rows,
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Genome].
  Future<Genome> deleteRow(
    _is.DatabaseSession session,
    Genome row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Genome>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Genome>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<GenomeTable> where,
    _is.OrderByBuilder<GenomeTable>? orderBy,
    _is.OrderByListBuilder<GenomeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Genome>(
      where: where(Genome.t),
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Genome>(
      where: where?.call(Genome.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Genome] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<GenomeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Genome>(
      where: where(Genome.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
