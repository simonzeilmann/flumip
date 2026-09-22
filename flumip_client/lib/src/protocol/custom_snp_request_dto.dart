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

/// What the app sends to add a custom SNP, whether by upload or by URL. No table.
///
/// The bytes themselves never travel through an endpoint — an upload streams to
/// the `/snp_upload/...` web route, and a URL import is fetched by the server.
/// This carries only the description of what is being added.
abstract class CustomSnpRequestDto
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CustomSnpRequestDto._({
    required this.name,
    String? description,
    required this.genomeId,
    bool? private,
    this.urls,
  }) : description = description ?? '',
       private = private ?? true;

  factory CustomSnpRequestDto({
    required String name,
    String? description,
    required int genomeId,
    bool? private,
    List<String>? urls,
  }) = _CustomSnpRequestDtoImpl;

  factory CustomSnpRequestDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return CustomSnpRequestDto(
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      genomeId: jsonSerialization['genomeId'] as int,
      private: jsonSerialization['private'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['private']),
      urls: jsonSerialization['urls'] == null
          ? null
          : _i2kzrgg5.Protocol().deserialize<List<String>>(
              jsonSerialization['urls'],
            ),
    );
  }

  String name;

  String description;

  /// The build the VCF is called against. Required: there is no sensible default,
  /// and guessing wrong produces wrong MIPs rather than an error.
  int genomeId;

  /// True keeps it visible to the uploader alone. The share toggle flips it later.
  bool private;

  /// For the URL flow: the `.vcf.gz` address and optionally its `.vcf.gz.tbi`.
  /// Ignored by `createUpload`. Validated server-side before the row is inserted —
  /// see `snpSourceUrlRejection`.
  List<String>? urls;

  /// Returns a shallow copy of this [CustomSnpRequestDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CustomSnpRequestDto copyWith({
    String? name,
    String? description,
    int? genomeId,
    bool? private,
    List<String>? urls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomSnpRequestDto',
      'name': name,
      'description': description,
      'genomeId': genomeId,
      'private': private,
      if (urls != null) 'urls': urls?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CustomSnpRequestDto',
      'name': name,
      'description': description,
      'genomeId': genomeId,
      'private': private,
      if (urls != null) 'urls': urls?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CustomSnpRequestDtoImpl extends CustomSnpRequestDto {
  _CustomSnpRequestDtoImpl({
    required String name,
    String? description,
    required int genomeId,
    bool? private,
    List<String>? urls,
  }) : super._(
         name: name,
         description: description,
         genomeId: genomeId,
         private: private,
         urls: urls,
       );

  /// Returns a shallow copy of this [CustomSnpRequestDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CustomSnpRequestDto copyWith({
    String? name,
    String? description,
    int? genomeId,
    bool? private,
    Object? urls = _Undefined,
  }) {
    return CustomSnpRequestDto(
      name: name ?? this.name,
      description: description ?? this.description,
      genomeId: genomeId ?? this.genomeId,
      private: private ?? this.private,
      urls: urls is List<String>? ? urls : this.urls?.map((e0) => e0).toList(),
    );
  }
}
