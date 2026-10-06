import 'dart:io';

import 'package:flumip_server/src/services/mipgen_service.dart';

/// The suffix the UCSC track gets, after the full name of the design file.
///
/// `<project>.picked_mips.txt.ucsc_track.bed`, which is what the track route
/// and the file list look for.
const ucscTrackSuffix = '.ucsc_track.bed';

/// Item colours, as UCSC's `itemRgb` wants them. One per strand, and fixed: a
/// track whose colours change every time it is rebuilt cannot be compared with
/// the last one, or tested.
const plusStrandRgb = '37,99,235';
const minusStrandRgb = '217,119,6';

/// The UCSC custom track for a design: one BED feature per MIP, the two arms
/// as thin ends and the gap between them as the thick middle.
///
/// FLUMIP's own code. MIPGEN ships a Python script that does the same job, but
/// it is part of MIPGEN and cannot be redistributed modified, and it needed
/// modifying (Python 3, and a crash on truncated input).
///
/// Columns of `picked_mips.txt` read here, zero-based, as its header names
/// them: 1 `logistic_score`, 2 `chr`, 3–4 `ext_probe_start`/`_stop`,
/// 5 `ext_probe_copy`, 7–8 `lig_probe_start`/`_stop`, 17 `probe_strand`,
/// 19 `mip_name`.
class UcscTrack {
  UcscTrack(this.plus, this.minus, this.shortRows);

  /// BED lines, without newline, per strand.
  final List<String> plus;
  final List<String> minus;

  /// Rows with fewer than [pickedMipsFieldCount] fields, which were skipped.
  /// More than zero means the design file was cut short.
  final int shortRows;

  /// Builds the track from the lines of a design file, header included.
  factory UcscTrack.fromPickedMips(Iterable<String> lines) {
    final plus = <String>[];
    final minus = <String>[];
    var shortRows = 0;

    for (final line in lines.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final v = trimmed.split('\t');
      if (v.length < pickedMipsFieldCount) {
        shortRows++;
        continue;
      }
      // Rows without a copy count or with a non-numeric position are not MIPs
      // that can be drawn; MIPGEN's own script skipped them the same way.
      if (v[5] == 'NA' || !_digits.hasMatch(v[4])) continue;

      final ends = [
        int.parse(v[3]),
        int.parse(v[4]),
        int.parse(v[7]),
        int.parse(v[8]),
      ]..sort();
      final strand = v[17];
      final name = '${v[19]}_${double.parse(v[1]).toStringAsFixed(3)}';
      final rgb = strand == '+' ? plusStrandRgb : minusStrandRgb;
      // mipgen's coordinates are 1-based, BED's starts are 0-based, so the
      // start moves back one. The thick part runs from the end of the first
      // arm to just short of the second, as MIPGEN's own script drew it.
      final row = [
        'chr${v[2]}',
        ends[0] - 1,
        ends[3],
        name,
        1,
        strand,
        ends[1],
        ends[2] - 1,
        rgb,
      ].join('\t');
      (strand == '+' ? plus : minus).add(row);
    }
    return UcscTrack(plus, minus, shortRows);
  }

  /// The BED file, with one `track` line per strand so UCSC shows them as two
  /// tracks named after [prefix].
  String toBed(String prefix) {
    final out = StringBuffer()..writeln('track name=${prefix}_plus itemRgb=on');
    plus.forEach(out.writeln);
    out
      ..writeln()
      ..writeln('track name=${prefix}_minus itemRgb=on');
    minus.forEach(out.writeln);
    return out.toString();
  }

  static final _digits = RegExp(r'^\d+$');
}

/// Writes the UCSC track for the design at [pickedMipsPath] beside it.
///
/// ⚠️ Writes whatever could be salvaged, and then throws if rows were skipped:
/// a partial track reported as a finished one is how a truncated design gets
/// mistaken for a complete one.
Future<void> writeUcscTrack(String pickedMipsPath, String prefix) async {
  final track = UcscTrack.fromPickedMips(
    await File(pickedMipsPath).readAsLines(),
  );
  await File(
    '$pickedMipsPath$ucscTrackSuffix',
  ).writeAsString(track.toBed(prefix));
  if (track.shortRows > 0) {
    throw FormatException(
      '${track.shortRows} row(s) of the design had fewer than '
      '$pickedMipsFieldCount values and were left out, so the track is '
      'incomplete.',
    );
  }
}
