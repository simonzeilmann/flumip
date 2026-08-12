/// Turning a project's UCSC track file into browser links.
///
/// Pure — no `client`, no `BuildContext`, no `web.window`. That is the point of
/// the file existing: this is the only non-trivial *computation* in the project
/// tile, it has already been wrong once in a way nobody noticed (see the note in
/// [ucscTrackUrls]), and while it lived inside a `State` class that imports
/// `main.dart` it could not be tested at all.
library;

/// The span a chromosome covers in a track file.
class GenomeRange {
  GenomeRange(this.name, this.start, this.end);

  final String name;
  int start;
  int end;
}

/// The extent of each chromosome named in [track].
///
/// A track file is tab-separated with `chr…` in the first column; the second and
/// third are the start and end of one feature. One range per chromosome, spanning
/// every feature on it.
List<GenomeRange> genomeRanges(List<String> track) {
  final names = <String>{};
  for (final line in track) {
    if (!line.startsWith('chr')) continue;
    final parts = line.split('\t');
    if (parts.length >= 3) names.add(parts[0]);
  }

  final ranges = <GenomeRange>[];
  for (final name in names) {
    final result = GenomeRange(name, 0x20000000000000, 0);
    for (final line in track) {
      final parts = line.split('\t');
      if (parts.length < 3) continue;
      // ⚠️ An equality, not `line.startsWith(name)`. A prefix match makes `chr1`
      // swallow every feature on `chr10` through `chr19` as well, so its range
      // spans coordinates from chromosomes it has nothing to do with and UCSC
      // opens on a region containing no MIPs. Any panel with genes on both chr1
      // and chr1x was affected — which, on a human panel, is most of them.
      if (parts[0] != name) continue;
      final start = int.parse(parts[1]);
      final end = int.parse(parts[2]);
      if (result.start > start) result.start = start;
      if (result.end < end) result.end = end;
    }
    ranges.add(result);
  }

  return ranges;
}

/// One UCSC Genome Browser URL per range in [track], keyed by chromosome.
///
/// [trackToken] keys the public `/ucsc_track/<token>` URL that UCSC will fetch.
/// It used to be the project's id, which made every project's track readable and
/// enumerable by anyone who could reach the port; the token comes from
/// `client.file.getUcscTrackToken`, which checks access before releasing it.
///
/// ⚠️ Each URL is built from [base] rather than appended to a shared, mutating
/// string. The original did `url +=` inside the loop, so with two ranges the
/// second URL carried the first range's `&position=` as well and UCSC was handed
/// two conflicting positions. Only projects with more than one range were
/// affected, which is presumably why it went unnoticed for so long — and is
/// exactly why this now has a test.
Map<String, String> ucscTrackUrls({
  required List<String> track,
  required String genomeName,
  required String trackToken,
  required String siteUrl,
}) {
  // Anything not recognised is designed against hg38, which is what the app
  // installs by default.
  final db = switch (genomeName) {
    'hg18' || 'hg19' || 'hs1' => genomeName,
    _ => 'hg38',
  };
  final base = 'https://genome.ucsc.edu/cgi-bin/hgTracks?db=$db';

  return {
    for (final range in genomeRanges(track))
      range.name:
          '$base&position=${range.name}:${range.start}-${range.end} '
          '&hgt.customText=$siteUrl/ucsc_track/$trackToken',
  };
}
