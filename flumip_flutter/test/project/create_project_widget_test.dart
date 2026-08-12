import 'package:flumip_flutter/project/create_project_widget.dart';
import 'package:flumip_flutter/project/project_options_fields.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'new_project_controller_test.dart' show Harness;

Future<Harness> pumpForm(
  WidgetTester tester,
  Harness harness, {
  void Function()? onAbort,
  void Function(dynamic project)? onCreated,
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: CreateProjectWidget(
          controller: harness.controller,
          onProjectCreated: (p) => onCreated?.call(p),
          onAbort: onAbort ?? () {},
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

  testWidgets('creating hands the project back', (tester) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    Object? created;
    await pumpForm(tester, h, onCreated: (p) => created = p);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'panel A');
    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(created, isNotNull);
    expect(h.calls, contains('insertOptions'));
  });

  testWidgets('⚠️ a nameless project says so and calls nothing back', (
    tester,
  ) async {
    final h = Harness();
    addTearDown(h.controller.dispose);
    Object? created;
    await pumpForm(tester, h, onCreated: (p) => created = p);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.text('Create project'));
    await tester.pumpAndSettle();

    expect(created, isNull);
    expect(h.calls, isEmpty);
    expect(find.text('Project name is required'), findsOneWidget);
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
    expect(h.calls, isNot(contains('insertOptions')));
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
