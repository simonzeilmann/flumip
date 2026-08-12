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

/// One downloadable file in a project's directory. No table — transport only.
///
/// Carries the name and the size so the app can list what is there and say how
/// big it is *before* anyone clicks. A project that kept its intermediates can
/// be gigabytes, and "Download all" with no indication of size is how somebody
/// accidentally starts a 4 GB transfer over a hotel connection.
///
/// The bytes themselves never travel through an endpoint — they are streamed by
/// the `/download/...` web route, which can send a file far larger than a
/// serialised endpoint response should ever hold.
abstract class ProjectFileDto
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ProjectFileDto._({
    required this.name,
    required this.sizeBytes,
  });

  factory ProjectFileDto({
    required String name,
    required int sizeBytes,
  }) = _ProjectFileDtoImpl;

  factory ProjectFileDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProjectFileDto(
      name: jsonSerialization['name'] as String,
      sizeBytes: jsonSerialization['sizeBytes'] as int,
    );
  }

  String name;

  int sizeBytes;

  /// Returns a shallow copy of this [ProjectFileDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProjectFileDto copyWith({
    String? name,
    int? sizeBytes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectFileDto',
      'name': name,
      'sizeBytes': sizeBytes,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProjectFileDto',
      'name': name,
      'sizeBytes': sizeBytes,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ProjectFileDtoImpl extends ProjectFileDto {
  _ProjectFileDtoImpl({
    required String name,
    required int sizeBytes,
  }) : super._(
         name: name,
         sizeBytes: sizeBytes,
       );

  /// Returns a shallow copy of this [ProjectFileDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProjectFileDto copyWith({
    String? name,
    int? sizeBytes,
  }) {
    return ProjectFileDto(
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}
