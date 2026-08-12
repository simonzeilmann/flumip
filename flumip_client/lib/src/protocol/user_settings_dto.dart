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

/// The settings the calling user may see, and whether they may administer.
///
/// **This is the extension point for per-user settings.** There are none yet —
/// every field on `Settings` is server configuration that only an administrator
/// has any business reading — so today this carries just the two flags the app
/// needs to decide what to render. When a genuinely per-user setting is defined
/// (a preferred genome, a default for `emailNotification`, a display
/// preference), it belongs here: add the field, have `SettingsEndpoint.userSettings`
/// fill it in from the caller's identity, and render it in the Settings tab's
/// user view, which already exists and says there is nothing yet.
///
/// Deliberately NOT the `Settings` object with fields blanked out. A reduced
/// copy of a bigger model invites the mistake of adding a field to the model and
/// having it silently reach a client that must not see it — the same trap
/// `SettingsService.updateSettings` guards against with its explicit field list.
/// Anything on this class is here because somebody chose to expose it.
///
/// No table — transport only.
abstract class UserSettingsDto implements _i1.SerializableModel {
  UserSettingsDto._({
    bool? isAdmin,
    bool? passwordAccepted,
  }) : isAdmin = isAdmin ?? false,
       passwordAccepted = passwordAccepted ?? true;

  factory UserSettingsDto({
    bool? isAdmin,
    bool? passwordAccepted,
  }) = _UserSettingsDtoImpl;

  factory UserSettingsDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserSettingsDto(
      isAdmin: jsonSerialization['isAdmin'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      passwordAccepted: jsonSerialization['passwordAccepted'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['passwordAccepted'],
            ),
    );
  }

  /// Whether this caller may read and write the server configuration.
  ///
  /// The app has the same answer from the session token, but asking the server
  /// keeps the decision on the server: the admin form is populated by
  /// `getSettings`, which enforces this independently, so a client that lied
  /// here would gain nothing.
  bool isAdmin;

  /// Whether the settings password can still be used to reach the admin form.
  ///
  /// False once single sign-on is enforcing, at which point identity is the only
  /// way in and offering a password box would be offering something that cannot
  /// work. See `SettingsService._isAdmin`.
  bool passwordAccepted;

  /// Returns a shallow copy of this [UserSettingsDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserSettingsDto copyWith({
    bool? isAdmin,
    bool? passwordAccepted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserSettingsDto',
      'isAdmin': isAdmin,
      'passwordAccepted': passwordAccepted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _UserSettingsDtoImpl extends UserSettingsDto {
  _UserSettingsDtoImpl({
    bool? isAdmin,
    bool? passwordAccepted,
  }) : super._(
         isAdmin: isAdmin,
         passwordAccepted: passwordAccepted,
       );

  /// Returns a shallow copy of this [UserSettingsDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserSettingsDto copyWith({
    bool? isAdmin,
    bool? passwordAccepted,
  }) {
    return UserSettingsDto(
      isAdmin: isAdmin ?? this.isAdmin,
      passwordAccepted: passwordAccepted ?? this.passwordAccepted,
    );
  }
}
