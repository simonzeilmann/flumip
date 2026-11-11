import 'dart:async';

import 'package:flumip_flutter/project/create_project_widget.dart';
import 'package:flumip_flutter/project/new_project_controller.dart';
import 'package:flumip_flutter/project/project_options_fields.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'new_project_controller_test.dart' show Harness;
import 'project_tile_controller_test.dart' show genomeFixture;

Future<Harness> pumpForm(
  WidgetTester tester,
  Harness harness, {
  void Function()? onAbort,
  void Function(NewProjectResult result)? onSaved,
  bool notificationsAvailable = false,
  bool willHaveOwner = false,
  Size size = const Size(1200, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: CreateProjectWidget(
          controller: harness.controller,
          onSaved: (result) => onSaved?.call(result),
          onAbort: onAbort ?? () {},
          notificationsAvailable: notificationsAvailable,
          willHaveOwner: willHaveOwner,
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('the two fields that are about the project', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('Project'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Description'), findsOneWidget);
  });

  testWidgets('⚠️ the design options start folded away', (tester) async {
    // The defaults come from the server and suit most panels; 28 fields on open
    // would bury the two that matter.
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    expect(find.byType(ProjectOptionsFields), findsNothing);

    await tester.tap(find.text('Show options'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectOptionsFields), findsOneWidget);
    expect(find.text('Capture and arms'), findsOneWidget);
  });

  testWidgets('the three inputs a design needs are on the form', (
    tester,
  ) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('Design target'), findsOneWidget);
    expect(find.text('None chosen'), findsOneWidget);
    expect(find.text('Choose a genome first.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Add a gene'), findsOneWidget);
  });

  testWidgets('a genome is chosen in the picker and shown', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('hg38'));
    await tester.pumpAndSettle();

    expect(h.controller.genome?.name, 'hg38');
    expect(find.text('Change'), findsOneWidget);
    // The SNP sets for it are on offer, with none chosen.
    expect(find.text('No SNP set'), findsOneWidget);
  });

  testWidgets('a gene typed into the form becomes a chip', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Add a gene'),
      'tp53',
    );
    await tester.tap(find.byTooltip('Add gene'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'TP53'), findsOneWidget);
    expect(h.calls, isNot(contains(startsWith('save'))), reason: 'not stored');
  });

  testWidgets('saving hands the project back as a draft', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    NewProjectResult? saved;
    await pumpForm(tester, h, onSaved: (result) => saved = result);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'panel A');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.started, isFalse);
    expect(h.calls, contains('save "panel A"'));
    expect(h.calls, isNot(contains('bed 1')));
  });

  testWidgets('⚠️ "Save and start" is dead until there is something to run', (
    tester,
  ) async {
    // A genome and a gene: what the BED file is built from. The button says
    // so itself, because a dead button with no reason reads as broken.
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    FilledButton start() => tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Save and start'),
        matching: find.bySubtype<FilledButton>(),
      ),
    );
    expect(start().onPressed, isNull);
    expect(
      find.byTooltip(NewProjectController.startRequirement),
      findsOneWidget,
    );

    h.controller.chooseGenome(genomeFixture());
    h.controller.addGene('BRCA1');
    await tester.pumpAndSettle();

    expect(start().onPressed, isNotNull);
    expect(find.byTooltip(NewProjectController.startRequirement), findsNothing);
  });

  testWidgets('"Save and start" stores the project and starts the run', (
    tester,
  ) async {
    final h = Harness()..fillForStart();
    addTearDown(h.controller.dispose);
    NewProjectResult? saved;
    await pumpForm(tester, h, onSaved: (result) => saved = result);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.text('Save and start'));
    // Not pumpAndSettle: the button keeps its spinner once the project exists
    // — the list replaces the form at that point — and a spinner never
    // settles.
    await tester.pump();
    await tester.pump();

    expect(h.calls, ['save "panel A"', 'bed 1', 'generate 1 delete=true']);
    expect(saved!.started, isTrue);
  });

  testWidgets('⚠️ every button is dead while a save is in flight', (
    tester,
  ) async {
    final h = Harness()..saveGate = Completer<void>();
    addTearDown(h.controller.dispose);
    var aborted = false;
    await pumpForm(tester, h, onAbort: () => aborted = true);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'panel A');
    h.calls.clear();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Saving…'), findsOneWidget);
    await tester.tap(find.text('Saving…'), warnIfMissed: false);
    await tester.tap(find.text('Cancel'), warnIfMissed: false);
    await tester.pump();
    expect(aborted, isFalse);
    expect(h.calls, ['save "panel A"']);

    h.saveGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('⚠️ a nameless project says so and calls nothing back', (
    tester,
  ) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    NewProjectResult? saved;
    await pumpForm(tester, h, onSaved: (result) => saved = result);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNull);
    expect(h.calls, isEmpty);
    expect(find.text('A project needs a name.'), findsOneWidget);
  });

  testWidgets('the email switch is offered only where mail can be sent', (
    tester,
  ) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('Delete intermediate files'), findsOneWidget);
    expect(find.text('Email me when it finishes'), findsNothing);
  });

  testWidgets('⚠️ the email switch is dead when nobody will own the project', (
    tester,
  ) async {
    // Shown and disabled, with the reason, like the tile's: the setting is
    // real, this install just has nobody to send the mail to.
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h, notificationsAvailable: true);
    await tester.pumpAndSettle();

    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Email me when it finishes'),
    );
    expect(tile.onChanged, isNull);
    expect(
      find.text('This project will have no owner to notify.'),
      findsOneWidget,
    );
  });

  testWidgets('the email switch is sent with the project', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(
      tester,
      h,
      notificationsAvailable: true,
      willHaveOwner: true,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'panel A');
    await tester.ensureVisible(find.text('Email me when it finishes'));
    await tester.tap(find.text('Email me when it finishes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(h.saved!.emailNotification, isTrue);
  });

  testWidgets('⚠️ the three actions fit a phone', (tester) async {
    // In a `Row` they overflowed at this width; the bar wraps instead.
    final h = Harness();
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h, size: const Size(320, 800));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save and start'), findsOneWidget);
  });

  testWidgets('cancelling calls back without creating anything', (
    tester,
  ) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    var aborted = false;
    await pumpForm(tester, h, onAbort: () => aborted = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(aborted, isTrue);
    expect(h.calls, isNot(contains(startsWith('save'))));
  });

  testWidgets('a failure to load the defaults still leaves a usable form', (
    tester,
  ) async {
    final h = Harness()..defaultsThrows = Exception('down');
    addTearDown(h.controller.dispose);
    await pumpForm(tester, h);
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load default'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
  });
}
