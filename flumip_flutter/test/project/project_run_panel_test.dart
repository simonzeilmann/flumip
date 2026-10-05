import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/mipgen_progress.dart';
import 'package:flumip_flutter/project/project_run_panel.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The right-hand column of an expanded project tile.
///
/// Testable at all only because it was lifted out of `project_tile.dart`, which
/// imports `main.dart` and so builds a Serverpod client the moment a test file
/// mentions it. This is the first coverage of "which buttons does a project in
/// state X actually offer", which is the whole job of the column.
Project projectFixture({
  bool bedFileCreated = false,
  bool active = false,
  Duration? completedIn,
  String error = '',
  String warning = '',
  List<String>? genes,
  int? genome,
  int? snp,
  int? owner,
  bool emailNotification = false,
  DateTime? started,
  int size = 0,
}) => Project(
  id: 1,
  name: 'panel',
  description: '',
  genes: genes,
  genome: genome,
  snp: snp,
  owner: owner,
  bedFileCreated: bedFileCreated,
  active: active,
  completedIn: completedIn,
  started: started,
  error: error,
  warning: warning,
  emailNotification: emailNotification,
  size: size,
  options: 1,
  created: DateTime(2026),
);

class Calls {
  final pressed = <String>[];
  bool? deleteExcess;
  bool? notify;
}

Future<Calls> pumpPanel(
  WidgetTester tester,
  Project project, {
  bool notificationsAvailable = false,
  bool deleteExcessFiles = true,
  MipgenProgress progress = const MipgenProgress.empty(),
}) async {
  final calls = Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: ProjectRunPanel(
              project: project,
              progress: progress,
              notificationsAvailable: notificationsAvailable,
              deleteExcessFiles: deleteExcessFiles,
              onDeleteExcessFilesChanged: (v) => calls.deleteExcess = v,
              onEmailNotificationChanged: (v) => calls.notify = v,
              onCreateBedFile: () => calls.pressed.add('bed'),
              onGenerateMips: () => calls.pressed.add('generate'),
              onShowMipsResult: () => calls.pressed.add('mips'),
              onShowSnpMipsResult: () => calls.pressed.add('snp-mips'),
              onShowUcscTrack: () => calls.pressed.add('ucsc'),
              onShowUcscTrackFile: () => calls.pressed.add('track-file'),
              onShowDesignLog: () => calls.pressed.add('log'),
              onShowDownloads: () => calls.pressed.add('downloads'),
            ),
          ),
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  group('a project that has not run yet', () {
    testWidgets('a draft is offered the BED step, and nothing else', (
      tester,
    ) async {
      await pumpPanel(tester, projectFixture());

      expect(find.text('Create BED file'), findsOneWidget);
      expect(find.text('Generate MIPs'), findsNothing);
      expect(find.text('Design complete'), findsNothing);
    });

    testWidgets(
      'the BED button is dead until there is something to build from',
      (tester) async {
        await pumpPanel(tester, projectFixture());
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Create BED file'),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('a genome and a gene are enough to build one', (tester) async {
      final calls = await pumpPanel(
        tester,
        projectFixture(genes: ['BRCA1'], genome: 3),
      );

      await tester.tap(find.text('Create BED file'));
      expect(calls.pressed, ['bed']);
    });

    testWidgets('a BED file turns the step into a statement', (tester) async {
      await pumpPanel(
        tester,
        projectFixture(genes: ['BRCA1'], genome: 3, bedFileCreated: true),
      );

      expect(find.text('BED file ready'), findsOneWidget);
      expect(find.text('Create BED file'), findsNothing);
      expect(find.text('Generate MIPs'), findsOneWidget);
    });
  });

  group('the run switches', () {
    Project ready({int? owner, bool emailNotification = false}) =>
        projectFixture(
          genes: ['BRCA1'],
          genome: 3,
          bedFileCreated: true,
          owner: owner,
          emailNotification: emailNotification,
        );

    testWidgets('the disk-space switch reports the new value', (tester) async {
      final calls = await pumpPanel(tester, ready());

      await tester.tap(find.text('Delete intermediate files'));
      expect(calls.deleteExcess, isFalse);
    });

    testWidgets('no mail switch when the install has mail off', (tester) async {
      await pumpPanel(tester, ready(owner: 7));
      expect(find.text('Email me when it finishes'), findsNothing);
    });

    testWidgets('an unowned project is told why it cannot be notified', (
      tester,
    ) async {
      // ⚠️ Shown disabled rather than hidden: the setting is real, this install
      // just cannot act on it. The server resolves the address from the owner,
      // and nothing sets an owner while single sign-on is off.
      await pumpPanel(tester, ready(), notificationsAvailable: true);

      expect(find.text('This project has no owner to notify.'), findsOneWidget);
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Email me when it finishes'),
      );
      expect(tile.onChanged, isNull);
      expect(tile.value, isFalse);
    });

    testWidgets('an owned project can switch mail on', (tester) async {
      final calls = await pumpPanel(
        tester,
        ready(owner: 7),
        notificationsAvailable: true,
      );

      await tester.tap(find.text('Email me when it finishes'));
      expect(calls.notify, isTrue);
    });
  });

  group('while a design is running', () {
    Project running() => projectFixture(
      genes: ['BRCA1'],
      genome: 3,
      bedFileCreated: true,
      active: true,
      started: DateTime.utc(2026, 1, 1),
    );

    testWidgets('the live panel replaces the start controls', (tester) async {
      // ⚠️ `pump`, never `pumpAndSettle`: the panel holds an indeterminate
      // spinner, so nothing ever settles.
      await pumpPanel(
        tester,
        running(),
        progress: const MipgenProgress(lines: ['designing MIPs for BRCA1']),
      );

      expect(find.text('Designing MIPs'), findsOneWidget);
      expect(find.text('designing MIPs for BRCA1'), findsOneWidget);
      expect(find.text('Generate MIPs'), findsNothing);
      expect(find.text('Create BED file'), findsNothing);
    });
  });

  group('a finished run', () {
    Project done({String warning = '', String error = ''}) => projectFixture(
      genes: ['BRCA1'],
      genome: 3,
      bedFileCreated: true,
      completedIn: const Duration(hours: 1, minutes: 2, seconds: 3),
      size: 2_400_000_000,
      warning: warning,
      error: error,
    );

    testWidgets('says how long it took and how big the output is', (
      tester,
    ) async {
      await pumpPanel(tester, done());

      expect(find.text('Design complete'), findsOneWidget);
      expect(find.text('01:02:03'), findsOneWidget);
      expect(find.text('2.40 GB'), findsOneWidget);
    });

    testWidgets('offers every way of reading the results', (tester) async {
      final calls = await pumpPanel(tester, done());

      await tester.tap(find.text('MIPs result'));
      await tester.tap(find.text('SNP MIPs result'));
      await tester.tap(find.text('UCSC'));
      await tester.tap(find.text('Download'));
      expect(calls.pressed, ['mips', 'snp-mips', 'ucsc', 'downloads']);
    });

    testWidgets('the track file and the log are behind the overflow', (
      tester,
    ) async {
      final calls = await pumpPanel(tester, done());

      expect(find.text('View track file'), findsNothing);
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View design log'));
      // ⚠️ A pump is required before asserting. Unlike an ordinary button, a
      // `MenuItemButton` dismisses the menu first and runs its callback after
      // the frame — so checking straight after the tap sees nothing and reads
      // as a dead menu item.
      await tester.pumpAndSettle();
      expect(calls.pressed, ['log']);
    });

    testWidgets('⚠️ a warning is amber, and the run still reads as complete', (
      tester,
    ) async {
      // The distinction this panel exists to make. The MIPs are there and
      // downloadable; dressing a missing UCSC track as a failure sends people
      // looking for results they already have.
      await pumpPanel(tester, done(warning: 'No UCSC track could be built.'));

      expect(find.text('Design complete'), findsOneWidget);
      expect(find.text('No UCSC track could be built.'), findsOneWidget);
      expect(find.textContaining('The design failed'), findsNothing);
      expect(find.text('MIPs result'), findsOneWidget);
    });

    testWidgets('a failure offers no results at all', (tester) async {
      await pumpPanel(tester, done(error: 'mipgen exited with 1'));

      expect(find.textContaining('The design failed'), findsOneWidget);
      expect(find.text('Design complete'), findsNothing);
      expect(find.text('MIPs result'), findsNothing);
      expect(find.text('Download'), findsNothing);
    });
  });
}
