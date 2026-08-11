import 'package:flumip_flutter/project/project_options_view.dart';
import 'package:flumip_flutter/project/project_run_panel.dart';
import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'project_run_panel_test.dart' show projectFixture;
import 'project_tile_controller_test.dart' show Harness, snpFixture;

/// ⚠️ **An expanded project tile, pumped whole** — which nothing could do until
/// the tile stopped reaching for `client` from inside its `State`. It is the
/// widest surface in the app: three columns, a poll, and every action a project
/// has.
Future<Harness> pumpTile(WidgetTester tester, Harness harness) async {
  tester.view.physicalSize = const Size(1400, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProjectTile(
            project: harness.project,
            onDelete: () => harness.calls.add('delete'),
            controller: harness.controller,
          ),
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('a collapsed row says what the project is doing', (tester) async {
    final h = Harness();
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('panel'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byType(ProjectOptionsView), findsNothing);
    h.controller.dispose();
  });

  testWidgets('opening it shows all three columns', (tester) async {
    final h = Harness(
      project: projectFixture(genes: ['BRCA1'], genome: 3, snp: 9),
    );
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectOptionsView), findsOneWidget);
    expect(find.byType(ProjectRunPanel), findsOneWidget);
    expect(find.text('Genome'), findsOneWidget);
    expect(find.text('SNP set'), findsOneWidget);
    expect(find.text('Genes'), findsOneWidget);
    h.controller.dispose();
  });

  testWidgets('the genome and SNP set arrive and are shown', (tester) async {
    final h = Harness(
      project: projectFixture(genes: ['BRCA1'], genome: 3, snp: 9),
      expanded: true,
    )..snps = [snpFixture()];
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('hg38'), findsOneWidget);
    expect(find.text('dbSNP common'), findsWidgets);
    h.controller.dispose();
  });

  testWidgets('a gene can be added from the field', (tester) async {
    final h = Harness(project: projectFixture(genome: 3), expanded: true);
    await pumpTile(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.enterText(
      find.widgetWithText(TextField, 'Add a gene'),
      'TP53',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(h.calls.first, 'addGene TP53');
    h.controller.dispose();
  });

  testWidgets('the BED step is offered once there is something to build from', (
    tester,
  ) async {
    final h = Harness(
      project: projectFixture(genes: ['BRCA1'], genome: 3),
      expanded: true,
    );
    await pumpTile(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.text('Create BED file'));
    await tester.pumpAndSettle();

    expect(h.calls.first, 'createBed 1');
    h.controller.dispose();
  });

  testWidgets('a running design shows the live panel, not the start controls', (
    tester,
  ) async {
    final h = Harness(
      project: projectFixture(
        genes: ['BRCA1'],
        genome: 3,
        bedFileCreated: true,
        active: true,
        started: DateTime.utc(2026),
      ),
      expanded: true,
    );
    await pumpTile(tester, h);
    // ⚠️ `pump`, never `pumpAndSettle`: the live panel holds an indeterminate
    // spinner, so nothing ever settles while a design is going.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Designing MIPs'), findsOneWidget);
    expect(find.text('designing MIPs for BRCA1'), findsOneWidget);
    expect(find.text('Generate MIPs'), findsNothing);
    h.controller.dispose();
  });

  testWidgets('a message from the controller becomes a snack bar', (
    tester,
  ) async {
    final h = Harness(expanded: true);
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    await h.controller.createBedFile();
    await tester.pump();

    expect(find.text('BED file created successfully'), findsOneWidget);
    h.controller.dispose();
  });

  testWidgets('deleting asks first, and only then calls back', (tester) async {
    final h = Harness();
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.calls, isNot(contains('delete')));

    await tester.tap(find.byTooltip('Delete project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(h.calls, contains('delete'));
    h.controller.dispose();
  });

  testWidgets('⚠️ a failed reload explains itself in the inputs column', (
    tester,
  ) async {
    // Beside the thing it explains, rather than at the bottom of the tile.
    final h = Harness(expanded: true)..loadThrows = Exception('no route');
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to reload project'), findsOneWidget);
    h.controller.dispose();
  });

  testWidgets('⚠️ a controller passed in is not disposed by the tile', (
    tester,
  ) async {
    final h = Harness();
    await pumpTile(tester, h);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await expectLater(h.controller.refresh(), completes);
    h.controller.dispose();
  });
}
