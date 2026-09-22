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

/// Which of the three things a search hit is. No table.
///
/// Decides the icon a hit gets, the group it appears under, and which tab opening
/// it lands on — so the client's tab indices are keyed off this and nothing else.
///
/// `serialized: byName` for the same reason `SnpImportStatus` uses it: reordering
/// these values must not silently repoint traffic already on the wire.
enum SearchHitKind implements _isc.SerializableModel {
  /// A row of the projects tab.
  project,

  /// A genome in the library, whatever category the rail files it under.
  genome,

  /// An SNP set, global or custom. Named `snpSet` rather than `snp` because that
  /// is what the UI calls it everywhere.
  snpSet;

  static SearchHitKind fromJson(String name) {
    switch (name) {
      case 'project':
        return SearchHitKind.project;
      case 'genome':
        return SearchHitKind.genome;
      case 'snpSet':
        return SearchHitKind.snpSet;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SearchHitKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
