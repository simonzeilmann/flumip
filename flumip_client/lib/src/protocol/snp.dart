/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Snp implements _i1.SerializableModel {
  Snp._({
    this.id,
    required this.name,
    String? description,
    required this.vcfPath,
    required this.tbiPath,
    required this.folder,
    required this.active,
    bool? private,
  })  : description = description ?? '',
        private = private ?? false;

  factory Snp({
    int? id,
    required String name,
    String? description,
    required String vcfPath,
    required String tbiPath,
    required String folder,
    required bool active,
    bool? private,
  }) = _SnpImpl;

  factory Snp.fromJson(Map<String, dynamic> jsonSerialization) {
    return Snp(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      vcfPath: jsonSerialization['vcfPath'] as String,
      tbiPath: jsonSerialization['tbiPath'] as String,
      folder: jsonSerialization['folder'] as String,
      active: jsonSerialization['active'] as bool,
      private: jsonSerialization['private'] as bool,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String description;

  String vcfPath;

  String tbiPath;

  String folder;

  bool active;

  bool private;

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Snp copyWith({
    int? id,
    String? name,
    String? description,
    String? vcfPath,
    String? tbiPath,
    String? folder,
    bool? active,
    bool? private,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'vcfPath': vcfPath,
      'tbiPath': tbiPath,
      'folder': folder,
      'active': active,
      'private': private,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SnpImpl extends Snp {
  _SnpImpl({
    int? id,
    required String name,
    String? description,
    required String vcfPath,
    required String tbiPath,
    required String folder,
    required bool active,
    bool? private,
  }) : super._(
          id: id,
          name: name,
          description: description,
          vcfPath: vcfPath,
          tbiPath: tbiPath,
          folder: folder,
          active: active,
          private: private,
        );

  /// Returns a shallow copy of this [Snp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Snp copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    String? vcfPath,
    String? tbiPath,
    String? folder,
    bool? active,
    bool? private,
  }) {
    return Snp(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      vcfPath: vcfPath ?? this.vcfPath,
      tbiPath: tbiPath ?? this.tbiPath,
      folder: folder ?? this.folder,
      active: active ?? this.active,
      private: private ?? this.private,
    );
  }
}
