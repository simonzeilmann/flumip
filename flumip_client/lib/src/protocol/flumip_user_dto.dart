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

/// A user an administrator can hand a project to. No table — transport only.
///
/// FlumipUser is serverOnly, so reassigning ownership needs a client-facing view
/// of it: the picker has to show who is available and send back which one was
/// chosen. Deliberately narrower than the row — no issuer, subject, or lastLogin
/// — because the picker needs a label and an id and nothing else, and this is
/// the one place where the user list becomes visible to a client at all.
///
/// Distinct from AuthUserDto, which describes *the caller* and carries no id.
/// Both exist because they answer different questions: "who am I" and "who could
/// own this".
abstract class FlumipUserDto
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FlumipUserDto._({required this.id, required this.email, String? displayName})
    : displayName = displayName ?? '';

  factory FlumipUserDto({
    required int id,
    required String email,
    String? displayName,
  }) = _FlumipUserDtoImpl;

  factory FlumipUserDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return FlumipUserDto(
      id: jsonSerialization['id'] as int,
      email: jsonSerialization['email'] as String,
      displayName: jsonSerialization['displayName'] as String?,
    );
  }

  int id;

  String email;

  String displayName;

  /// Returns a shallow copy of this [FlumipUserDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FlumipUserDto copyWith({int? id, String? email, String? displayName});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FlumipUserDto',
      'id': id,
      'email': email,
      'displayName': displayName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FlumipUserDto',
      'id': id,
      'email': email,
      'displayName': displayName,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FlumipUserDtoImpl extends FlumipUserDto {
  _FlumipUserDtoImpl({
    required int id,
    required String email,
    String? displayName,
  }) : super._(id: id, email: email, displayName: displayName);

  /// Returns a shallow copy of this [FlumipUserDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FlumipUserDto copyWith({int? id, String? email, String? displayName}) {
    return FlumipUserDto(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
}
