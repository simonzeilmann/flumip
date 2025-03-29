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

abstract class Genome implements _i1.SerializableModel {
  Genome._({
    this.id,
    required this.name,
    String? description,
    this.path,
    this.fastaPath,
    this.refPath,
    this.snpFolder,
    this.snp,
    this.category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  })  : description = description ?? '',
        active = active ?? true,
        indexed = indexed ?? false,
        indexing = indexing ?? false,
        indexPID = indexPID ?? 0,
        indexResults = indexResults ?? 0,
        size = size ?? 0;

  factory Genome({
    int? id,
    required String name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    List<int>? snp,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) = _GenomeImpl;

  factory Genome.fromJson(Map<String, dynamic> jsonSerialization) {
    return Genome(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      path: jsonSerialization['path'] as String?,
      fastaPath: jsonSerialization['fastaPath'] as String?,
      refPath: jsonSerialization['refPath'] as String?,
      snpFolder: jsonSerialization['snpFolder'] as String?,
      snp: (jsonSerialization['snp'] as List?)?.map((e) => e as int).toList(),
      category: jsonSerialization['category'] as String?,
      active: jsonSerialization['active'] as bool,
      indexed: jsonSerialization['indexed'] as bool,
      indexing: jsonSerialization['indexing'] as bool,
      indexPID: jsonSerialization['indexPID'] as int,
      indexResults: jsonSerialization['indexResults'] as int,
      size: jsonSerialization['size'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String name;

  String description;

  String? path;

  String? fastaPath;

  String? refPath;

  String? snpFolder;

  List<int>? snp;

  String? category;

  bool active;

  bool indexed;

  bool indexing;

  int indexPID;

  int indexResults;

  int size;

  /// Returns a shallow copy of this [Genome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Genome copyWith({
    int? id,
    String? name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    List<int>? snp,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (path != null) 'path': path,
      if (fastaPath != null) 'fastaPath': fastaPath,
      if (refPath != null) 'refPath': refPath,
      if (snpFolder != null) 'snpFolder': snpFolder,
      if (snp != null) 'snp': snp?.toJson(),
      if (category != null) 'category': category,
      'active': active,
      'indexed': indexed,
      'indexing': indexing,
      'indexPID': indexPID,
      'indexResults': indexResults,
      'size': size,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GenomeImpl extends Genome {
  _GenomeImpl({
    int? id,
    required String name,
    String? description,
    String? path,
    String? fastaPath,
    String? refPath,
    String? snpFolder,
    List<int>? snp,
    String? category,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) : super._(
          id: id,
          name: name,
          description: description,
          path: path,
          fastaPath: fastaPath,
          refPath: refPath,
          snpFolder: snpFolder,
          snp: snp,
          category: category,
          active: active,
          indexed: indexed,
          indexing: indexing,
          indexPID: indexPID,
          indexResults: indexResults,
          size: size,
        );

  /// Returns a shallow copy of this [Genome]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Genome copyWith({
    Object? id = _Undefined,
    String? name,
    String? description,
    Object? path = _Undefined,
    Object? fastaPath = _Undefined,
    Object? refPath = _Undefined,
    Object? snpFolder = _Undefined,
    Object? snp = _Undefined,
    Object? category = _Undefined,
    bool? active,
    bool? indexed,
    bool? indexing,
    int? indexPID,
    int? indexResults,
    int? size,
  }) {
    return Genome(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      path: path is String? ? path : this.path,
      fastaPath: fastaPath is String? ? fastaPath : this.fastaPath,
      refPath: refPath is String? ? refPath : this.refPath,
      snpFolder: snpFolder is String? ? snpFolder : this.snpFolder,
      snp: snp is List<int>? ? snp : this.snp?.map((e0) => e0).toList(),
      category: category is String? ? category : this.category,
      active: active ?? this.active,
      indexed: indexed ?? this.indexed,
      indexing: indexing ?? this.indexing,
      indexPID: indexPID ?? this.indexPID,
      indexResults: indexResults ?? this.indexResults,
      size: size ?? this.size,
    );
  }
}
