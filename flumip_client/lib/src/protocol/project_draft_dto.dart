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
import 'package:flumip_client/src/protocol/protocol.dart' as _i2kzrgg5;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'project_options.dart' as _i4kq7s26;

/// What the create-project form sends: everything a new project needs, in one
/// go. No table.
///
/// The form used to create a bare project and leave the genome, the SNP set and
/// the genes to be set one call at a time on the project's tile. This carries
/// all of it, so that saving the form either makes the whole project or makes
/// nothing — see `ProjectService.createConfiguredProject`.
abstract class ProjectDraftDto
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ProjectDraftDto._({
    required this.name,
    String? description,
    required this.options,
    this.genome,
    this.snp,
    this.genes,
    bool? emailNotification,
  }) : description = description ?? '',
       emailNotification = emailNotification ?? false;

  factory ProjectDraftDto({
    required String name,
    String? description,
    required _i4kq7s26.ProjectOptions options,
    int? genome,
    int? snp,
    List<String>? genes,
    bool? emailNotification,
  }) = _ProjectDraftDtoImpl;

  factory ProjectDraftDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectDraftDto(
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      options: _i2kzrgg5.Protocol().deserialize<_i4kq7s26.ProjectOptions>(
        jsonSerialization['options'],
      ),
      genome: jsonSerialization['genome'] as int?,
      snp: jsonSerialization['snp'] as int?,
      genes: jsonSerialization['genes'] == null
          ? null
          : _i2kzrgg5.Protocol().deserialize<List<String>>(
              jsonSerialization['genes'],
            ),
      emailNotification: jsonSerialization['emailNotification'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['emailNotification'],
            ),
    );
  }

  String name;

  String description;

  /// Unsaved: the server inserts the row itself, so there is no window in which
  /// options exist without a project, and no id for a caller to point elsewhere.
  _i4kq7s26.ProjectOptions options;

  /// The genome to design against, or null to choose it later on the tile.
  int? genome;

  /// Optional even with a genome. Checked like `setSnpById` checks it: visible to
  /// the caller, for this genome's build, and ready.
  int? snp;

  /// Normalised like `addGenesToProject`: trimmed, upper-cased, repeats dropped.
  List<String>? genes;

  bool emailNotification;

  /// Returns a shallow copy of this [ProjectDraftDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ProjectDraftDto copyWith({
    String? name,
    String? description,
    _i4kq7s26.ProjectOptions? options,
    int? genome,
    int? snp,
    List<String>? genes,
    bool? emailNotification,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectDraftDto',
      'name': name,
      'description': description,
      'options': options.toJson(),
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      if (genes != null) 'genes': genes?.toJson(),
      'emailNotification': emailNotification,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProjectDraftDto',
      'name': name,
      'description': description,
      'options': options.toJsonForProtocol(),
      if (genome != null) 'genome': genome,
      if (snp != null) 'snp': snp,
      if (genes != null) 'genes': genes?.toJson(),
      'emailNotification': emailNotification,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ProjectDraftDtoImpl extends ProjectDraftDto {
  _ProjectDraftDtoImpl({
    required String name,
    String? description,
    required _i4kq7s26.ProjectOptions options,
    int? genome,
    int? snp,
    List<String>? genes,
    bool? emailNotification,
  }) : super._(
         name: name,
         description: description,
         options: options,
         genome: genome,
         snp: snp,
         genes: genes,
         emailNotification: emailNotification,
       );

  /// Returns a shallow copy of this [ProjectDraftDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ProjectDraftDto copyWith({
    String? name,
    String? description,
    _i4kq7s26.ProjectOptions? options,
    Object? genome = _Undefined,
    Object? snp = _Undefined,
    Object? genes = _Undefined,
    bool? emailNotification,
  }) {
    return ProjectDraftDto(
      name: name ?? this.name,
      description: description ?? this.description,
      options: options ?? this.options.copyWith(),
      genome: genome is int? ? genome : this.genome,
      snp: snp is int? ? snp : this.snp,
      genes: genes is List<String>?
          ? genes
          : this.genes?.map((e0) => e0).toList(),
      emailNotification: emailNotification ?? this.emailNotification,
    );
  }
}
