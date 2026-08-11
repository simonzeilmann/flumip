import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/snp_section.dart';
import 'package:flumip_flutter/snp/snp_tile.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snp_section_controller_test.dart' show Harness, snpFixture;

/// The SNP list, pumped whole.
///
/// ⚠️ The genome fixture only supplies the id the section shows in its heading
/// and hands to the add dialog; everything on screen comes from the controller.
Genome genomeFixture() => Genome(
  id: 3,
  name: 'hg38',
  description: '',
  category: 'Homo sapiens',
  path: '/opt/flumip/data/genomes/human/hg38',
  size: 3_100_000_000,
  indexed: true,
  indexing: false,
  active: true,
);

Future<Harness> pumpSection(WidgetTester tester, Harness harness) async {
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SnpSection(
          genome: genomeFixture(),
          controller: harness.controller,
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('a spinner until the sets arrive', (tester) async {
    final h = Harness();
    await pumpSection(tester, h);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(SnpTile), findsOneWidget);
    h.dispose();
  });

  testWidgets('the count is part of the heading', (tester) async {
    // It used to be a bare numeral floating to the right of the title, which
    // reads as nothing at all.
    final h = Harness(snps: [snpFixture(id: 1), snpFixture(id: 2)]);
    await pumpSection(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('SNP sets (2)'), findsOneWidget);
    h.dispose();
  });

  testWidgets('an empty genome says so, centred', (tester) async {
    final h = Harness(snps: const []);
    await pumpSection(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('No SNP sets for this genome yet.'), findsOneWidget);
    expect(find.byType(SnpTile), findsNothing);
    h.dispose();
  });

  testWidgets('a load failure explains itself and can be dismissed', (
    tester,
  ) async {
    final h = Harness()..loadThrows = Exception('no route to host');
    await pumpSection(tester, h);
    // ⚠️ Bounded pumps throughout this test, never `pumpAndSettle`. A failed
    // load leaves the list null, so the indeterminate spinner stays on screen
    // beside the banner — and nothing settles while one is drawn.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Could not load SNP sets'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Could not load SNP sets'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    h.dispose();
  });

  testWidgets('a row action reaches the controller', (tester) async {
    final h = Harness(snps: [snpFixture(private: true)], mine: [snpFixture()]);
    await pumpSection(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.byType(PopupMenuButton<SnpAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share with everyone'));
    await tester.pumpAndSettle();

    expect(h.calls.first, 'shared 1=true');
    h.dispose();
  });

  testWidgets('a message from the controller becomes a snack bar', (
    tester,
  ) async {
    final h = Harness(snps: [snpFixture()], mine: [snpFixture()]);
    await pumpSection(tester, h);
    await tester.pumpAndSettle();

    await h.controller.delete(h.controller.snps!.single);
    await tester.pump();

    expect(find.text('Deleted "panel" and its files.'), findsOneWidget);
    h.dispose();
  });

  testWidgets('⚠️ a controller passed in is not disposed by the section', (
    tester,
  ) async {
    final h = Harness();
    await pumpSection(tester, h);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await expectLater(h.controller.load(), completes);
    h.dispose();
  });

  testWidgets('changing genome re-asks for that genome\'s sets', (
    tester,
  ) async {
    final h = Harness();
    await pumpSection(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SnpSection(
            genome: Genome(
              id: 9,
              name: 'hs1',
              description: '',
              category: 'Homo sapiens',
              path: '/opt/flumip/data/genomes/human/hs1',
              size: 3_100_000_000,
              indexed: true,
              indexing: false,
              active: true,
            ),
            controller: h.controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(h.calls, contains('snps 9'));
    h.dispose();
  });
}
