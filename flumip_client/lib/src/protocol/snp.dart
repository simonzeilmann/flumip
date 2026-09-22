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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
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
abstract class Snp
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
      active: _isc.BoolJsonExtension.fromJson(jsonSerialization['active']),
      private: jsonSerialization['private'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['private']),
      size: jsonSerialization['size'] as int?,
      genome: jsonSerialization['genome'] as int?,
      owner: jsonSerialization['owner'] as int?,
      custom: jsonSerialization['custom'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['custom']),
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
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['statusUpdated'],
            ),
      created: jsonSerialization['created'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['created']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
