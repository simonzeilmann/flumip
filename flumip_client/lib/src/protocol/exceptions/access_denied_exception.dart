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

/// Raised when the signed-in user may not touch the project they asked for.
///
/// Deliberately distinct from FlumipFileNotFoundException so the app can tell
/// "no such project" from "not yours" and show a message that makes sense. The
/// server does *not* use it to hide existence: list endpoints filter foreign
/// projects out entirely, so a client that never guesses ids never sees this.
abstract class AccessDeniedException
    implements _i1.SerializableException, _i1.SerializableModel {
  AccessDeniedException._({String? message})
    : message = message ?? 'You do not have access to this project';

  factory AccessDeniedException({String? message}) = _AccessDeniedExceptionImpl;

  factory AccessDeniedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AccessDeniedException(
      message: jsonSerialization['message'] as String?,
    );
  }

  String message;

  /// Returns a shallow copy of this [AccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AccessDeniedException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccessDeniedException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'AccessDeniedException(message: $message)';
  }
}

class _AccessDeniedExceptionImpl extends AccessDeniedException {
  _AccessDeniedExceptionImpl({String? message}) : super._(message: message);

  /// Returns a shallow copy of this [AccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AccessDeniedException copyWith({String? message}) {
    return AccessDeniedException(message: message ?? this.message);
  }
}
