import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/mipgen_progress.dart';
import 'package:flumip_flutter/project/project_state.dart';
import 'package:flutter_test/flutter_test.dart';

Project p({
  List<String>? genes,
  int? genome,
  bool bedFileCreated = false,
  bool active = false,
  Duration? completedIn,
  String error = '',
}) =>
    Project(
      id: 1,
      name: 'test',
      description: '',
      genes: genes,
      genome: genome,
      bedFileCreated: bedFileCreated,
      active: active,
      completedIn: completedIn,
      error: error,
      size: 0,
      options: 1,
      created: DateTime(2026),
    );

void main() {
  group('ProjectState.of', () {
    test('a bare project is a draft', () {
      expect(ProjectState.of(p()), ProjectState.draft);
    });

    test('genes without a genome is still a draft', () {
      expect(ProjectState.of(p(genes: ['BRCA1'])), ProjectState.draft);
    });

    test('genome and genes but no BED file needs one', () {
      expect(
        ProjectState.of(p(genes: ['BRCA1'], genome: 3)),
        ProjectState.needsBedFile,
      );
    });

    test('a BED file makes it ready to run', () {
      expect(
        ProjectState.of(p(genes: ['BRCA1'], genome: 3, bedFileCreated: true)),
        ProjectState.readyToRun,
      );
    });

    test('active with no completion is running', () {
      expect(
        ProjectState.of(p(bedFileCreated: true, active: true)),
        ProjectState.running,
      );
    });

    test('completed with no error is complete', () {
      expect(
        ProjectState.of(p(completedIn: const Duration(minutes: 6))),
        ProjectState.complete,
      );
    });

    test('completed with an error is failed', () {
      expect(
        ProjectState.of(
          p(completedIn: const Duration(minutes: 6), error: 'boom'),
        ),
        ProjectState.failed,
      );
    });

    test('running wins over a previous completion', () {
      // ⚠️ Re-running a finished project leaves `completedIn` set from last
      // time. Checking it first would report a live run as "Complete".
      expect(
        ProjectState.of(
          p(active: true, bedFileCreated: true),
        ),
        ProjectState.running,
      );
    });

    test('every state has a label', () {
      for (final state in ProjectState.values) {
        expect(state.label, isNotEmpty);
      }
    });
  });

  group('resultHasData', () {
    test('a file with rows has data', () {
      expect(resultHasData(['>mip_key score chr', 'row one']), isTrue);
    });

    test('a header on its own does not', () {
      // ⚠️ The case from project kjh-jhk: the run wrote the file with its header
      // and no MIPs, and opening it showed an empty box with a scrollbar.
      expect(resultHasData(['>mip_key logistic_score chr ext_probe_start']),
          isFalse);
    });

    test('headers and blank lines together do not', () {
      expect(resultHasData(['>header', '', '   ', '>another']), isFalse);
    });

    test('an absent file does not', () {
      expect(resultHasData([]), isFalse);
    });

    test('a row that merely mentions ">" still counts', () {
      // Only a *leading* ">" marks a header.
      expect(resultHasData(['chr1 100 a>b']), isTrue);
    });
  });
}
