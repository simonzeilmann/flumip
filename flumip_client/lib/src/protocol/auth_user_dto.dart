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

/// The signed-in user, as shown in the app bar. No table — transport only.
abstract class AuthUserDto implements _i1.SerializableModel {
  AuthUserDto._({
    required this.email,
    String? displayName,
    bool? isAdmin,
  }) : displayName = displayName ?? '',
       isAdmin = isAdmin ?? false;

  factory AuthUserDto({
    required String email,
    String? displayName,
    bool? isAdmin,
  }) = _AuthUserDtoImpl;

  factory AuthUserDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthUserDto(
      email: jsonSerialization['email'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      isAdmin: jsonSerialization['isAdmin'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
    );
  }

  String email;

  String displayName;

  bool isAdmin;

  /// Returns a shallow copy of this [AuthUserDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AuthUserDto copyWith({
    String? email,
    String? displayName,
    bool? isAdmin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthUserDto',
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AuthUserDtoImpl extends AuthUserDto {
  _AuthUserDtoImpl({
    required String email,
    String? displayName,
    bool? isAdmin,
  }) : super._(
         email: email,
         displayName: displayName,
         isAdmin: isAdmin,
       );

  /// Returns a shallow copy of this [AuthUserDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AuthUserDto copyWith({
    String? email,
    String? displayName,
    bool? isAdmin,
  }) {
    return AuthUserDto(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
