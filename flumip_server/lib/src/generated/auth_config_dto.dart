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
///
/// The public-mode fields are what the entry notice needs to draw itself before
/// the visitor has any credential: they are all shown to every visitor anyway.
abstract class AuthConfigDto
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AuthConfigDto._({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    this.projectRetentionHours,
    this.maxProjectLifetimeHours,
  }) : enabled = enabled ?? false,
       buttonLabel = buttonLabel ?? 'Sign in with SSO',
       publicMode = publicMode ?? false,
       publicNoticeText = publicNoticeText ?? '',
       imprintUrl = imprintUrl ?? '',
       privacyUrl = privacyUrl ?? '';

  factory AuthConfigDto({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    int? projectRetentionHours,
    int? maxProjectLifetimeHours,
  }) = _AuthConfigDtoImpl;

  factory AuthConfigDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthConfigDto(
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      buttonLabel: jsonSerialization['buttonLabel'] as String?,
      publicMode: jsonSerialization['publicMode'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['publicMode']),
      publicNoticeText: jsonSerialization['publicNoticeText'] as String?,
      imprintUrl: jsonSerialization['imprintUrl'] as String?,
      privacyUrl: jsonSerialization['privacyUrl'] as String?,
      projectRetentionHours: jsonSerialization['projectRetentionHours'] as int?,
      maxProjectLifetimeHours:
          jsonSerialization['maxProjectLifetimeHours'] as int?,
    );
  }

  bool enabled;

  String buttonLabel;

  bool publicMode;

  String publicNoticeText;

  String imprintUrl;

  String privacyUrl;

  /// How long a new project is kept, in hours, or null when nothing on this
  /// server is deleted automatically.
  int? projectRetentionHours;

  /// The furthest "Keep longer" can go, in hours after creation. Null exactly
  /// when [projectRetentionHours] is.
  int? maxProjectLifetimeHours;

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuthConfigDto copyWith({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    int? projectRetentionHours,
    int? maxProjectLifetimeHours,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuthConfigDto',
      'enabled': enabled,
      'buttonLabel': buttonLabel,
      'publicMode': publicMode,
      'publicNoticeText': publicNoticeText,
      'imprintUrl': imprintUrl,
      'privacyUrl': privacyUrl,
      if (projectRetentionHours != null)
        'projectRetentionHours': projectRetentionHours,
      if (maxProjectLifetimeHours != null)
        'maxProjectLifetimeHours': maxProjectLifetimeHours,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuthConfigDto',
      'enabled': enabled,
      'buttonLabel': buttonLabel,
      'publicMode': publicMode,
      'publicNoticeText': publicNoticeText,
      'imprintUrl': imprintUrl,
      'privacyUrl': privacyUrl,
      if (projectRetentionHours != null)
        'projectRetentionHours': projectRetentionHours,
      if (maxProjectLifetimeHours != null)
        'maxProjectLifetimeHours': maxProjectLifetimeHours,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuthConfigDtoImpl extends AuthConfigDto {
  _AuthConfigDtoImpl({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    int? projectRetentionHours,
    int? maxProjectLifetimeHours,
  }) : super._(
         enabled: enabled,
         buttonLabel: buttonLabel,
         publicMode: publicMode,
         publicNoticeText: publicNoticeText,
         imprintUrl: imprintUrl,
         privacyUrl: privacyUrl,
         projectRetentionHours: projectRetentionHours,
         maxProjectLifetimeHours: maxProjectLifetimeHours,
       );

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuthConfigDto copyWith({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    Object? projectRetentionHours = _Undefined,
    Object? maxProjectLifetimeHours = _Undefined,
  }) {
    return AuthConfigDto(
      enabled: enabled ?? this.enabled,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      publicMode: publicMode ?? this.publicMode,
      publicNoticeText: publicNoticeText ?? this.publicNoticeText,
      imprintUrl: imprintUrl ?? this.imprintUrl,
      privacyUrl: privacyUrl ?? this.privacyUrl,
      projectRetentionHours: projectRetentionHours is int?
          ? projectRetentionHours
          : this.projectRetentionHours,
      maxProjectLifetimeHours: maxProjectLifetimeHours is int?
          ? maxProjectLifetimeHours
          : this.maxProjectLifetimeHours,
    );
  }
}
