import 'package:flumip_flutter/genome/genome_detail_pane.dart';
import 'package:flumip_flutter/genome/genome_rail.dart';
import 'package:flumip_flutter/genome/genome_tab.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'genome_controller_test.dart' show Harness, genomeFixture;

/// The genome tab, pumped whole.
///
/// ⚠️ Only the rail is exercised here. Selecting a genome builds
/// `GenomeDetailPane`, which builds `SnpSection` — and that one still reads the
/// app-wide `client` in its own `initState`, so a test that selected a genome
/// would reach for the network. That is the next conversion, and until it lands
/// the split is: the rail here, the detail pane in `genome_detail_pane_test`,
/// and everything the tab *does* in `genome_controller_test`.
Future<Harness> pumpTab(
  WidgetTester tester,
  Harness harness, {
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: GenomeTab(controller: harness.controller)),
    ),
  );
  return harness;
}

void main() {
  testWidgets('the rail lists the categories', (tester) async {
    final h = Harness(categories: ['Homo sapiens', 'Mus musculus']);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.byType(GenomeRail), findsOneWidget);
    expect(find.text('Homo sapiens'), findsOneWidget);
    expect(find.text('Mus musculus'), findsOneWidget);
  });

  testWidgets('nothing selected asks you to pick one', (tester) async {
    await pumpTab(tester, Harness());
    await tester.pumpAndSettle();

    expect(find.text('Select a genome.'), findsOneWidget);
    expect(find.byType(GenomeDetailPane), findsNothing);
  });

  testWidgets('opening a category lists its genomes', (tester) async {
    final h = Harness(
      genomes: [
        genomeFixture(name: 'hg38'),
        genomeFixture(id: 2, name: 'hs1'),
      ],
    );
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Homo sapiens'));
    await tester.pumpAndSettle();

    expect(find.text('hg38'), findsOneWidget);
    expect(find.text('hs1'), findsOneWidget);
  });

  testWidgets('a rail failure explains the empty list', (tester) async {
    final h = Harness()..categoriesThrows = Exception('no route to host');
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.textContaining('no route to host'), findsOneWidget);
  });

  testWidgets('the library menu reaches the controller', (tester) async {
    final h = Harness();
    await pumpTab(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan for new genomes'));
    await tester.pumpAndSettle();

    expect(h.calls, contains('scan'));
  });

  testWidgets('a message from the controller becomes a snack bar', (
    tester,
  ) async {
    final h = Harness();
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await h.controller.scanForGenomes();
    await tester.pump();

    expect(find.text('Scanned for new genomes.'), findsOneWidget);
  });

  testWidgets('⚠️ a controller passed in is not disposed by the tab', (
    tester,
  ) async {
    // The tab disposes the one it built for itself, and only that one — a test
    // owns what it handed over.
    final h = Harness();
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await expectLater(h.controller.refreshCategories(), completes);
  });

  testWidgets('a narrow window shows one pane', (tester) async {
    // Below kSplitWidth the rail takes the whole width and the detail replaces
    // it, rather than the two sharing a row.
    final h = Harness();
    await pumpTab(tester, h, size: const Size(700, 900));
    await tester.pumpAndSettle();

    expect(find.byType(GenomeRail), findsOneWidget);
    expect(find.text('Select a genome.'), findsNothing);
  });
}
