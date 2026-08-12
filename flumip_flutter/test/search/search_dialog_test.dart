import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/search/search_dialog.dart';
import 'package:flumip_flutter/ui/error_banner.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'search_controller_test.dart' show Harness, hitFixture;

/// The dialog, pumped whole against a controller wired to fakes.
///
/// Pumped as a page rather than through `showDialog`, except where the test is
/// about dismissal: an `AlertDialog` renders the same either way, and a route
/// makes `Navigator.pop` assertions harder to reach than they need to be.
Future<List<SearchHitDto>> pumpDialog(
  WidgetTester tester,
  Harness harness, {
  Size size = const Size(1000, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final opened = <SearchHitDto>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: SearchDialog(controller: harness.controller, onOpen: opened.add),
    ),
  );
  return opened;
}

/// Types into the search field and lets the debounce and the answer land.
Future<void> type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('it asks for two characters before it says anything', (
    tester,
  ) async {
    final h = Harness();
    await pumpDialog(tester, h);

    expect(find.textContaining('Type at least 2'), findsOneWidget);

    await type(tester, 'b');

    // Still the hint, not an empty-result message about a question nobody asked.
    expect(find.textContaining('Type at least 2'), findsOneWidget);
    expect(h.queries, isEmpty);
  });

  testWidgets('hits are grouped under a heading per kind', (tester) async {
    final h = Harness(
      hits: [
        hitFixture(kind: SearchHitKind.project, id: 1, name: 'BRCA panel'),
        hitFixture(kind: SearchHitKind.genome, id: 2, name: 'hg38'),
        hitFixture(kind: SearchHitKind.snpSet, id: 3, name: 'ClinVar'),
      ],
    );
    await pumpDialog(tester, h);

    await type(tester, 'brca');

    expect(find.text('PROJECTS'), findsOneWidget);
    expect(find.text('GENOMES'), findsOneWidget);
    expect(find.text('SNP SETS'), findsOneWidget);
    expect(find.text('BRCA panel'), findsOneWidget);
    expect(find.text('hg38'), findsOneWidget);
    expect(find.text('ClinVar'), findsOneWidget);
  });

  testWidgets('a heading with no hits is left out entirely', (tester) async {
    final h = Harness(
      hits: [hitFixture(kind: SearchHitKind.genome, name: 'hg38')],
    );
    await pumpDialog(tester, h);

    await type(tester, 'hg');

    expect(find.text('GENOMES'), findsOneWidget);
    expect(find.text('PROJECTS'), findsNothing);
    expect(find.text('SNP SETS'), findsNothing);
  });

  testWidgets('a row falls back to its context when it has no description', (
    tester,
  ) async {
    final h = Harness(
      hits: [
        hitFixture(
          kind: SearchHitKind.snpSet,
          name: 'ClinVar',
          subtitle: '',
          context: 'hg38',
        ),
        hitFixture(
          kind: SearchHitKind.project,
          id: 2,
          name: 'panel',
          subtitle: 'cardiomyopathy',
          context: '',
        ),
      ],
    );
    await pumpDialog(tester, h);

    await type(tester, 'anything');

    expect(find.text('hg38'), findsOneWidget);
    expect(find.text('cardiomyopathy'), findsOneWidget);
  });

  testWidgets('tapping a row hands the hit over', (tester) async {
    final h = Harness(hits: [hitFixture(id: 42, name: 'BRCA panel')]);
    final opened = await pumpDialog(tester, h);

    await type(tester, 'brca');
    await tester.tap(find.text('BRCA panel'));
    await tester.pumpAndSettle();

    expect(opened.map((h) => h.id), [42]);
  });

  testWidgets('submitting opens the first hit', (tester) async {
    final h = Harness(
      hits: [
        hitFixture(id: 1, name: 'first'),
        hitFixture(id: 2, name: 'second'),
      ],
    );
    final opened = await pumpDialog(tester, h);

    await type(tester, 'brca');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(opened.map((h) => h.id), [1]);
  });

  testWidgets('submitting with nothing found opens nothing', (tester) async {
    final h = Harness(hits: const []);
    final opened = await pumpDialog(tester, h);

    await type(tester, 'brca');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
  });

  testWidgets('nothing matched says so, and quotes the query', (tester) async {
    final h = Harness(hits: const []);
    await pumpDialog(tester, h);

    await type(tester, 'zzzz');

    expect(find.textContaining('Nothing matched "zzzz"'), findsOneWidget);
  });

  testWidgets('a failure raises the error banner', (tester) async {
    final h = Harness()..searchThrows = Exception('server went away');
    await pumpDialog(tester, h);

    await type(tester, 'brca');

    expect(find.byType(ErrorBanner), findsOneWidget);
    expect(find.textContaining('server went away'), findsOneWidget);
  });

  testWidgets('⚠️ the previous results stay up while the next answer lands', (
    tester,
  ) async {
    // The single biggest contributor to search *feeling* fast: swapping the list
    // for a spinner on every keystroke makes a quick search look like a slow one.
    final h = Harness(hits: [hitFixture(name: 'BRCA panel')]);
    await pumpDialog(tester, h);

    await type(tester, 'brca');
    expect(find.text('BRCA panel'), findsOneWidget);

    h.gate = Completer<void>();
    h.hits = [hitFixture(name: 'BRCA panel 2')];
    await tester.enterText(find.byType(TextField), 'brca p');
    // Bounded pump, not pumpAndSettle: an indeterminate progress indicator is on
    // screen and nothing settles while one is drawn.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('BRCA panel'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    h.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('BRCA panel 2'), findsOneWidget);
    expect(find.text('BRCA panel'), findsNothing);
  });

  testWidgets('the clear button empties the field and the results', (
    tester,
  ) async {
    final h = Harness(hits: [hitFixture(name: 'BRCA panel')]);
    await pumpDialog(tester, h);

    await type(tester, 'brca');
    expect(find.text('BRCA panel'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('BRCA panel'), findsNothing);
    expect(find.textContaining('Type at least 2'), findsOneWidget);
  });

  testWidgets('choosing a hit dismisses the dialog', (tester) async {
    // Through a real route this time, because the dismissal is the thing under
    // test: `onOpen` switches tab, and a tab animating behind a barrier that is
    // still up looks like a dialog that has hung.
    final h = Harness(hits: [hitFixture(id: 7, name: 'BRCA panel')]);
    final opened = <SearchHitDto>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showSearchDialog(
                context,
                controller: h.controller,
                onOpen: opened.add,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await type(tester, 'brca');
    await tester.tap(find.text('BRCA panel'));
    await tester.pumpAndSettle();

    expect(opened.map((h) => h.id), [7]);
    expect(find.byType(SearchDialog), findsNothing);
  });
}
