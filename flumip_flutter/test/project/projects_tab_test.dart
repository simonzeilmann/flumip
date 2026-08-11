import 'package:flumip_flutter/project/project_tile.dart';
import 'package:flumip_flutter/project/projects_tab.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'projects_controller_test.dart' show Harness, projectFixture;

/// ⚠️ **The first test in this app to pump a whole tab.**
///
/// Two things had to be true before this file could exist. The tab had to stop
/// importing `main.dart`, which pulls in `dart:js_interop` and cannot be compiled
/// for the VM at all; and its fetching had to move somewhere a fake could be
/// substituted, because the generated Serverpod `Client` assigns its endpoints to
/// `late final` fields and so cannot be subclassed.
///
/// ⚠️ Every tile is left collapsed on purpose. `ProjectTile` reads the app-wide
/// `client` when it is expanded, and this test has no server — so expanding one
/// would reach for the network. Covering the expanded tile is what
/// `project_run_panel_test` and `project_inputs_test` do, against the pieces it
/// is built from.
Future<Harness> pumpTab(WidgetTester tester, Harness harness) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: ProjectsTab(controller: harness.controller)),
    ),
  );
  return harness;
}

void main() {
  testWidgets('a spinner until the list arrives', (tester) async {
    final h = Harness(projects: [projectFixture(id: 1)]);
    await pumpTab(tester, h);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ProjectTile), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ProjectTile), findsOneWidget);
  });

  testWidgets('one tile per project, newest first', (tester) async {
    final h = Harness(
      projects: [
        projectFixture(id: 1, created: DateTime(2026, 1, 1)),
        projectFixture(id: 2, created: DateTime(2026, 2, 1)),
      ],
    );
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.byType(ProjectTile), findsNWidgets(2));
    final first = tester.widget<ProjectTile>(find.byType(ProjectTile).first);
    expect(first.project.id, 2, reason: 'newest at the top');
  });

  testWidgets('an empty install still offers the create button', (
    tester,
  ) async {
    await pumpTab(tester, Harness());
    await tester.pumpAndSettle();

    expect(find.byType(ProjectTile), findsNothing);
    expect(find.text('Create project'), findsOneWidget);
  });

  testWidgets('⚠️ a failed first load explains itself, and cannot be dismissed', (
    tester,
  ) async {
    // It is the only thing on the screen. Dismissing it left the tab showing a
    // spinner that never stops — `loading` is "no projects and no error" — with
    // nothing left saying why. Caught by this test hanging on `pumpAndSettle`.
    final h = Harness()..loadThrows = Exception('no route to host');
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.textContaining('no route to host'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byTooltip('Dismiss'), findsNothing);
  });

  testWidgets('an error over a loaded list can be dismissed', (tester) async {
    // A failed delete, say: the list is still there to go back to.
    final h = Harness(projects: [projectFixture(id: 1)])
      ..deleteThrows = Exception('not yours');
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not yours'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not yours'), findsNothing);
    expect(find.byType(ProjectTile), findsOneWidget, reason: 'row restored');
  });

  testWidgets('⚠️ deleting takes the row off at once', (tester) async {
    // The whole point of the optimistic delete: the server removes a possibly
    // multi-gigabyte directory before it answers.
    final h = Harness(projects: [projectFixture(id: 1), projectFixture(id: 2)]);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();
    expect(find.byType(ProjectTile), findsNWidgets(2));

    await tester.tap(find.byTooltip('Delete project').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(find.byType(ProjectTile), findsOneWidget);
  });

  testWidgets('deleting can be called off', (tester) async {
    final h = Harness(projects: [projectFixture(id: 1)]);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete project'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectTile), findsOneWidget);
    expect(h.calls, isNot(contains('delete 1')));
  });

  testWidgets('the create form replaces the list', (tester) async {
    final h = Harness(projects: [projectFixture(id: 1)]);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create project'));
    await tester.pump();

    expect(find.byType(ProjectTile), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('⚠️ the tab does not dispose a controller it was handed', (
    tester,
  ) async {
    // The app-wide one outlives the tab — TabBarView can rebuild it — and a test
    // owns the one it passed in. Disposing it here would break both.
    final h = Harness(projects: [projectFixture(id: 1)]);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await expectLater(h.controller.refresh(), completes);
  });
}
