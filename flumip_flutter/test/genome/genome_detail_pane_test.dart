import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/genome/genome_detail_pane.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testable because the pane takes its data as parameters and its SNP list as an
/// injected widget — the same constraint that made the admin delete dialog
/// testable. Everything else in this tab reaches the top-level `client`.
Genome genomeFixture({
  String name = 'hg38',
  bool indexed = false,
  bool indexing = false,
  bool active = true,
  int size = 3_100_000_000,
  String description = '',
  String? category = 'Homo sapiens',
}) => Genome(
  id: 12,
  name: name,
  description: description,
  category: category,
  path: '/opt/flumip/data/genomes/human/hg38',
  size: size,
  indexed: indexed,
  indexing: indexing,
  active: active,
);

Future<void> pumpPane(
  WidgetTester tester,
  Genome genome, {
  double width = 1000,
  void Function(bool)? onToggleActive,
  VoidCallback? onIndex,
  VoidCallback? onDeleteIndex,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: GenomeDetailPane(
          genome: genome,
          snpSection: const SizedBox(key: Key('snp-section')),
          onDeleteIndex: onDeleteIndex ?? () {},
          onIndexGenome: onIndex ?? () {},
          onToggleGenomeActive: onToggleActive ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('the index state is a sentence, not a boolean', () {
    testWidgets('not indexed', (tester) async {
      await pumpPane(tester, genomeFixture());
      expect(find.text('Not indexed'), findsOneWidget);
    });

    testWidgets('indexed', (tester) async {
      await pumpPane(tester, genomeFixture(indexed: true));
      expect(find.text('Indexed'), findsOneWidget);
    });

    testWidgets('indexing', (tester) async {
      await pumpPane(tester, genomeFixture(indexing: true));
      expect(find.text('Indexing…'), findsOneWidget);
    });

    testWidgets('never the word true, in any state', (tester) async {
      // ⚠️ The regression guard. This pane used to interpolate the raw flags —
      // `'Indexing: ${genome.indexing}...'` and `'Indexed: ${genome.indexed}'` —
      // so the interface said "Indexing: true..." and "Indexed: false" to
      // biologists.
      for (final genome in [
        genomeFixture(),
        genomeFixture(indexed: true),
        genomeFixture(indexing: true),
        genomeFixture(indexed: true, indexing: true),
      ]) {
        await pumpPane(tester, genome);
        expect(find.textContaining('true'), findsNothing);
        expect(find.textContaining('false'), findsNothing);
      }
    });
  });

  group('the action offered matches the state', () {
    testWidgets('an unindexed genome can be indexed', (tester) async {
      await pumpPane(tester, genomeFixture());
      expect(find.text('Build index'), findsOneWidget);
      expect(find.text('Delete index'), findsNothing);
    });

    testWidgets('an indexed genome can have its index removed', (tester) async {
      await pumpPane(tester, genomeFixture(indexed: true));
      expect(find.text('Delete index'), findsOneWidget);
      expect(find.text('Build index'), findsNothing);
    });

    testWidgets('neither is offered while the index is building', (
      tester,
    ) async {
      await pumpPane(tester, genomeFixture(indexing: true));
      expect(find.text('Build index'), findsNothing);
      expect(find.text('Delete index'), findsNothing);
    });

    testWidgets('indexing wins even when indexed is also set', (tester) async {
      // The server sets both while rebuilding an existing index.
      await pumpPane(tester, genomeFixture(indexed: true, indexing: true));
      expect(find.text('Indexing…'), findsOneWidget);
    });
  });

  testWidgets('a very long name does not overflow', (tester) async {
    // ⚠️ The title used to be a bare Text in a Row with no flex, in a pane that
    // was a third of the window wide.
    await pumpPane(tester, genomeFixture(name: 'x' * 200), width: 400);

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text('x' * 200));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
  });

  testWidgets('the size is human-readable, not gigabytes-only', (tester) async {
    // A 150 MB genome used to render as "0.15 GB" — and the size was not shown
    // in this pane at all, only in the list.
    await pumpPane(tester, genomeFixture(size: 150_000_000));
    expect(find.textContaining('150 MB'), findsOneWidget);
  });

  testWidgets('category, size and id share one subdued line', (tester) async {
    await pumpPane(tester, genomeFixture());
    expect(
      find.textContaining('Homo sapiens · 3.10 GB · ID 12'),
      findsOneWidget,
    );
  });

  testWidgets('a genome with no category still reads properly', (tester) async {
    await pumpPane(tester, genomeFixture(category: null));
    expect(find.textContaining('3.10 GB · ID 12'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('the active switch reports the new value', (tester) async {
    bool? reported;
    await pumpPane(
      tester,
      genomeFixture(active: true),
      onToggleActive: (v) => reported = v,
    );

    await tester.tap(find.byType(Switch));
    expect(reported, isFalse);
  });

  testWidgets('the SNP list is handed through untouched', (tester) async {
    await pumpPane(tester, genomeFixture());
    expect(find.byKey(const Key('snp-section')), findsOneWidget);
  });

  testWidgets('there is no back button on a wide window', (tester) async {
    await pumpPane(tester, genomeFixture());
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
