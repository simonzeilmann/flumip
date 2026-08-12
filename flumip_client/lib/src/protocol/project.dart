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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'package:flumip_client/src/protocol/protocol.dart' as _i2;

abstract class Project implements _i1.SerializableModel {
  Project._({
    this.id,
    required this.name,
    String? description,
    this.genome,
    this.snp,
    this.tags,
    DateTime? created,
    this.owner,
    this.department,
    this.genes,
    bool? bedFileCreated,
    bool? active,
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
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
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
      description: jsonSerialization['description'] as String?,
      genome: jsonSerialization['genome'] as int?,
      snp: jsonSerialization['snp'] as int?,
      tags: jsonSerialization['tags'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(jsonSerialization['tags']),
      created: jsonSerialization['created'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
      owner: jsonSerialization['owner'] as int?,
      department: jsonSerialization['department'] as int?,
      genes: jsonSerialization['genes'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['genes'],
            ),
      bedFileCreated: jsonSerialization['bedFileCreated'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['bedFileCreated']),
      active: jsonSerialization['active'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['active']),
      size: jsonSerialization['size'] as int?,
      emailNotification: jsonSerialization['emailNotification'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['emailNotification'],
            ),
      options: jsonSerialization['options'] as int,
      started: jsonSerialization['started'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['started']),
      completedIn: jsonSerialization['completedIn'] == null
          ? null
          : _i1.DurationJsonExtension.fromJson(
              jsonSerialization['completedIn'],
            ),
      error: jsonSerialization['error'] as String?,
      warning: jsonSerialization['warning'] as String?,
      cleanup: jsonSerialization['cleanup'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['cleanup']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

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

  List<String>? tags;

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

  /// Reserved. Nothing sets this, because no department claim is collected from
  /// the identity provider. `projectIsAccessible` reads it, but the clause
  /// cannot match while the caller's department is always null. Wiring it means
  /// adding a claim name to Settings — see docs/authorization.md.
  int? department;

  List<String>? genes;

  bool bedFileCreated;

  bool active;

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

  /// Returns a shallow copy of this [Project]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Project copyWith({
    int? id,
    String? name,
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
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
      'description': description,
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      if (tags != null) 'tags': tags?.toJson(),
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

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectImpl extends Project {
  _ProjectImpl({
    int? id,
    required String name,
    String? description,
    int? genome,
    int? snp,
    List<String>? tags,
    DateTime? created,
    int? owner,
    int? department,
    List<String>? genes,
    bool? bedFileCreated,
    bool? active,
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
         description: description,
         genome: genome,
         snp: snp,
         tags: tags,
         created: created,
         owner: owner,
         department: department,
         genes: genes,
         bedFileCreated: bedFileCreated,
         active: active,
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
  @_i1.useResult
  @override
  Project copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    Object? genome = _Undefined,
    Object? snp = _Undefined,
    Object? tags = _Undefined,
    DateTime? created,
    Object? owner = _Undefined,
    Object? department = _Undefined,
    Object? genes = _Undefined,
    bool? bedFileCreated,
    bool? active,
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
      description: description ?? this.description,
      genome: genome is int? ? genome : this.genome,
      snp: snp is int? ? snp : this.snp,
      tags: tags is List<String>? ? tags : this.tags?.map((e0) => e0).toList(),
      created: created ?? this.created,
      owner: owner is int? ? owner : this.owner,
      department: department is int? ? department : this.department,
      genes: genes is List<String>?
          ? genes
          : this.genes?.map((e0) => e0).toList(),
      bedFileCreated: bedFileCreated ?? this.bedFileCreated,
      active: active ?? this.active,
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
