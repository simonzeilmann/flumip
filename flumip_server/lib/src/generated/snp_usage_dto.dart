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

/// One project currently pointing at an SNP. No table.
///
/// Shown in the delete confirmation, so that nobody removes a file three running
/// designs depend on without being told which three.
abstract class SnpUsageDto
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SnpUsageDto._({required this.projectId, required this.projectName});

  factory SnpUsageDto({required int projectId, required String projectName}) =
      _SnpUsageDtoImpl;

  factory SnpUsageDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return SnpUsageDto(
      projectId: jsonSerialization['projectId'] as int,
      projectName: jsonSerialization['projectName'] as String,
    );
  }

  int projectId;

  String projectName;

  /// Returns a shallow copy of this [SnpUsageDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SnpUsageDto copyWith({int? projectId, String? projectName});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SnpUsageDto',
      'projectId': projectId,
      'projectName': projectName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SnpUsageDto',
      'projectId': projectId,
      'projectName': projectName,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _SnpUsageDtoImpl extends SnpUsageDto {
  _SnpUsageDtoImpl({required int projectId, required String projectName})
    : super._(projectId: projectId, projectName: projectName);

  /// Returns a shallow copy of this [SnpUsageDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SnpUsageDto copyWith({int? projectId, String? projectName}) {
    return SnpUsageDto(
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
    );
  }
}
