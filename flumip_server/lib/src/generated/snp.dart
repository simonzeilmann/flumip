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
import 'snp_import_status.dart' as _i2;

/// One SNP dataset: a bgzip'd VCF plus its tabix index.
///
/// Two provenances, told apart by [custom]:
///
/// - **Global** (`custom: false`) — found by `GenomeService.collectGenomes` under
///   `Settings.genomeDir`. Owned by nobody, visible to everybody, and removable
///   only by an administrator, because removing one deletes files out of the
///   shared genome tree.
/// - **Custom** (`custom: true`) — added by a user, living under
///   `Settings.customSnpDir`. Has an [owner], a [genome] and a [status], because
///   the bytes arrive after the row does.
///
/// `folder` is the scanner's idempotency key and stays that way. For a custom SNP
/// the folder is derived from the row id, so the row is authoritative and a scan
/// only reconciles what is on disk against it.
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
    this.genome,
    this.owner,
    bool? custom,
    _i2.SnpImportStatus? status,
    String? statusMessage,
    this.sourceVcfUrl,
    this.sourceTbiUrl,
    int? bytesDownloaded,
    int? totalBytes,
    this.statusUpdated,
    DateTime? created,
  }) : description = description ?? '',
       private = private ?? false,
       size = size ?? 0,
       custom = custom ?? false,
       status = status ?? _i2.SnpImportStatus.ready,
       statusMessage = statusMessage ?? '',
       bytesDownloaded = bytesDownloaded ?? 0,
       totalBytes = totalBytes ?? 0,
       created = created ?? DateTime.now();

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
    int? genome,
    int? owner,
    bool? custom,
    _i2.SnpImportStatus? status,
    String? statusMessage,
    String? sourceVcfUrl,
    String? sourceTbiUrl,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? statusUpdated,
    DateTime? created,
  }) = _SnpImpl;

  factory Snp.fromJson(Map<String, dynamic> jsonSerialization) {
    return Snp(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      vcfPath: jsonSerialization['vcfPath'] as String,
      tbiPath: jsonSerialization['tbiPath'] as String,
      folder: jsonSerialization['folder'] as String,
      active: _i1.BoolJsonExtension.fromJson(jsonSerialization['active']),
      private: jsonSerialization['private'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['private']),
      size: jsonSerialization['size'] as int?,
      genome: jsonSerialization['genome'] as int?,
      owner: jsonSerialization['owner'] as int?,
      custom: jsonSerialization['custom'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['custom']),
      status: jsonSerialization['status'] == null
          ? null
          : _i2.SnpImportStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      statusMessage: jsonSerialization['statusMessage'] as String?,
      sourceVcfUrl: jsonSerialization['sourceVcfUrl'] as String?,
      sourceTbiUrl: jsonSerialization['sourceTbiUrl'] as String?,
      bytesDownloaded: jsonSerialization['bytesDownloaded'] as int?,
      totalBytes: jsonSerialization['totalBytes'] as int?,
      statusUpdated: jsonSerialization['statusUpdated'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['statusUpdated'],
            ),
      created: jsonSerialization['created'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
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

  /// Written true by the scanner since the beginning and read by nothing. Left
  /// alone on purpose: [status] is the flag that actually decides whether an SNP
  /// can be used, and dropping a column earns migration risk for no behaviour
  /// change.
  bool active;

  /// Visible only to [owner] and to administrators. The share toggle clears it.
  ///
  /// See `snpIsAccessible`, and note that the rule differs from
  /// `projectIsAccessible`: here a null owner is *not* a grant.
  bool private;

  int size;

  /// The genome build this SNP is called against. Chosen when a custom SNP is
  /// added; filled in by the scanner for globals from the enclosing directory.
  ///
  /// This, not `Genome.snp`, is the authoritative link — VCF coordinates are
  /// build-specific, so an hg38 file used against hs1 silently produces wrong
  /// MIPs. `Genome.snp` is still maintained so nothing that reads it breaks.
  ///
  /// SetNull rather than Cascade: deleting a genome must not destroy a user's
  /// uploaded file. Such an SNP appears in no picker and its owner can delete it.
  int? genome;

  /// The FlumipUser who added this, or null. Null for every global SNP and for
  /// anything added while single sign-on is off — mirroring `Project.owner`,
  /// including onDelete=SetNull, because deleting an identity must not delete the
  /// data they contributed.
  int? owner;

  /// False for scanner-discovered SNPs under `genomeDir`, true for anything under
  /// `customSnpDir`. Decides which of the two delete paths applies.
  bool custom;

  /// Where the bytes are in their journey. `ready` is the only status mipgen will
  /// accept, and it is the default so that every row predating this feature —
  /// which means every global SNP — is usable with no data migration.
  _i2.SnpImportStatus status;

  /// Why it failed, or which step it is on. Never holds a remote response body: a
  /// fetched error page can contain anything and this string is rendered in the
  /// app.
  String statusMessage;

  /// Where the files were fetched from, for provenance and for retry. Null for
  /// uploads and for globals. Stored with any userinfo stripped.
  String? sourceVcfUrl;

  String? sourceTbiUrl;

  int bytesDownloaded;

  /// From Content-Length when the server sent one, 0 when it did not.
  int totalBytes;

  /// Heartbeat, written on every status change and every throttled progress
  /// update, so a reconcile pass can tell a live import from one whose server
  /// died mid-flight.
  DateTime? statusUpdated;

  DateTime created;

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
    int? genome,
    int? owner,
    bool? custom,
    _i2.SnpImportStatus? status,
    String? statusMessage,
    String? sourceVcfUrl,
    String? sourceTbiUrl,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? statusUpdated,
    DateTime? created,
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
      if (genome != null) 'genome': genome,
      if (owner != null) 'owner': owner,
      'custom': custom,
      'status': status.toJson(),
      'statusMessage': statusMessage,
      if (sourceVcfUrl != null) 'sourceVcfUrl': sourceVcfUrl,
      if (sourceTbiUrl != null) 'sourceTbiUrl': sourceTbiUrl,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      if (statusUpdated != null) 'statusUpdated': statusUpdated?.toJson(),
      'created': created.toJson(),
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
      if (genome != null) 'genome': genome,
      if (owner != null) 'owner': owner,
      'custom': custom,
      'status': status.toJson(),
      'statusMessage': statusMessage,
      if (sourceVcfUrl != null) 'sourceVcfUrl': sourceVcfUrl,
      if (sourceTbiUrl != null) 'sourceTbiUrl': sourceTbiUrl,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      if (statusUpdated != null) 'statusUpdated': statusUpdated?.toJson(),
      'created': created.toJson(),
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
    int? genome,
    int? owner,
    bool? custom,
    _i2.SnpImportStatus? status,
    String? statusMessage,
    String? sourceVcfUrl,
    String? sourceTbiUrl,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? statusUpdated,
    DateTime? created,
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
         genome: genome,
         owner: owner,
         custom: custom,
         status: status,
         statusMessage: statusMessage,
         sourceVcfUrl: sourceVcfUrl,
         sourceTbiUrl: sourceTbiUrl,
         bytesDownloaded: bytesDownloaded,
         totalBytes: totalBytes,
         statusUpdated: statusUpdated,
         created: created,
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
    Object? genome = _Undefined,
    Object? owner = _Undefined,
    bool? custom,
    _i2.SnpImportStatus? status,
    String? statusMessage,
    Object? sourceVcfUrl = _Undefined,
    Object? sourceTbiUrl = _Undefined,
    int? bytesDownloaded,
    int? totalBytes,
    Object? statusUpdated = _Undefined,
    DateTime? created,
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
      genome: genome is int? ? genome : this.genome,
      owner: owner is int? ? owner : this.owner,
      custom: custom ?? this.custom,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      sourceVcfUrl: sourceVcfUrl is String? ? sourceVcfUrl : this.sourceVcfUrl,
      sourceTbiUrl: sourceTbiUrl is String? ? sourceTbiUrl : this.sourceTbiUrl,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      statusUpdated: statusUpdated is DateTime?
          ? statusUpdated
          : this.statusUpdated,
      created: created ?? this.created,
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

  _i1.ColumnValue<int, int> genome(int? value) => _i1.ColumnValue(
    table.genome,
    value,
  );

  _i1.ColumnValue<int, int> owner(int? value) => _i1.ColumnValue(
    table.owner,
    value,
  );

  _i1.ColumnValue<bool, bool> custom(bool value) => _i1.ColumnValue(
    table.custom,
    value,
  );

  _i1.ColumnValue<_i2.SnpImportStatus, _i2.SnpImportStatus> status(
    _i2.SnpImportStatus value,
  ) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> statusMessage(String value) =>
      _i1.ColumnValue(
        table.statusMessage,
        value,
      );

  _i1.ColumnValue<String, String> sourceVcfUrl(String? value) =>
      _i1.ColumnValue(
        table.sourceVcfUrl,
        value,
      );

  _i1.ColumnValue<String, String> sourceTbiUrl(String? value) =>
      _i1.ColumnValue(
        table.sourceTbiUrl,
        value,
      );

  _i1.ColumnValue<int, int> bytesDownloaded(int value) => _i1.ColumnValue(
    table.bytesDownloaded,
    value,
  );

  _i1.ColumnValue<int, int> totalBytes(int value) => _i1.ColumnValue(
    table.totalBytes,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> statusUpdated(DateTime? value) =>
      _i1.ColumnValue(
        table.statusUpdated,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _i1.ColumnValue(
        table.created,
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
    genome = _i1.ColumnInt(
      'genome',
      this,
    );
    owner = _i1.ColumnInt(
      'owner',
      this,
    );
    custom = _i1.ColumnBool(
      'custom',
      this,
      hasDefault: true,
    );
    status = _i1.ColumnEnum(
      'status',
      this,
      _i1.EnumSerialization.byName,
      hasDefault: true,
    );
    statusMessage = _i1.ColumnString(
      'statusMessage',
      this,
      hasDefault: true,
    );
    sourceVcfUrl = _i1.ColumnString(
      'sourceVcfUrl',
      this,
    );
    sourceTbiUrl = _i1.ColumnString(
      'sourceTbiUrl',
      this,
    );
    bytesDownloaded = _i1.ColumnInt(
      'bytesDownloaded',
      this,
      hasDefault: true,
    );
    totalBytes = _i1.ColumnInt(
      'totalBytes',
      this,
      hasDefault: true,
    );
    statusUpdated = _i1.ColumnDateTime(
      'statusUpdated',
      this,
    );
    created = _i1.ColumnDateTime(
      'created',
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

  /// Written true by the scanner since the beginning and read by nothing. Left
  /// alone on purpose: [status] is the flag that actually decides whether an SNP
  /// can be used, and dropping a column earns migration risk for no behaviour
  /// change.
  late final _i1.ColumnBool active;

  /// Visible only to [owner] and to administrators. The share toggle clears it.
  ///
  /// See `snpIsAccessible`, and note that the rule differs from
  /// `projectIsAccessible`: here a null owner is *not* a grant.
  late final _i1.ColumnBool private;

  late final _i1.ColumnInt size;

  /// The genome build this SNP is called against. Chosen when a custom SNP is
  /// added; filled in by the scanner for globals from the enclosing directory.
  ///
  /// This, not `Genome.snp`, is the authoritative link — VCF coordinates are
  /// build-specific, so an hg38 file used against hs1 silently produces wrong
  /// MIPs. `Genome.snp` is still maintained so nothing that reads it breaks.
  ///
  /// SetNull rather than Cascade: deleting a genome must not destroy a user's
  /// uploaded file. Such an SNP appears in no picker and its owner can delete it.
  late final _i1.ColumnInt genome;

  /// The FlumipUser who added this, or null. Null for every global SNP and for
  /// anything added while single sign-on is off — mirroring `Project.owner`,
  /// including onDelete=SetNull, because deleting an identity must not delete the
  /// data they contributed.
  late final _i1.ColumnInt owner;

  /// False for scanner-discovered SNPs under `genomeDir`, true for anything under
  /// `customSnpDir`. Decides which of the two delete paths applies.
  late final _i1.ColumnBool custom;

  /// Where the bytes are in their journey. `ready` is the only status mipgen will
  /// accept, and it is the default so that every row predating this feature —
  /// which means every global SNP — is usable with no data migration.
  late final _i1.ColumnEnum<_i2.SnpImportStatus> status;

  /// Why it failed, or which step it is on. Never holds a remote response body: a
  /// fetched error page can contain anything and this string is rendered in the
  /// app.
  late final _i1.ColumnString statusMessage;

  /// Where the files were fetched from, for provenance and for retry. Null for
  /// uploads and for globals. Stored with any userinfo stripped.
  late final _i1.ColumnString sourceVcfUrl;

  late final _i1.ColumnString sourceTbiUrl;

  late final _i1.ColumnInt bytesDownloaded;

  /// From Content-Length when the server sent one, 0 when it did not.
  late final _i1.ColumnInt totalBytes;

  /// Heartbeat, written on every status change and every throttled progress
  /// update, so a reconcile pass can tell a live import from one whose server
  /// died mid-flight.
  late final _i1.ColumnDateTime statusUpdated;

  late final _i1.ColumnDateTime created;

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
    genome,
    owner,
    custom,
    status,
    statusMessage,
    sourceVcfUrl,
    sourceTbiUrl,
    bytesDownloaded,
    totalBytes,
    statusUpdated,
    created,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
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
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<SnpTable>? where,
    int? offset,
    _i1.OrderByBuilder<SnpTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SnpTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Snp] by its [id] or null if no such row exists.
  Future<Snp?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Snp>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Snp]s in the list and returns the inserted rows.
  ///
  /// The returned [Snp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Snp>> insert(
    _i1.DatabaseSession session,
    List<Snp> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Snp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Snp] and returns the inserted row.
  ///
  /// The returned [Snp] will have its `id` field set.
  Future<Snp> insertRow(
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session, {
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
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session,
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
    _i1.DatabaseSession session, {
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
    _i1.DatabaseSession session, {
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

  /// Acquires row-level locks on [Snp] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<SnpTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Snp>(
      where: where(Snp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
