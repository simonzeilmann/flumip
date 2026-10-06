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

abstract class Project
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Project._({
    this.id,
    required this.name,
    this.folderName,
    String? description,
    this.genome,
    this.snp,
    DateTime? created,
    this.owner,
    this.department,
    this.trackToken,
    this.genes,
    bool? bedFileCreated,
    bool? active,
    this.pid,
    int? size,
    bool? emailNotification,
    required this.options,
    this.started,
    this.completedIn,
    String? error,
    String? warning,
    bool? cleanup,
  }) : description = description ?? '',
       created = created ?? DateTime.now(),
       bedFileCreated = bedFileCreated ?? false,
       active = active ?? false,
       size = size ?? 0,
       emailNotification = emailNotification ?? false,
       error = error ?? '',
       warning = warning ?? '',
       cleanup = cleanup ?? false;

  factory Project({
    int? id,
    required String name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    DateTime? created,
    int? owner,
    String? department,
    String? trackToken,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    required int options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    String? warning,
    bool? cleanup,
  }) = _ProjectImpl;

  factory Project.fromJson(Map<String, dynamic> jsonSerialization) {
    return Project(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      folderName: jsonSerialization['folderName'] as String?,
      description: jsonSerialization['description'] as String?,
      genome: jsonSerialization['genome'] as int?,
      snp: jsonSerialization['snp'] as int?,
      created: jsonSerialization['created'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      owner: jsonSerialization['owner'] as int?,
      department: jsonSerialization['department'] as String?,
      trackToken: jsonSerialization['trackToken'] as String?,
      genes: jsonSerialization['genes'] == null
          ? null
          : _ijyeyqvr.Protocol().deserialize<List<String>>(
              jsonSerialization['genes'],
            ),
      bedFileCreated: jsonSerialization['bedFileCreated'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['bedFileCreated']),
      active: jsonSerialization['active'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      pid: jsonSerialization['pid'] as int?,
      size: jsonSerialization['size'] as int?,
      emailNotification: jsonSerialization['emailNotification'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['emailNotification'],
            ),
      options: jsonSerialization['options'] as int,
      started: jsonSerialization['started'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['started']),
      completedIn: jsonSerialization['completedIn'] == null
          ? null
          : _is.DurationJsonExtension.fromJson(
              jsonSerialization['completedIn'],
            ),
      error: jsonSerialization['error'] as String?,
      warning: jsonSerialization['warning'] as String?,
      cleanup: jsonSerialization['cleanup'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['cleanup']),
    );
  }

  static final t = ProjectTable();

  static const db = ProjectRepository._();

  @override
  int? id;

  String name;

  String? folderName;

  String description;

  int? genome;

  /// The chosen SNP set, or null for "no SNP masking".
  ///
  /// onDelete=SetNull, exactly like [owner]: deleting an SNP must null the pointer
  /// rather than leave a project aimed at a row that is gone. `generateMips`
  /// refuses to run when this points at an SNP that is not ready, so a project
  /// whose SNP was deleted fails loudly instead of quietly designing different
  /// MIPs.
  int? snp;

  DateTime created;

  /// The FlumipUser who created the project, or null.
  ///
  /// Null means "unowned", which every project on an existing install is, since
  /// nothing wrote this column before authorization existed. Unowned projects
  /// stay fully accessible to everyone so that switching single sign-on on does
  /// not strand people's existing work — see `projectIsAccessible`.
  ///
  /// onDelete=SetNull rather than Cascade: deleting an identity must not delete
  /// the data they produced. The project falls back to unowned, which an admin
  /// can then reassign.
  int? owner;

  /// The group this project belongs to, as the identity provider spells it.
  ///
  /// A **String**, not an id: it holds a claim value verbatim (`cardiology`,
  /// `realm_access.roles` entry, whatever the provider sends) and there is no
  /// table of departments to point at. It was `int?` while nothing could set
  /// it, which is exactly the shape a claim value cannot take.
  ///
  /// Null means "no department", which is every project created before this
  /// and every project on an install with no department claim configured.
  /// `projectIsAccessible` treats null as "owner and admins only" — a
  /// department only ever *widens* access, never narrows it.
  ///
  /// Set through `ProjectEndpoint.setProjectDepartment`, by the owner or an
  /// admin. Stamped automatically at creation when the creator belongs to
  /// exactly one group, because then there is nothing to choose.
  String? department;

  /// Unguessable token for the public `/ucsc_track/<token>` URL.
  ///
  /// serverOnly, and handed out only by `FileEndpoint.getUcscTrackToken` after
  /// an access check. The route itself cannot require a session — the fetcher is
  /// genome.ucsc.edu, not a browser — so the token is what stops the track from
  /// being enumerable. Null on projects created before this existed; minted on
  /// first request.
  String? trackToken;

  List<String>? genes;

  bool bedFileCreated;

  bool active;

  int? pid;

  int size;

  bool emailNotification;

  int options;

  DateTime? started;

  Duration? completedIn;

  String error;

  /// Something worth knowing about a run that nonetheless succeeded.
  ///
  /// ⚠️ Distinct from [error], and the distinction is the point. Finalizing a
  /// finished run does several things after the MIPs are safely on disk — sizing
  /// the output, timing it, generating the UCSC track — and any of those
  /// throwing used to land in `error`, which marks the whole project failed. A
  /// project whose MIPs designed perfectly well would report "MIP generation
  /// failed" because a track file could not be written.
  ///
  /// `error` means there is no result. `warning` means there is a result and
  /// something about it is worth reading.
  String warning;

  bool cleanup;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Project copyWith({
    int? id,
    String? name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    DateTime? created,
    int? owner,
    String? department,
    String? trackToken,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    int? options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    String? warning,
    bool? cleanup,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      if (folderName != null) 'folderName': folderName,
      'description': description,
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      'created': created.toJson(),
      if (owner != null) 'owner': owner,
      if (department != null) 'department': department,
      if (trackToken != null) 'trackToken': trackToken,
      if (genes != null) 'genes': genes?.toJson(),
      'bedFileCreated': bedFileCreated,
      'active': active,
      if (pid != null) 'pid': pid,
      'size': size,
      'emailNotification': emailNotification,
      'options': options,
      if (started != null) 'started': started?.toJson(),
      if (completedIn != null) 'completedIn': completedIn?.toJson(),
      'error': error,
      'warning': warning,
      'cleanup': cleanup,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Project',
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      'created': created.toJson(),
      if (owner != null) 'owner': owner,
      if (department != null) 'department': department,
      if (genes != null) 'genes': genes?.toJson(),
      'bedFileCreated': bedFileCreated,
      'active': active,
      'size': size,
      'emailNotification': emailNotification,
      'options': options,
      if (started != null) 'started': started?.toJson(),
      if (completedIn != null) 'completedIn': completedIn?.toJson(),
      'error': error,
      'warning': warning,
      'cleanup': cleanup,
    };
  }

  static ProjectInclude include() {
    return ProjectInclude._();
  }

  static ProjectIncludeList includeList({
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    ProjectInclude? include,
  }) {
    return ProjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectImpl extends Project {
  _ProjectImpl({
    int? id,
    required String name,
    String? folderName,
    String? description,
    int? genome,
    int? snp,
    DateTime? created,
    int? owner,
    String? department,
    String? trackToken,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
    int? pid,
    int? size,
    bool? emailNotification,
    required int options,
    DateTime? started,
    Duration? completedIn,
    String? error,
    String? warning,
    bool? cleanup,
  }) : super._(
         id: id,
         name: name,
         folderName: folderName,
         description: description,
         genome: genome,
         snp: snp,
         created: created,
         owner: owner,
         department: department,
         trackToken: trackToken,
         genes: genes,
         bedFileCreated: bedFileCreated,
         active: active,
         pid: pid,
         size: size,
         emailNotification: emailNotification,
         options: options,
         started: started,
         completedIn: completedIn,
         error: error,
         warning: warning,
         cleanup: cleanup,
       );

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Project copyWith({
    Object? id = _Undefined,
    String? name,
    Object? folderName = _Undefined,
    String? description,
    Object? genome = _Undefined,
    Object? snp = _Undefined,
    DateTime? created,
    Object? owner = _Undefined,
    Object? department = _Undefined,
    Object? trackToken = _Undefined,
    Object? genes = _Undefined,
    bool? bedFileCreated,
    bool? active,
    Object? pid = _Undefined,
    int? size,
    bool? emailNotification,
    int? options,
    Object? started = _Undefined,
    Object? completedIn = _Undefined,
    String? error,
    String? warning,
    bool? cleanup,
  }) {
    return Project(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      folderName: folderName is String? ? folderName : this.folderName,
      description: description ?? this.description,
      genome: genome is int? ? genome : this.genome,
      snp: snp is int? ? snp : this.snp,
      created: created ?? this.created,
      owner: owner is int? ? owner : this.owner,
      department: department is String? ? department : this.department,
      trackToken: trackToken is String? ? trackToken : this.trackToken,
      genes: genes is List<String>?
          ? genes
          : this.genes?.map((e0) => e0).toList(),
      bedFileCreated: bedFileCreated ?? this.bedFileCreated,
      active: active ?? this.active,
      pid: pid is int? ? pid : this.pid,
      size: size ?? this.size,
      emailNotification: emailNotification ?? this.emailNotification,
      options: options ?? this.options,
      started: started is DateTime? ? started : this.started,
      completedIn: completedIn is Duration? ? completedIn : this.completedIn,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      cleanup: cleanup ?? this.cleanup,
    );
  }
}

class ProjectUpdateTable extends _is.UpdateTable<ProjectTable> {
  ProjectUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> folderName(String? value) =>
      _is.ColumnValue(table.folderName, value);

  _is.ColumnValue<String, String> description(String value) =>
      _is.ColumnValue(table.description, value);

  _is.ColumnValue<int, int> genome(int? value) =>
      _is.ColumnValue(table.genome, value);

  _is.ColumnValue<int, int> snp(int? value) =>
      _is.ColumnValue(table.snp, value);

  _is.ColumnValue<DateTime, DateTime> created(DateTime value) =>
      _is.ColumnValue(table.created, value);

  _is.ColumnValue<int, int> owner(int? value) =>
      _is.ColumnValue(table.owner, value);

  _is.ColumnValue<String, String> department(String? value) =>
      _is.ColumnValue(table.department, value);

  _is.ColumnValue<String, String> trackToken(String? value) =>
      _is.ColumnValue(table.trackToken, value);

  _is.ColumnValue<List<String>, List<String>> genes(List<String>? value) =>
      _is.ColumnValue(table.genes, value);

  _is.ColumnValue<bool, bool> bedFileCreated(bool value) =>
      _is.ColumnValue(table.bedFileCreated, value);

  _is.ColumnValue<bool, bool> active(bool value) =>
      _is.ColumnValue(table.active, value);

  _is.ColumnValue<int, int> pid(int? value) =>
      _is.ColumnValue(table.pid, value);

  _is.ColumnValue<int, int> size(int value) =>
      _is.ColumnValue(table.size, value);

  _is.ColumnValue<bool, bool> emailNotification(bool value) =>
      _is.ColumnValue(table.emailNotification, value);

  _is.ColumnValue<int, int> options(int value) =>
      _is.ColumnValue(table.options, value);

  _is.ColumnValue<DateTime, DateTime> started(DateTime? value) =>
      _is.ColumnValue(table.started, value);

  _is.ColumnValue<Duration, Duration> completedIn(Duration? value) =>
      _is.ColumnValue(table.completedIn, value);

  _is.ColumnValue<String, String> error(String value) =>
      _is.ColumnValue(table.error, value);

  _is.ColumnValue<String, String> warning(String value) =>
      _is.ColumnValue(table.warning, value);

  _is.ColumnValue<bool, bool> cleanup(bool value) =>
      _is.ColumnValue(table.cleanup, value);
}

class ProjectTable extends _is.Table<int?> {
  ProjectTable({super.tableRelation}) : super(tableName: 'project') {
    updateTable = ProjectUpdateTable(this);
    name = _is.ColumnString('name', this);
    folderName = _is.ColumnString('folderName', this);
    description = _is.ColumnString('description', this, hasDefault: true);
    genome = _is.ColumnInt('genome', this);
    snp = _is.ColumnInt('snp', this);
    created = _is.ColumnDateTime('created', this, hasDefault: true);
    owner = _is.ColumnInt('owner', this);
    department = _is.ColumnString('department', this);
    trackToken = _is.ColumnString('trackToken', this);
    genes = _is.ColumnSerializable<List<String>>('genes', this);
    bedFileCreated = _is.ColumnBool('bedFileCreated', this, hasDefault: true);
    active = _is.ColumnBool('active', this, hasDefault: true);
    pid = _is.ColumnInt('pid', this);
    size = _is.ColumnInt('size', this, hasDefault: true);
    emailNotification = _is.ColumnBool(
      'emailNotification',
      this,
      hasDefault: true,
    );
    options = _is.ColumnInt('options', this);
    started = _is.ColumnDateTime('started', this);
    completedIn = _is.ColumnDuration('completedIn', this);
    error = _is.ColumnString('error', this, hasDefault: true);
    warning = _is.ColumnString('warning', this, hasDefault: true);
    cleanup = _is.ColumnBool('cleanup', this, hasDefault: true);
  }

  late final ProjectUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString folderName;

  late final _is.ColumnString description;

  late final _is.ColumnInt genome;

  /// The chosen SNP set, or null for "no SNP masking".
  ///
  /// onDelete=SetNull, exactly like [owner]: deleting an SNP must null the pointer
  /// rather than leave a project aimed at a row that is gone. `generateMips`
  /// refuses to run when this points at an SNP that is not ready, so a project
  /// whose SNP was deleted fails loudly instead of quietly designing different
  /// MIPs.
  late final _is.ColumnInt snp;

  late final _is.ColumnDateTime created;

  /// The FlumipUser who created the project, or null.
  ///
  /// Null means "unowned", which every project on an existing install is, since
  /// nothing wrote this column before authorization existed. Unowned projects
  /// stay fully accessible to everyone so that switching single sign-on on does
  /// not strand people's existing work — see `projectIsAccessible`.
  ///
  /// onDelete=SetNull rather than Cascade: deleting an identity must not delete
  /// the data they produced. The project falls back to unowned, which an admin
  /// can then reassign.
  late final _is.ColumnInt owner;

  /// The group this project belongs to, as the identity provider spells it.
  ///
  /// A **String**, not an id: it holds a claim value verbatim (`cardiology`,
  /// `realm_access.roles` entry, whatever the provider sends) and there is no
  /// table of departments to point at. It was `int?` while nothing could set
  /// it, which is exactly the shape a claim value cannot take.
  ///
  /// Null means "no department", which is every project created before this
  /// and every project on an install with no department claim configured.
  /// `projectIsAccessible` treats null as "owner and admins only" — a
  /// department only ever *widens* access, never narrows it.
  ///
  /// Set through `ProjectEndpoint.setProjectDepartment`, by the owner or an
  /// admin. Stamped automatically at creation when the creator belongs to
  /// exactly one group, because then there is nothing to choose.
  late final _is.ColumnString department;

  /// Unguessable token for the public `/ucsc_track/<token>` URL.
  ///
  /// serverOnly, and handed out only by `FileEndpoint.getUcscTrackToken` after
  /// an access check. The route itself cannot require a session — the fetcher is
  /// genome.ucsc.edu, not a browser — so the token is what stops the track from
  /// being enumerable. Null on projects created before this existed; minted on
  /// first request.
  late final _is.ColumnString trackToken;

  late final _is.ColumnSerializable<List<String>> genes;

  late final _is.ColumnBool bedFileCreated;

  late final _is.ColumnBool active;

  late final _is.ColumnInt pid;

  late final _is.ColumnInt size;

  late final _is.ColumnBool emailNotification;

  late final _is.ColumnInt options;

  late final _is.ColumnDateTime started;

  late final _is.ColumnDuration completedIn;

  late final _is.ColumnString error;

  /// Something worth knowing about a run that nonetheless succeeded.
  ///
  /// ⚠️ Distinct from [error], and the distinction is the point. Finalizing a
  /// finished run does several things after the MIPs are safely on disk — sizing
  /// the output, timing it, generating the UCSC track — and any of those
  /// throwing used to land in `error`, which marks the whole project failed. A
  /// project whose MIPs designed perfectly well would report "MIP generation
  /// failed" because a track file could not be written.
  ///
  /// `error` means there is no result. `warning` means there is a result and
  /// something about it is worth reading.
  late final _is.ColumnString warning;

  late final _is.ColumnBool cleanup;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    folderName,
    description,
    genome,
    snp,
    created,
    owner,
    department,
    trackToken,
    genes,
    bedFileCreated,
    active,
    pid,
    size,
    emailNotification,
    options,
    started,
    completedIn,
    error,
    warning,
    cleanup,
  ];
}

class ProjectInclude extends _is.IncludeObject {
  ProjectInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Project.t;
}

class ProjectIncludeList extends _is.IncludeList {
  ProjectIncludeList._({
    _is.WhereExpressionBuilder<ProjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Project.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Project.t;
}

class ProjectRepository {
  const ProjectRepository._();

  /// Returns a list of [Project]s matching the given query parameters.
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
  Future<List<Project>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Project] matching the given query parameters.
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
  Future<Project?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Project>(
      where: where?.call(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Project] by its [id] or null if no such row exists.
  Future<Project?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Project>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Project]s in the list and returns the inserted rows.
  ///
  /// The returned [Project]s will have their `id` fields set.
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
  Future<List<Project>> insert(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Project>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Project] and returns the inserted row.
  ///
  /// The returned [Project] will have its `id` field set.
  Future<Project> insertRow(
    _is.DatabaseSession session,
    Project row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Project>(row, transaction: transaction);
  }

  /// Upserts all [Project]s in the list and returns the resulting rows.
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
  /// The returned [Project]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> upsert(
    _is.DatabaseSession session,
    List<Project> rows, {
    required _is.ColumnSelections<ProjectTable> conflictColumns,
    _is.ColumnSelections<ProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Project>(
      rows,
      conflictColumns: conflictColumns(Project.t),
      updateColumns: updateColumns?.call(Project.t),
      updateWhere: updateWhere?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Project] and returns the resulting row.
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
  /// The returned [Project] will have its `id` field set.
  Future<Project?> upsertRow(
    _is.DatabaseSession session,
    Project row, {
    required _is.ColumnSelections<ProjectTable> conflictColumns,
    _is.ColumnSelections<ProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ProjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Project>(
      row,
      conflictColumns: conflictColumns(Project.t),
      updateColumns: updateColumns?.call(Project.t),
      updateWhere: updateWhere?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates all [Project]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> update(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.ColumnSelections<ProjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Project>(
      rows,
      columns: columns?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Project]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Project> updateRow(
    _is.DatabaseSession session,
    Project row, {
    _is.ColumnSelections<ProjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Project>(
      row,
      columns: columns?.call(Project.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Project] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Project?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Project>(
      id,
      columnValues: columnValues(Project.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Project]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ProjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ProjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Project>(
      columnValues: columnValues(Project.t.updateTable),
      where: where(Project.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Project]s in the list and returns the deleted rows.
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
  Future<List<Project>> delete(
    _is.DatabaseSession session,
    List<Project> rows, {
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Project>(
      rows,
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Project].
  Future<Project> deleteRow(
    _is.DatabaseSession session,
    Project row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Project>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Project>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectTable> where,
    _is.OrderByBuilder<ProjectTable>? orderBy,
    _is.OrderByListBuilder<ProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Project>(
      where: where(Project.t),
      orderBy: orderBy?.call(Project.t),
      orderByList: orderByList?.call(Project.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ProjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Project>(
      where: where?.call(Project.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Project] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ProjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Project>(
      where: where(Project.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
