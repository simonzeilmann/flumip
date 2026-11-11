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

/// What the app needs to know before anyone has signed in.
///
/// Deliberately minimal and safe to serve unauthenticated: whether a sign-in is
/// required at all, and what to put on the button. No table — transport only.
///
/// The public-mode fields are what the entry notice needs to draw itself before
/// the visitor has any credential: they are all shown to every visitor anyway.
abstract class AuthConfigDto
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AuthConfigDto._({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    this.projectRetentionHours,
    this.maxProjectLifetimeHours,
    this.guestSnpMaxBytes,
    this.guestSnpRetentionDays,
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
    int? guestSnpMaxBytes,
    int? guestSnpRetentionDays,
  }) = _AuthConfigDtoImpl;

  factory AuthConfigDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuthConfigDto(
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      buttonLabel: jsonSerialization['buttonLabel'] as String?,
      publicMode: jsonSerialization['publicMode'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['publicMode']),
      publicNoticeText: jsonSerialization['publicNoticeText'] as String?,
      imprintUrl: jsonSerialization['imprintUrl'] as String?,
      privacyUrl: jsonSerialization['privacyUrl'] as String?,
      projectRetentionHours: jsonSerialization['projectRetentionHours'] as int?,
      maxProjectLifetimeHours:
          jsonSerialization['maxProjectLifetimeHours'] as int?,
      guestSnpMaxBytes: jsonSerialization['guestSnpMaxBytes'] as int?,
      guestSnpRetentionDays: jsonSerialization['guestSnpRetentionDays'] as int?,
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

  /// The largest file a guest may upload as part of an SNP set, in bytes, or
  /// null when guests cannot add SNP sets (or this is not a public instance).
  int? guestSnpMaxBytes;

  /// How long a guest's SNP set is kept, in days. Null exactly when
  /// [guestSnpMaxBytes] is.
  int? guestSnpRetentionDays;

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AuthConfigDto copyWith({
    bool? enabled,
    String? buttonLabel,
    bool? publicMode,
    String? publicNoticeText,
    String? imprintUrl,
    String? privacyUrl,
    int? projectRetentionHours,
    int? maxProjectLifetimeHours,
    int? guestSnpMaxBytes,
    int? guestSnpRetentionDays,
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
      if (guestSnpMaxBytes != null) 'guestSnpMaxBytes': guestSnpMaxBytes,
      if (guestSnpRetentionDays != null)
        'guestSnpRetentionDays': guestSnpRetentionDays,
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
      if (guestSnpMaxBytes != null) 'guestSnpMaxBytes': guestSnpMaxBytes,
      if (guestSnpRetentionDays != null)
        'guestSnpRetentionDays': guestSnpRetentionDays,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
    int? guestSnpMaxBytes,
    int? guestSnpRetentionDays,
  }) : super._(
         enabled: enabled,
         buttonLabel: buttonLabel,
         publicMode: publicMode,
         publicNoticeText: publicNoticeText,
         imprintUrl: imprintUrl,
         privacyUrl: privacyUrl,
         projectRetentionHours: projectRetentionHours,
         maxProjectLifetimeHours: maxProjectLifetimeHours,
         guestSnpMaxBytes: guestSnpMaxBytes,
         guestSnpRetentionDays: guestSnpRetentionDays,
       );

  /// Returns a shallow copy of this [AuthConfigDto]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    Object? guestSnpMaxBytes = _Undefined,
    Object? guestSnpRetentionDays = _Undefined,
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
      guestSnpMaxBytes: guestSnpMaxBytes is int?
          ? guestSnpMaxBytes
          : this.guestSnpMaxBytes,
      guestSnpRetentionDays: guestSnpRetentionDays is int?
          ? guestSnpRetentionDays
          : this.guestSnpRetentionDays,
    );
  }
}
