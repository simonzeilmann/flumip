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
import 'search_hit_kind.dart' as _ia4xis23;

/// One row of the unified search results. No table.
///
/// Deliberately flat, and deliberately narrower than any of the three rows it can
/// describe. A hit needs a label, a subtitle, and *enough to open the thing* —
/// which for an SNP set means the genome it belongs to and the category that
/// genome sits in, because opening an SNP set means opening its genome.
///
/// ⚠️ Carries no path, no owner and no `statusMessage`. `Snp.statusMessage` is
/// documented as able to contain anything, and a list somebody is typing into is
/// the wrong surface for arbitrary text from a remote server. Anything a user
/// needs beyond identifying the row is on the tab the hit opens.
abstract class SearchHitDto
    implements _is.SerializableModel, _is.ProtocolSerialization {
  SearchHitDto._({
    required this.id,
    required this.kind,
    required this.name,
    String? subtitle,
    this.genomeId,
    this.category,
    String? context,
  }) : subtitle = subtitle ?? '',
       context = context ?? '';

  factory SearchHitDto({
    required int id,
    required _ia4xis23.SearchHitKind kind,
    required String name,
    String? subtitle,
    int? genomeId,
    String? category,
    String? context,
  }) = _SearchHitDtoImpl;

  factory SearchHitDto.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchHitDto(
      id: jsonSerialization['id'] as int,
      kind: _ia4xis23.SearchHitKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      name: jsonSerialization['name'] as String,
      subtitle: jsonSerialization['subtitle'] as String?,
      genomeId: jsonSerialization['genomeId'] as int?,
      category: jsonSerialization['category'] as String?,
      context: jsonSerialization['context'] as String?,
    );
  }

  _ia4xis23.SearchHitKind kind;

  /// The row id of the project, genome or SNP set. Unique only within [kind].
  int id;

  String name;

  /// The row's own description, empty when it has none.
  String subtitle;

  /// The genome to open in order to reach this hit: the genome itself for a
  /// genome hit, the owning genome for an SNP set, null for a project.
  int? genomeId;

  /// The rail category that genome sits in, so the client can open the rail on
  /// the way. Null for a project, and for a genome filed under no category.
  String? category;

  /// The trailing line under the name: the genome's name for an SNP set, the
  /// category for a genome, empty for a project.
  String context;

  /// Returns a shallow copy of this [SearchHitDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SearchHitDto copyWith({
    int? id,
    _ia4xis23.SearchHitKind? kind,
    String? name,
    String? subtitle,
    int? genomeId,
    String? category,
    String? context,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchHitDto',
      'id': id,
      'kind': kind.toJson(),
      'name': name,
      'subtitle': subtitle,
      if (genomeId != null) 'genomeId': genomeId,
      if (category != null) 'category': category,
      'context': context,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchHitDto',
      'id': id,
      'kind': kind.toJson(),
      'name': name,
      'subtitle': subtitle,
      if (genomeId != null) 'genomeId': genomeId,
      if (category != null) 'category': category,
      'context': context,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SearchHitDtoImpl extends SearchHitDto {
  _SearchHitDtoImpl({
    required int id,
    required _ia4xis23.SearchHitKind kind,
    required String name,
    String? subtitle,
    int? genomeId,
    String? category,
    String? context,
  }) : super._(
         id: id,
         kind: kind,
         name: name,
         subtitle: subtitle,
         genomeId: genomeId,
         category: category,
         context: context,
       );

  /// Returns a shallow copy of this [SearchHitDto]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SearchHitDto copyWith({
    int? id,
    _ia4xis23.SearchHitKind? kind,
    String? name,
    String? subtitle,
    Object? genomeId = _Undefined,
    Object? category = _Undefined,
    String? context,
  }) {
    return SearchHitDto(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      genomeId: genomeId is int? ? genomeId : this.genomeId,
      category: category is String? ? category : this.category,
      context: context ?? this.context,
    );
  }
}
