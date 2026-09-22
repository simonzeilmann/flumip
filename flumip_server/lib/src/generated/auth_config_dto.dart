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

/// What the app needs to know before anyone has signed in.
///
/// Deliberately minimal and safe to serve unauthenticated: whether a sign-in is
/// required at all, and what to put on the button. No table — transport only.
abstract class AuthConfigDto
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AuthConfigDto._({bool? enabled, String? buttonLabel})
    : enabled = enabled ?? false,
      buttonLabel = buttonLabel ?? 'Sign in with SSO';

  factory AuthConfigDto({bool? enabled, String? buttonLabel}) =
      _AuthConfigDtoImpl;

  factory AuthConfigDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthConfigDto(
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      buttonLabel: jsonSerialization['buttonLabel'] as String?,
    );
  }

  bool enabled;

  String buttonLabel;

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuthConfigDto copyWith({bool? enabled, String? buttonLabel});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthConfigDto',
      'enabled': enabled,
      'buttonLabel': buttonLabel,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthConfigDto',
      'enabled': enabled,
      'buttonLabel': buttonLabel,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AuthConfigDtoImpl extends AuthConfigDto {
  _AuthConfigDtoImpl({bool? enabled, String? buttonLabel})
    : super._(enabled: enabled, buttonLabel: buttonLabel);

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuthConfigDto copyWith({bool? enabled, String? buttonLabel}) {
    return AuthConfigDto(
      enabled: enabled ?? this.enabled,
      buttonLabel: buttonLabel ?? this.buttonLabel,
    );
  }
}
