import 'package:flumip_flutter/project/ucsc_track.dart';
import 'package:flutter_test/flutter_test.dart';

/// The first tests this code has ever had.
///
/// It lived inside a `State` class in `project_tile.dart`, which imports
/// `main.dart` and so builds a Serverpod client at import time — nothing in the
/// suite could reach it. It also carried a bug for its whole life (see the
/// two-range test below), which is what a pure function with no tests buys you.
void main() {
  const token = 'abc123';
  const site = 'https://flumip.example';

  // Two features on chr1 and one on chr7, tab-separated, as mipgen writes them.
  const track = [
    'track name="MIPs"',
    'chr1\t1000\t1200\tmip_1',
    'chr1\t5000\t5400\tmip_2',
    'chr7\t900\t950\tmip_3',
  ];

  group('genomeRanges', () {
    test('spans every feature on a chromosome', () {
      final ranges = genomeRanges(track);
      final chr1 = ranges.firstWhere((r) => r.name == 'chr1');

      expect(chr1.start, 1000);
      expect(chr1.end, 5400);
    });

    test('one range per chromosome', () {
      expect(
        genomeRanges(track).map((r) => r.name),
        unorderedEquals(['chr1', 'chr7']),
      );
    });

    test('ignores lines that are not features', () {
      // The `track name=` header, and anything short of three columns.
      expect(genomeRanges(const ['track name="MIPs"', 'chr1\t10']), isEmpty);
    });

    test('an empty file names no ranges', () {
      expect(genomeRanges(const []), isEmpty);
    });

    test('⚠️ chr1 does not swallow chr10', () {
      // The chromosome was matched with `line.startsWith(name)`, so chr1's range
      // absorbed every feature on chr10 through chr19 and UCSC opened on a span
      // containing no MIPs. On a human panel, genes on both chr1 and one of the
      // chr1x chromosomes is the common case, not the corner one.
      final ranges = genomeRanges(const [
        'chr1\t1000\t1200\tmip_1',
        'chr10\t90000000\t90000400\tmip_2',
      ]);

      final chr1 = ranges.firstWhere((r) => r.name == 'chr1');
      expect(chr1.start, 1000);
      expect(chr1.end, 1200);

      final chr10 = ranges.firstWhere((r) => r.name == 'chr10');
      expect(chr10.start, 90000000);
      expect(chr10.end, 90000400);
    });
  });

  group('ucscTrackUrls', () {
    test('carries the position and the track URL', () {
      final urls = ucscTrackUrls(
        track: track,
        genomeName: 'hg38',
        trackToken: token,
        siteUrl: site,
      );

      expect(urls['chr7'], contains('db=hg38'));
      expect(urls['chr7'], contains('position=chr7:900-950'));
      expect(urls['chr7'], contains('hgt.customText=$site/ucsc_track/$token'));
    });

    test('⚠️ each range gets its own position, and only its own', () {
      // The regression guard. This was `url +=` inside the loop, mutating the
      // shared base, so the second URL carried the first range's `&position=` as
      // well and UCSC was handed two conflicting positions. Only projects with
      // more than one range were affected, which is why it went unnoticed.
      final urls = ucscTrackUrls(
        track: track,
        genomeName: 'hg38',
        trackToken: token,
        siteUrl: site,
      );

      expect(urls, hasLength(2));
      for (final url in urls.values) {
        expect('position='.allMatches(url), hasLength(1));
      }
      expect(urls['chr7'], isNot(contains('chr1:')));
      expect(urls['chr1'], isNot(contains('chr7:')));
    });

    test('every link is keyed by the token, never the project id', () {
      // Making this the project id is what made every project's track readable
      // and enumerable by anyone who could reach the port.
      final urls = ucscTrackUrls(
        track: track,
        genomeName: 'hg38',
        trackToken: token,
        siteUrl: site,
      );
      for (final url in urls.values) {
        expect(url, contains('/ucsc_track/$token'));
      }
    });

    test('the assemblies UCSC knows are passed through', () {
      for (final db in ['hg18', 'hg19', 'hs1']) {
        final urls = ucscTrackUrls(
          track: track,
          genomeName: db,
          trackToken: token,
          siteUrl: site,
        );
        expect(urls['chr1'], contains('db=$db'));
      }
    });

    test('anything else is designed against hg38', () {
      // Which is what the app installs by default.
      for (final name in ['', 'default', 'mm10', 'some-local-assembly']) {
        final urls = ucscTrackUrls(
          track: track,
          genomeName: name,
          trackToken: token,
          siteUrl: site,
        );
        expect(urls['chr1'], contains('db=hg38'));
      }
    });

    test('a track file with no features yields no links', () {
      expect(
        ucscTrackUrls(
          track: const ['track name="MIPs"'],
          genomeName: 'hg38',
          trackToken: token,
          siteUrl: site,
        ),
        isEmpty,
      );
    });
  });
}
