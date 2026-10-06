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

/// Everything the settings tab needs to show about the SSO setup that is not
/// itself a setting. No table — transport only.
///
/// [redirectUri] is the highest-value field here: a mismatch between what this
/// server computes and what the provider has registered is the single most
/// common way an OIDC setup fails, and the error surfaces at the provider where
/// the admin cannot see our value. Showing it removes the guesswork.
///
/// [secretConfigured] stands in for the client secret, which is never sent to
/// the browser. [envOverrides] names the fields an environment variable has
/// taken over, so the tab can render them read-only instead of letting an admin
/// save a value that silently has no effect.
abstract class AuthAdminStatusDto
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AuthAdminStatusDto._({
    bool? enabled,
    bool? enforcing,
    bool? secretConfigured,
    required this.envOverrides,
    String? redirectUri,
    bool? discoveryOk,
    this.discoveryError,
    this.authorizationEndpoint,
    this.tokenEndpoint,
  }) : enabled = enabled ?? false,
       enforcing = enforcing ?? false,
       secretConfigured = secretConfigured ?? false,
       redirectUri = redirectUri ?? '',
       discoveryOk = discoveryOk ?? false;

  factory AuthAdminStatusDto({
    bool? enabled,
    bool? enforcing,
    bool? secretConfigured,
    required List<String> envOverrides,
    String? redirectUri,
    bool? discoveryOk,
    String? discoveryError,
    String? authorizationEndpoint,
    String? tokenEndpoint,
  }) = _AuthAdminStatusDtoImpl;

  factory AuthAdminStatusDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthAdminStatusDto(
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      enforcing: jsonSerialization['enforcing'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['enforcing']),
      secretConfigured: jsonSerialization['secretConfigured'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['secretConfigured'],
            ),
      envOverrides: _i2kzrgg5.Protocol().deserialize<List<String>>(
        jsonSerialization['envOverrides'],
      ),
      redirectUri: jsonSerialization['redirectUri'] as String?,
      discoveryOk: jsonSerialization['discoveryOk'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['discoveryOk']),
      discoveryError: jsonSerialization['discoveryError'] as String?,
      authorizationEndpoint:
          jsonSerialization['authorizationEndpoint'] as String?,
      tokenEndpoint: jsonSerialization['tokenEndpoint'] as String?,
    );
  }

  bool enabled;

  bool enforcing;

  bool secretConfigured;

  List<String> envOverrides;

  String redirectUri;

  bool discoveryOk;

  String? discoveryError;

  String? authorizationEndpoint;

  String? tokenEndpoint;

  /// Returns a shallow copy of this [AuthAdminStatusDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AuthAdminStatusDto copyWith({
    bool? enabled,
    bool? enforcing,
    bool? secretConfigured,
    List<String>? envOverrides,
    String? redirectUri,
    bool? discoveryOk,
    String? discoveryError,
    String? authorizationEndpoint,
    String? tokenEndpoint,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthAdminStatusDto',
      'enabled': enabled,
      'enforcing': enforcing,
      'secretConfigured': secretConfigured,
      'envOverrides': envOverrides.toJson(),
      'redirectUri': redirectUri,
      'discoveryOk': discoveryOk,
      if (discoveryError != null) 'discoveryError': discoveryError,
      if (authorizationEndpoint != null)
        'authorizationEndpoint': authorizationEndpoint,
      if (tokenEndpoint != null) 'tokenEndpoint': tokenEndpoint,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthAdminStatusDto',
      'enabled': enabled,
      'enforcing': enforcing,
      'secretConfigured': secretConfigured,
      'envOverrides': envOverrides.toJson(),
      'redirectUri': redirectUri,
      'discoveryOk': discoveryOk,
      if (discoveryError != null) 'discoveryError': discoveryError,
      if (authorizationEndpoint != null)
        'authorizationEndpoint': authorizationEndpoint,
      if (tokenEndpoint != null) 'tokenEndpoint': tokenEndpoint,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthAdminStatusDtoImpl extends AuthAdminStatusDto {
  _AuthAdminStatusDtoImpl({
    bool? enabled,
    bool? enforcing,
    bool? secretConfigured,
    required List<String> envOverrides,
    String? redirectUri,
    bool? discoveryOk,
    String? discoveryError,
    String? authorizationEndpoint,
    String? tokenEndpoint,
  }) : super._(
         enabled: enabled,
         enforcing: enforcing,
         secretConfigured: secretConfigured,
         envOverrides: envOverrides,
         redirectUri: redirectUri,
         discoveryOk: discoveryOk,
         discoveryError: discoveryError,
         authorizationEndpoint: authorizationEndpoint,
         tokenEndpoint: tokenEndpoint,
       );

  /// Returns a shallow copy of this [AuthAdminStatusDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AuthAdminStatusDto copyWith({
    bool? enabled,
    bool? enforcing,
    bool? secretConfigured,
    List<String>? envOverrides,
    String? redirectUri,
    bool? discoveryOk,
    Object? discoveryError = _Undefined,
    Object? authorizationEndpoint = _Undefined,
    Object? tokenEndpoint = _Undefined,
  }) {
    return AuthAdminStatusDto(
      enabled: enabled ?? this.enabled,
      enforcing: enforcing ?? this.enforcing,
      secretConfigured: secretConfigured ?? this.secretConfigured,
      envOverrides: envOverrides ?? this.envOverrides.map((e0) => e0).toList(),
      redirectUri: redirectUri ?? this.redirectUri,
      discoveryOk: discoveryOk ?? this.discoveryOk,
      discoveryError: discoveryError is String?
          ? discoveryError
          : this.discoveryError,
      authorizationEndpoint: authorizationEndpoint is String?
          ? authorizationEndpoint
          : this.authorizationEndpoint,
      tokenEndpoint: tokenEndpoint is String?
          ? tokenEndpoint
          : this.tokenEndpoint,
    );
  }
}
