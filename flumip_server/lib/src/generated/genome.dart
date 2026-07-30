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
import 'package:flumip_server/src/generated/protocol.dart' as _i2;

abstract class Genome implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Genome._({
    this.id,
    required this.name,
    String? description,
    this.path,
    this.fastaPath,
    this.refPath,
    this.snpFolder,
    this.snp,
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
    List<int>? snp,
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
      snp: jsonSerialization['snp'] == null
          ? null
          : _i2.Protocol().deserialize<List<int>>(jsonSerialization['snp']),
      category: jsonSerialization['category'] as String?,
      active: jsonSerialization['active'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['active']),
      indexed: jsonSerialization['indexed'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['indexed']),
      indexing: jsonSerialization['indexing'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['indexing']),
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

  List<int>? snp;

  String? category;

  bool active;

  bool indexed;

  bool indexing;

  int indexPID;

  int indexResults;

  int size;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Genome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Genome copyWith({
    int? id,
    String? name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    List<int>? snp,
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
      if (snp != null) 'snp': snp?.toJson(),
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
      if (snp != null) 'snp': snp?.toJson(),
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
    _i1.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GenomeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GenomeTable>? orderByList,
    GenomeInclude? include,
  }) {
    return GenomeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Genome.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Genome.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
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
    List<int>? snp,
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
         snp: snp,
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
  @_i1.useResult
  @override
  Genome copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    Object? path = _Undefined,
    Object? fastaPath = _Undefined,
    Object? refPath = _Undefined,
    Object? snpFolder = _Undefined,
    Object? snp = _Undefined,
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
      snp: snp is List<int>? ? snp : this.snp?.map((e0) => e0).toList(),
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

class GenomeUpdateTable extends _i1.UpdateTable<GenomeTable> {
  GenomeUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) =>
      _i1.ColumnValue(table.name, value);

  _i1.ColumnValue<String, String> description(String value) =>
      _i1.ColumnValue(table.description, value);

  _i1.ColumnValue<String, String> path(String? value) =>
      _i1.ColumnValue(table.path, value);

  _i1.ColumnValue<String, String> fastaPath(String? value) =>
      _i1.ColumnValue(table.fastaPath, value);

  _i1.ColumnValue<String, String> refPath(String? value) =>
      _i1.ColumnValue(table.refPath, value);

  _i1.ColumnValue<String, String> snpFolder(String? value) =>
      _i1.ColumnValue(table.snpFolder, value);

  _i1.ColumnValue<List<int>, List<int>> snp(List<int>? value) =>
      _i1.ColumnValue(table.snp, value);

  _i1.ColumnValue<String, String> category(String? value) =>
      _i1.ColumnValue(table.category, value);

  _i1.ColumnValue<bool, bool> active(bool value) =>
      _i1.ColumnValue(table.active, value);

  _i1.ColumnValue<bool, bool> indexed(bool value) =>
      _i1.ColumnValue(table.indexed, value);

  _i1.ColumnValue<bool, bool> indexing(bool value) =>
      _i1.ColumnValue(table.indexing, value);

  _i1.ColumnValue<int, int> indexPID(int value) =>
      _i1.ColumnValue(table.indexPID, value);

  _i1.ColumnValue<int, int> indexResults(int value) =>
      _i1.ColumnValue(table.indexResults, value);

  _i1.ColumnValue<int, int> size(int value) =>
      _i1.ColumnValue(table.size, value);
}

class GenomeTable extends _i1.Table<int?> {
  GenomeTable({super.tableRelation}) : super(tableName: 'genome') {
    updateTable = GenomeUpdateTable(this);
    name = _i1.ColumnString('name', this);
    description = _i1.ColumnString('description', this, hasDefault: true);
    path = _i1.ColumnString('path', this);
    fastaPath = _i1.ColumnString('fastaPath', this);
    refPath = _i1.ColumnString('refPath', this);
    snpFolder = _i1.ColumnString('snpFolder', this);
    snp = _i1.ColumnSerializable<List<int>>('snp', this);
    category = _i1.ColumnString('category', this);
    active = _i1.ColumnBool('active', this, hasDefault: true);
    indexed = _i1.ColumnBool('indexed', this, hasDefault: true);
    indexing = _i1.ColumnBool('indexing', this, hasDefault: true);
    indexPID = _i1.ColumnInt('indexPID', this, hasDefault: true);
    indexResults = _i1.ColumnInt('indexResults', this, hasDefault: true);
    size = _i1.ColumnInt('size', this, hasDefault: true);
  }

  late final GenomeUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnString path;

  late final _i1.ColumnString fastaPath;

  late final _i1.ColumnString refPath;

  late final _i1.ColumnString snpFolder;

  late final _i1.ColumnSerializable<List<int>> snp;

  late final _i1.ColumnString category;

  late final _i1.ColumnBool active;

  late final _i1.ColumnBool indexed;

  late final _i1.ColumnBool indexing;

  late final _i1.ColumnInt indexPID;

  late final _i1.ColumnInt indexResults;

  late final _i1.ColumnInt size;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    description,
    path,
    fastaPath,
    refPath,
    snpFolder,
    snp,
    category,
    active,
    indexed,
    indexing,
    indexPID,
    indexResults,
    size,
  ];
}

class GenomeInclude extends _i1.IncludeObject {
  GenomeInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Genome.t;
}

class GenomeIncludeList extends _i1.IncludeList {
  GenomeIncludeList._({
    _i1.WhereExpressionBuilder<GenomeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Genome.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Genome.t;
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GenomeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GenomeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Genome>(
      where: where?.call(Genome.t),
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      orderDescending: orderDescending,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GenomeTable>? where,
    int? offset,
    _i1.OrderByBuilder<GenomeTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GenomeTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Genome>(
      where: where?.call(Genome.t),
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Genome] by its [id] or null if no such row exists.
  Future<Genome?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
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
  Future<List<Genome>> insert(
    _i1.DatabaseSession session,
    List<Genome> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Genome>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Genome] and returns the inserted row.
  ///
  /// The returned [Genome] will have its `id` field set.
  Future<Genome> insertRow(
    _i1.DatabaseSession session,
    Genome row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Genome>(row, transaction: transaction);
  }

  /// Updates all [Genome]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Genome>> update(
    _i1.DatabaseSession session,
    List<Genome> rows, {
    _i1.ColumnSelections<GenomeTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Genome>(
      rows,
      columns: columns?.call(Genome.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Genome]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Genome> updateRow(
    _i1.DatabaseSession session,
    Genome row, {
    _i1.ColumnSelections<GenomeTable>? columns,
    _i1.Transaction? transaction,
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
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GenomeUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Genome>(
      id,
      columnValues: columnValues(Genome.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Genome]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Genome>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GenomeUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GenomeTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GenomeTable>? orderBy,
    _i1.OrderByListBuilder<GenomeTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Genome>(
      columnValues: columnValues(Genome.t.updateTable),
      where: where(Genome.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Genome.t),
      orderByList: orderByList?.call(Genome.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Genome]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Genome>> delete(
    _i1.DatabaseSession session,
    List<Genome> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Genome>(rows, transaction: transaction);
  }

  /// Deletes a single [Genome].
  Future<Genome> deleteRow(
    _i1.DatabaseSession session,
    Genome row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Genome>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Genome>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GenomeTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Genome>(
      where: where(Genome.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GenomeTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Genome>(
      where: where?.call(Genome.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Genome] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GenomeTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Genome>(
      where: where(Genome.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
