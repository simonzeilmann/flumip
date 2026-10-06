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

/// Raised when the signed-in user may not touch the project they asked for.
///
/// Named for projects rather than called `AccessDeniedException` because
/// Serverpod already ships one of those, for its Insights endpoint. Two types
/// with the same name make any library that imports both protocols fail to
/// compile, and the specific name reads better at the catch site anyway.
///
/// Deliberately distinct from FlumipFileNotFoundException so the app can tell
/// "no such project" from "not yours" and show a message that makes sense. The
/// server does *not* use it to hide existence: list endpoints filter foreign
/// projects out entirely, so a client that never guesses ids never sees this.
abstract class ProjectAccessDeniedException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  ProjectAccessDeniedException._({String? message})
    : message = message ?? 'You do not have access to this project.';

  factory ProjectAccessDeniedException({String? message}) =
      _ProjectAccessDeniedExceptionImpl;

  factory ProjectAccessDeniedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProjectAccessDeniedException(
      message: jsonSerialization['message'] as String?,
    );
  }

  String message;

  /// Returns a shallow copy of this [ProjectAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ProjectAccessDeniedException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProjectAccessDeniedException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProjectAccessDeniedException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ProjectAccessDeniedException(message: $message)';
  }
}

class _ProjectAccessDeniedExceptionImpl extends ProjectAccessDeniedException {
  _ProjectAccessDeniedExceptionImpl({String? message})
    : super._(message: message);

  /// Returns a shallow copy of this [ProjectAccessDeniedException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ProjectAccessDeniedException copyWith({String? message}) {
    return ProjectAccessDeniedException(message: message ?? this.message);
  }
}
