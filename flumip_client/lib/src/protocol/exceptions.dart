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

abstract class GeneExtractionException
    implements _i1.SerializableException, _i1.SerializableModel {
  GeneExtractionException._({
    String? message,
    int? errorCode,
  }) : message = message ?? 'Bed File Could not be created',
       errorCode = errorCode ?? 1000;

  factory GeneExtractionException({
    String? message,
    int? errorCode,
  }) = _GeneExtractionExceptionImpl;

  factory GeneExtractionException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GeneExtractionException(
      message: jsonSerialization['message'] as String?,
      errorCode: jsonSerialization['errorCode'] as int?,
    );
  }

  String message;

  int errorCode;

  /// Returns a shallow copy of this [GeneExtractionException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GeneExtractionException copyWith({
    String? message,
    int? errorCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GeneExtractionException',
      'message': message,
      'errorCode': errorCode,
    };
  }

  @override
  String toString() {
    return 'GeneExtractionException(message: $message, errorCode: $errorCode)';
  }
}

class _GeneExtractionExceptionImpl extends GeneExtractionException {
  _GeneExtractionExceptionImpl({
    String? message,
    int? errorCode,
  }) : super._(
         message: message,
         errorCode: errorCode,
       );

  /// Returns a shallow copy of this [GeneExtractionException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GeneExtractionException copyWith({
    String? message,
    int? errorCode,
  }) {
    return GeneExtractionException(
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}
