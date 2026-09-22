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
import 'snp_import_status.dart' as _iq9n7xnd;

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
abstract class Snp implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    _iq9n7xnd.SnpImportStatus? status,
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
       status = status ?? _iq9n7xnd.SnpImportStatus.ready,
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
    _iq9n7xnd.SnpImportStatus? status,
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
      active: _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      private: jsonSerialization['private'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['private']),
      size: jsonSerialization['size'] as int?,
      genome: jsonSerialization['genome'] as int?,
      owner: jsonSerialization['owner'] as int?,
      custom: jsonSerialization['custom'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['custom']),
      status: jsonSerialization['status'] == null
          ? null
          : _iq9n7xnd.SnpImportStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      statusMessage: jsonSerialization['statusMessage'] as String?,
      sourceVcfUrl: jsonSerialization['sourceVcfUrl'] as String?,
      sourceTbiUrl: jsonSerialization['sourceTbiUrl'] as String?,
      bytesDownloaded: jsonSerialization['bytesDownloaded'] as int?,
      totalBytes: jsonSerialization['totalBytes'] as int?,
      statusUpdated: jsonSerialization['statusUpdated'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['statusUpdated'],
            ),
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
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
  _iq9n7xnd.SnpImportStatus status;

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
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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
    _iq9n7xnd.SnpImportStatus? status,
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
    _is.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    SnpInclude? include,
  }) {
    return SnpIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
    _iq9n7xnd.SnpImportStatus? status,
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
  @_is.useResult
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
    _iq9n7xnd.SnpImportStatus? status,
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

class SnpUpdateTable extends _is.UpdateTable<SnpTable> {
  SnpUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> description(String value) =>
      _is.ColumnValue(table.description, value);

  _is.ColumnValue<String, String> vcfPath(String value) =>
      _is.ColumnValue(table.vcfPath, value);

  _is.ColumnValue<String, String> tbiPath(String value) =>
      _is.ColumnValue(table.tbiPath, value);

  _is.ColumnValue<String, String> folder(String value) =>
      _is.ColumnValue(table.folder, value);

  _is.ColumnValue<bool, bool> active(bool value) =>
      _is.ColumnValue(table.active, value);

  _is.ColumnValue<bool, bool> private(bool value) =>
      _is.ColumnValue(table.private, value);

  _is.ColumnValue<int, int> size(int value) =>
      _is.ColumnValue(table.size, value);

  _is.ColumnValue<int, int> genome(int? value) =>
      _is.ColumnValue(table.genome, value);

  _is.ColumnValue<int, int> owner(int? value) =>
      _is.ColumnValue(table.owner, value);

  _is.ColumnValue<bool, bool> custom(bool value) =>
      _is.ColumnValue(table.custom, value);

  _is.ColumnValue<_iq9n7xnd.SnpImportStatus, _iq9n7xnd.SnpImportStatus> status(
    _iq9n7xnd.SnpImportStatus value,
  ) => _is.ColumnValue(table.status, value);

  _is.ColumnValue<String, String> statusMessage(String value) =>
      _is.ColumnValue(table.statusMessage, value);

  _is.ColumnValue<String, String> sourceVcfUrl(String? value) =>
      _is.ColumnValue(table.sourceVcfUrl, value);

  _is.ColumnValue<String, String> sourceTbiUrl(String? value) =>
      _is.ColumnValue(table.sourceTbiUrl, value);

  _is.ColumnValue<int, int> bytesDownloaded(int value) =>
      _is.ColumnValue(table.bytesDownloaded, value);

  _is.ColumnValue<int, int> totalBytes(int value) =>
      _is.ColumnValue(table.totalBytes, value);

  _is.ColumnValue<DateTime, DateTime> statusUpdated(DateTime? value) =>
      _is.ColumnValue(table.statusUpdated, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);
}

class SnpTable extends _is.Table<int?> {
  SnpTable({super.tableRelation}) : super(tableName: 'snp') {
    updateTable = SnpUpdateTable(this);
    name = _is.ColumnString('name', this);
    description = _is.ColumnString('description', this, hasDefault: true);
    vcfPath = _is.ColumnString('vcfPath', this);
    tbiPath = _is.ColumnString('tbiPath', this);
    folder = _is.ColumnString('folder', this);
    active = _is.ColumnBool('active', this);
    private = _is.ColumnBool('private', this, hasDefault: true);
    size = _is.ColumnInt('size', this, hasDefault: true);
    genome = _is.ColumnInt('genome', this);
    owner = _is.ColumnInt('owner', this);
    custom = _is.ColumnBool('custom', this, hasDefault: true);
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    statusMessage = _is.ColumnString('statusMessage', this, hasDefault: true);
    sourceVcfUrl = _is.ColumnString('sourceVcfUrl', this);
    sourceTbiUrl = _is.ColumnString('sourceTbiUrl', this);
    bytesDownloaded = _is.ColumnInt('bytesDownloaded', this, hasDefault: true);
    totalBytes = _is.ColumnInt('totalBytes', this, hasDefault: true);
    statusUpdated = _is.ColumnDateTime('statusUpdated', this);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
  }

  late final SnpUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  late final _is.ColumnString vcfPath;

  late final _is.ColumnString tbiPath;

  late final _is.ColumnString folder;

  /// Written true by the scanner since the beginning and read by nothing. Left
  /// alone on purpose: [status] is the flag that actually decides whether an SNP
  /// can be used, and dropping a column earns migration risk for no behaviour
  /// change.
  late final _is.ColumnBool active;

  /// Visible only to [owner] and to administrators. The share toggle clears it.
  ///
  /// See `snpIsAccessible`, and note that the rule differs from
  /// `projectIsAccessible`: here a null owner is *not* a grant.
  late final _is.ColumnBool private;

  late final _is.ColumnInt size;

  /// The genome build this SNP is called against. Chosen when a custom SNP is
  /// added; filled in by the scanner for globals from the enclosing directory.
  ///
  /// This, not `Genome.snp`, is the authoritative link — VCF coordinates are
  /// build-specific, so an hg38 file used against hs1 silently produces wrong
  /// MIPs. `Genome.snp` is still maintained so nothing that reads it breaks.
  ///
  /// SetNull rather than Cascade: deleting a genome must not destroy a user's
  /// uploaded file. Such an SNP appears in no picker and its owner can delete it.
  late final _is.ColumnInt genome;

  /// The FlumipUser who added this, or null. Null for every global SNP and for
  /// anything added while single sign-on is off — mirroring `Project.owner`,
  /// including onDelete=SetNull, because deleting an identity must not delete the
  /// data they contributed.
  late final _is.ColumnInt owner;

  /// False for scanner-discovered SNPs under `genomeDir`, true for anything under
  /// `customSnpDir`. Decides which of the two delete paths applies.
  late final _is.ColumnBool custom;

  /// Where the bytes are in their journey. `ready` is the only status mipgen will
  /// accept, and it is the default so that every row predating this feature —
  /// which means every global SNP — is usable with no data migration.
  late final _is.ColumnEnum<_iq9n7xnd.SnpImportStatus> status;

  /// Why it failed, or which step it is on. Never holds a remote response body: a
  /// fetched error page can contain anything and this string is rendered in the
  /// app.
  late final _is.ColumnString statusMessage;

  /// Where the files were fetched from, for provenance and for retry. Null for
  /// uploads and for globals. Stored with any userinfo stripped.
  late final _is.ColumnString sourceVcfUrl;

  late final _is.ColumnString sourceTbiUrl;

  late final _is.ColumnInt bytesDownloaded;

  /// From Content-Length when the server sent one, 0 when it did not.
  late final _is.ColumnInt totalBytes;

  /// Heartbeat, written on every status change and every throttled progress
  /// update, so a reconcile pass can tell a live import from one whose server
  /// died mid-flight.
  late final _is.ColumnDateTime statusUpdated;

  late final _is.ColumnDateTime created;

  @override
  List<_is.Column> get columns => [
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

class SnpInclude extends _is.IncludeObject {
  SnpInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Snp.t;
}

class SnpIncludeList extends _is.IncludeList {
  SnpIncludeList._({
    _is.WhereExpressionBuilder<SnpTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Snp.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Snp.t;
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
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
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SnpTable>? where,
    int? offset,
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Snp>(
      where: where?.call(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Snp] by its [id] or null if no such row exists.
  Future<Snp?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
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
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Snp>> insert(
    _is.DatabaseSession session,
    List<Snp> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Snp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Snp] and returns the inserted row.
  ///
  /// The returned [Snp] will have its `id` field set.
  Future<Snp> insertRow(
    _is.DatabaseSession session,
    Snp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Snp>(row, transaction: transaction);
  }

  /// Upserts all [Snp]s in the list and returns the resulting rows.
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
  /// The returned [Snp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Snp>> upsert(
    _is.DatabaseSession session,
    List<Snp> rows, {
    required _is.ColumnSelections<SnpTable> conflictColumns,
    _is.ColumnSelections<SnpTable>? updateColumns,
    _is.WhereExpressionBuilder<SnpTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Snp>(
      rows,
      conflictColumns: conflictColumns(Snp.t),
      updateColumns: updateColumns?.call(Snp.t),
      updateWhere: updateWhere?.call(Snp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Snp] and returns the resulting row.
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
  /// The returned [Snp] will have its `id` field set.
  Future<Snp?> upsertRow(
    _is.DatabaseSession session,
    Snp row, {
    required _is.ColumnSelections<SnpTable> conflictColumns,
    _is.ColumnSelections<SnpTable>? updateColumns,
    _is.WhereExpressionBuilder<SnpTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Snp>(
      row,
      conflictColumns: conflictColumns(Snp.t),
      updateColumns: updateColumns?.call(Snp.t),
      updateWhere: updateWhere?.call(Snp.t),
      transaction: transaction,
    );
  }

  /// Updates all [Snp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Snp>> update(
    _is.DatabaseSession session,
    List<Snp> rows, {
    _is.ColumnSelections<SnpTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Snp>(
      rows,
      columns: columns?.call(Snp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Snp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Snp> updateRow(
    _is.DatabaseSession session,
    Snp row, {
    _is.ColumnSelections<SnpTable>? columns,
    _is.Transaction? transaction,
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
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<SnpUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Snp>(
      id,
      columnValues: columnValues(Snp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Snp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Snp>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SnpUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SnpTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Snp>(
      columnValues: columnValues(Snp.t.updateTable),
      where: where(Snp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Snp]s in the list and returns the deleted rows.
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
  Future<List<Snp>> delete(
    _is.DatabaseSession session,
    List<Snp> rows, {
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Snp>(
      rows,
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Snp].
  Future<Snp> deleteRow(
    _is.DatabaseSession session,
    Snp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Snp>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Snp>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SnpTable> where,
    _is.OrderByBuilder<SnpTable>? orderBy,
    _is.OrderByListBuilder<SnpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Snp>(
      where: where(Snp.t),
      orderBy: orderBy?.call(Snp.t),
      orderByList: orderByList?.call(Snp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SnpTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Snp>(
      where: where?.call(Snp.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Snp] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SnpTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Snp>(
      where: where(Snp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
