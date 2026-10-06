import 'package:flumip_server/src/services/mipgen_service.dart';

/// Fixtures shaped like what mipgen actually leaves in a project directory.
///
/// Taken from a real run on a live install rather than invented, because the
/// whole point of the completeness check is the difference between a run that
/// finished and one that did not — and a fixture that is merely plausible
/// cannot tell you whether the check recognises the real thing.

/// A progress file from a run that reached the end.
///
/// ⚠️ Note what comes *after* the marker. A design with gaps is ordinary, and
/// mipgen appends its WARNING once picking is done — so the completion marker
/// is nowhere near the last line of a healthy file.
const completeProgress =
    '''
all 120 snps loaded; generating files for bwa
bwa copy number analysis finished
mips collapsed! picking mips...
$mipPickingCompleteMarker
demo.picked_mips.txt
and
demo.snps_mips.txt
WARNING: There are 116 gaps in covering supplied regions
''';

/// A progress file from a run that was killed before it finished picking.
///
/// This is what the OOM-killed run left behind: everything up to the step it
/// died in, and nothing after it.
const interruptedProgress = '''
all 120 snps loaded; generating files for bwa
bwa copy number analysis finished
mips collapsed! picking mips...
''';

/// One row of a design, tab-separated, with [fields] values.
///
/// The real header names twenty columns, `>mip_key` first and `mip_name` last;
/// the names do not matter here, only how many there are.
String designRow(int fields) => List.generate(fields, (i) => 'v$i').join('\t');

/// A design that is all there: a header and two full rows.
final completeDesign = [
  designRow(pickedMipsFieldCount),
  designRow(pickedMipsFieldCount),
  designRow(pickedMipsFieldCount),
].join('\n');

/// A design whose last row was cut off mid-write, one field short.
///
/// ⚠️ One field, deliberately. `values[19]` is the last field a full row has,
/// so the boundary the UCSC track generator crashed on is a row with nineteen —
/// and a check that only noticed badly mangled rows would sail past it.
final truncatedDesign = [
  designRow(pickedMipsFieldCount),
  designRow(pickedMipsFieldCount),
  designRow(pickedMipsFieldCount - 1),
].join('\n');
