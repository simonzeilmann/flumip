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

abstract class FlumipFileNotFoundException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  FlumipFileNotFoundException._({String? message})
    : message = message ?? 'The specified file was not found.';

  factory FlumipFileNotFoundException({String? message}) =
      _FlumipFileNotFoundExceptionImpl;

  factory FlumipFileNotFoundException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return FlumipFileNotFoundException(
      message: jsonSerialization['message'] as String?,
    );
  }

  String message;

  /// Returns a shallow copy of this [FlumipFileNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FlumipFileNotFoundException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {'__className__': 'FlumipFileNotFoundException', 'message': message};
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {'__className__': 'FlumipFileNotFoundException', 'message': message};
  }

  @override
  String toString() {
    return 'FlumipFileNotFoundException(message: $message)';
  }
}

class _FlumipFileNotFoundExceptionImpl extends FlumipFileNotFoundException {
  _FlumipFileNotFoundExceptionImpl({String? message})
    : super._(message: message);

  /// Returns a shallow copy of this [FlumipFileNotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FlumipFileNotFoundException copyWith({String? message}) {
    return FlumipFileNotFoundException(message: message ?? this.message);
  }
}
