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
  String warning = '',
}) => Project(
  id: 1,
  name: 'test',
  description: '',
  genes: genes,
  genome: genome,
  bedFileCreated: bedFileCreated,
  active: active,
  completedIn: completedIn,
  error: error,
  warning: warning,
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

    test('completed with a warning is still complete', () {
      // ⚠️ The whole point of the warning field. Finalizing does things after
      // the MIPs are safely on disk — the UCSC track, for one — and a failure
      // there used to land in `error`, reporting a perfectly good run as failed.
      final state = ProjectState.of(
        p(completedIn: const Duration(minutes: 6), warning: 'no track'),
      );
      expect(state, ProjectState.completeWithWarning);
      expect(state.succeeded, isTrue);
      expect(state.label, 'Complete');
    });

    test('an error still wins over a warning', () {
      expect(
        ProjectState.of(
          p(
            completedIn: const Duration(minutes: 6),
            error: 'boom',
            warning: 'also this',
          ),
        ),
        ProjectState.failed,
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
        ProjectState.of(p(active: true, bedFileCreated: true)),
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
      expect(
        resultHasData(['>mip_key logistic_score chr ext_probe_start']),
        isFalse,
      );
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

  group('ResultCounts', () {
    /// The real shape of `kjh-jhk.snp_mips.txt`, read off disk: a column header,
    /// four designed MIPs, and five remarks interleaved between them.
    const kjhJhk = [
      '>mip_key\tlogistic_score\tchr\text_probe_start',
      '>Alternate MIP(s) could not be generated for SNP in arms of MIP #1',
      '>Alternate MIP(s) could not be generated for SNP in arms of MIP #3',
      '17:43049098-43049259/20,23/-\t0.980682\t17',
      '>Alternate MIP(s) could not be generated for SNP in arms of MIP #14',
      '17:43074397-43074558/16,27/-\t0.962823\t17',
      '17:43076441-43076602/21,24/-\t0.944653\t17',
      '17:43093543-43093704/18,25/-\t0.982997\t17',
      '>Alternate MIP(s) could not be generated for SNP in arms of MIP #48',
      '>Alternate MIP(s) could not be generated for SNP in arms of MIP #61',
    ];

    test('separates designed MIPs from mipgen\'s remarks', () {
      final counts = ResultCounts.of(kjhJhk);
      expect(counts.mips, 4);
      expect(counts.notes, 5);
    });

    test('summarises the split, which "10 lines" did not', () {
      expect(ResultCounts.of(kjhJhk).summary, '4 MIPs · 5 notes');
    });

    test('the column header is not counted as a note', () {
      // ⚠️ Otherwise every file overstates its remarks by one.
      final counts = ResultCounts.of(['>mip_key score chr', 'a row']);
      expect(counts.notes, 0);
      expect(counts.summary, '1 MIP');
    });

    test('a clean run says only how many it produced', () {
      final counts = ResultCounts.of(['>header', 'a', 'b', 'c']);
      expect(counts.summary, '3 MIPs');
    });

    test('a run that produced nothing says so', () {
      expect(ResultCounts.of(['>header']).summary, 'no MIPs');
      expect(
        ResultCounts.of(['>header', '>could not be generated']).summary,
        'no MIPs · 1 note',
      );
    });

    test('blank lines count as neither', () {
      final counts = ResultCounts.of(['>header', '', '  ', 'a row']);
      expect(counts.mips, 1);
      expect(counts.notes, 0);
    });
  });
}
