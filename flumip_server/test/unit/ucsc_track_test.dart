import 'dart:io';

import 'package:flumip_server/src/services/ucsc_track.dart';
import 'package:test/test.dart';

import '../support/temp_dir.dart';

/// The header of a real `picked_mips.txt`.
const header =
    '>mip_key\tlogistic_score\tchr\text_probe_start\text_probe_stop\t'
    'ext_probe_copy\text_probe_sequence\tlig_probe_start\tlig_probe_stop\t'
    'lig_probe_copy\tlig_probe_sequence\tmip_scan_start_position\t'
    'mip_scan_stop_position\tscan_target_sequence\tmip_sequence\t'
    'feature_start_position\tfeature_stop_position\tprobe_strand\t'
    'failure_flags\tmip_name';

/// A row from a real MYH11 design on hg38, with [strand], [copy] and
/// [extStop] swappable for the cases below.
String row({
  String strand = '-',
  String copy = '2',
  String extStop = '15771595',
}) => [
  '16:15771434-15771595/16,29/$strand',
  '0.784409',
  '16',
  '15771580',
  extStop,
  copy,
  'TGGGTTTCAGCGAGGA',
  '15771434',
  '15771462',
  '1',
  'CCTTCCATTAAAAAAAAAAAAAAAAAAGG',
  '15771463',
  '15771579',
  'GGAG',
  'CCTT',
  '15771568',
  '15771712',
  strand,
  '000',
  'MYH11/NM_022844_0001',
].join('\t');

void main() {
  group('UcscTrack.fromPickedMips', () {
    test('turns a MIP into a BED feature with its arms as thin ends', () {
      // Checked against what MIPGEN's own generate_ucsc_track.py writes for
      // this row, colour aside.
      final track = UcscTrack.fromPickedMips([header, row()]);
      expect(track.minus, [
        'chr16\t15771433\t15771595\tMYH11/NM_022844_0001_0.784\t1\t-\t'
            '15771462\t15771579\t$minusStrandRgb',
      ]);
      expect(track.plus, isEmpty);
      expect(track.shortRows, 0);
    });

    test('splits the strands and colours them apart', () {
      final track = UcscTrack.fromPickedMips([
        header,
        row(strand: '+'),
        row(strand: '-'),
      ]);
      expect(
        track.plus.single,
        endsWith('\t+\t15771462\t15771579\t$plusStrandRgb'),
      );
      expect(
        track.minus.single,
        endsWith('\t-\t15771462\t15771579\t$minusStrandRgb'),
      );
    });

    test('skips MIPs with no copy count or a non-numeric position', () {
      final track = UcscTrack.fromPickedMips([
        header,
        row(copy: 'NA'),
        row(extStop: 'x'),
      ]);
      expect(track.plus, isEmpty);
      expect(track.minus, isEmpty);
      expect(track.shortRows, 0);
    });

    test('counts rows cut short instead of crashing on them', () {
      // The case MIPGEN's script died on with an IndexError.
      final cut = row().split('\t')..removeLast();
      final track = UcscTrack.fromPickedMips([
        header,
        row(),
        cut.join('\t'),
        '',
      ]);
      expect(track.minus, hasLength(1));
      expect(track.shortRows, 1);
    });

    test('a design with no MIPs is two empty tracks', () {
      expect(
        UcscTrack.fromPickedMips([header]).toBed('demo'),
        'track name=demo_plus itemRgb=on\n'
        '\n'
        'track name=demo_minus itemRgb=on\n',
      );
    });
  });

  group('writeUcscTrack', () {
    test('writes the track beside the design', () async {
      final dir = createTempDir('ucsc');
      final design = '${dir.path}/demo.picked_mips.txt';
      File(design).writeAsStringSync('$header\n${row(strand: '+')}\n');

      await writeUcscTrack(design, 'demo_ucsc_track');

      expect(
        File('$design$ucscTrackSuffix').readAsStringSync(),
        'track name=demo_ucsc_track_plus itemRgb=on\n'
        'chr16\t15771433\t15771595\tMYH11/NM_022844_0001_0.784\t1\t+\t'
        '15771462\t15771579\t$plusStrandRgb\n'
        '\n'
        'track name=demo_ucsc_track_minus itemRgb=on\n',
      );
    });

    test('writes what it can, then says the design was incomplete', () async {
      final dir = createTempDir('ucsc');
      final design = '${dir.path}/demo.picked_mips.txt';
      File(design).writeAsStringSync('$header\n${row()}\nshort\trow\n');

      await expectLater(
        writeUcscTrack(design, 'demo'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('1 row(s)'),
          ),
        ),
      );
      expect(
        File('$design$ucscTrackSuffix').readAsStringSync(),
        contains('MYH11'),
      );
    });
  });
}
