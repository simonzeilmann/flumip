import 'dart:io';

import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:test/test.dart';

import '../support/mipgen_output.dart';
import '../support/temp_dir.dart';

/// Did this MIP design actually finish?
///
/// ⚠️ **The case these exist for.** mipgen is started detached and polled with
/// `ps -p <pid>`, so nothing in FLUMIP ever sees its exit code — a run that was
/// killed and one that returned 0 look identical from outside. Until this
/// check, the entire success test was "a progress file exists and is not
/// empty", which an interrupted run satisfies just as well as a finished one.
/// A project whose design was cut short was therefore marked **Complete**, and
/// the only hint was a confusing message about the UCSC *track* — generated
/// from the very file that was incomplete.
void main() {
  final service = MipgenService();

  group('progressSaysComplete', () {
    test('accepts a run that reached the marker', () {
      expect(progressSaysComplete(completeProgress.split('\n')), isTrue);
    });

    test('looks through the file, not at its last line', () {
      // ⚠️ The gaps WARNING comes *after* the marker, and gaps are ordinary.
      // Testing the last line would call most healthy runs unfinished.
      expect(completeProgress.trim().split('\n').last, startsWith('WARNING'));
      expect(progressSaysComplete(completeProgress.split('\n')), isTrue);
    });

    test('rejects a run that stopped earlier', () {
      expect(progressSaysComplete(interruptedProgress.split('\n')), isFalse);
    });

    test('rejects an empty progress file', () {
      expect(progressSaysComplete([]), isFalse);
      expect(progressSaysComplete(['']), isFalse);
    });
  });

  group('isShortPickedMipsRow', () {
    test('accepts a full row', () {
      expect(isShortPickedMipsRow(designRow(pickedMipsFieldCount)), isFalse);
    });

    test('rejects a row one field short', () {
      // The exact boundary the UCSC track generator crashed on: it reads
      // values[19], which a nineteen-field row does not have.
      expect(isShortPickedMipsRow(designRow(pickedMipsFieldCount - 1)), isTrue);
    });

    test('a blank line is not a short row', () {
      // mipgen's last write ends in a newline, so a trailing empty line is what
      // a *complete* file looks like. Counting it would fail every good run.
      expect(isShortPickedMipsRow(''), isFalse);
      expect(isShortPickedMipsRow('   '), isFalse);
    });

    test('a row with extra fields is not truncation', () {
      expect(
        isShortPickedMipsRow(designRow(pickedMipsFieldCount + 1)),
        isFalse,
      );
    });
  });

  group('designProblem', () {
    late Directory dir;

    setUp(() => dir = createTempDir('design'));

    File write(String contents) =>
        File('${dir.path}/demo.$pickedMipsSuffix')..writeAsStringSync(contents);

    test('passes a run that finished', () async {
      final problem = await service.designProblem(
        write(completeDesign),
        completeProgress.split('\n'),
      );
      expect(problem, isNull);
    });

    test('a trailing newline is not a truncated row', () async {
      final problem = await service.designProblem(
        write('$completeDesign\n'),
        completeProgress.split('\n'),
      );
      expect(problem, isNull);
    });

    test('reports a run that stopped early, in the reader\'s terms', () async {
      // ⚠️ The design is *intact* here. This is the reading the old code had no
      // way to make: the file mipgen had written so far was fine, and only its
      // own progress file said it never got to the end.
      final problem = await service.designProblem(
        write(completeDesign),
        interruptedProgress.split('\n'),
      );
      expect(problem, contains('interrupted before it finished'));
      expect(problem, contains('should not be used'));
      // ⚠️ mipgen's internals stay out of it. "its progress file never reaches
      // mip picking complete:" named nothing the person reading this can act
      // on — they ran a design, they are not debugging the tool.
      expect(problem, isNot(contains(mipPickingCompleteMarker)));
      expect(problem, isNot(contains('progress file')));
    });

    test('names the row and its field count when one is cut short', () async {
      final problem = await service.designProblem(
        write(truncatedDesign),
        completeProgress.split('\n'),
      );
      // Row 3, with 19 of the 20 fields — enough for somebody to open the file
      // and see the same thing.
      expect(problem, contains('row 3'));
      expect(problem, contains('${pickedMipsFieldCount - 1} of the 20'));
      expect(problem, contains('should not be used'));
    });

    test('reports a design that is not on disk', () async {
      final problem = await service.designProblem(
        File('${dir.path}/demo.$pickedMipsSuffix'),
        completeProgress.split('\n'),
      );
      expect(problem, contains('is missing from this project'));
    });

    test('reports a design with nothing in it', () async {
      final problem = await service.designProblem(
        write(''),
        completeProgress.split('\n'),
      );
      expect(problem, contains('empty'));
    });

    test('the progress file is checked before the design is read', () async {
      // Both are wrong; the earlier failure is the one worth reporting, because
      // a run that stopped before picking explains the short file.
      final problem = await service.designProblem(
        write(truncatedDesign),
        interruptedProgress.split('\n'),
      );
      expect(problem, contains('interrupted before it finished'));
      expect(problem, isNot(contains('row 3')));
    });
  });
}
