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
import 'package:serverpod/serverpod.dart' as _i1;

/// Where an SNP's bytes are in their journey. Only `ready` is usable by mipgen.
///
/// `ready` is the default so that every row predating custom SNPs — every global
/// one the scanner found — is immediately usable without a data migration.
enum SnpImportStatus implements _i1.SerializableModel {
  /// The row and its directory exist, the bytes do not. An upload that was
  /// announced but never sent, or a download not yet picked up.
  pending,

  /// The import future call is streaming. `bytesDownloaded` and `totalBytes` move.
  downloading,

  /// `tabix -p vcf` is building the missing index.
  indexing,

  /// `vcfPath` and `tbiPath` are both set and both files are on disk.
  ready,

  /// `statusMessage` says why. Recoverable through `SnpEndpoint.retryImport`.
  failed;

  static SnpImportStatus fromJson(String name) {
    switch (name) {
      case 'pending':
        return SnpImportStatus.pending;
      case 'downloading':
        return SnpImportStatus.downloading;
      case 'indexing':
        return SnpImportStatus.indexing;
      case 'ready':
        return SnpImportStatus.ready;
      case 'failed':
        return SnpImportStatus.failed;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SnpImportStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
