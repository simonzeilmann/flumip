import 'package:flumip_server/src/services/snp_service.dart';

/// Bytes that look like a **complete** bgzip file to `SnpService.vcfProblem`.
///
/// ⚠️ Use this rather than a hand-written header for any fixture standing in for
/// a VCF. A header alone is, by the rule the service now applies, a *truncated*
/// file — which is the point of that rule, and means a fixture without the
/// end-of-file block fails for the right reason at a confusing moment.
///
/// The BGZF EOF marker is itself a well-formed empty BGZF member, so it doubles
/// as the smallest complete file there is.
List<int> completeBgzf({int filler = 0}) => [
      ...SnpService.bgzfEofMarker,
      if (filler > 0) ...List.filled(filler, 0x78),
      if (filler > 0) ...SnpService.bgzfEofMarker,
    ];

/// Bytes that are bgzip-shaped but stop before the end-of-file block.
///
/// Indistinguishable from a good file to `tabix`, which indexes it, exits 0, and
/// mentions the truncation only as a warning.
List<int> truncatedBgzf() => [
      ...SnpService.bgzfEofMarker,
      ...List.filled(120, 0x78),
    ];

/// Bytes compressed with plain `gzip` rather than `bgzip`.
List<int> plainGzip() => [...completeBgzf()]..[3] = 0x00; // FEXTRA cleared
