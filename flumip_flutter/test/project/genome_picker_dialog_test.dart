import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/genome_picker_dialog.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Genome g({
  int id = 1,
  String name = 'hg38',
  bool indexed = true,
  bool indexing = false,
  bool active = true,
  int size = 3100000000,
  String category = 'human',
}) =>
    Genome(
      id: id,
      name: name,
      description: '',
      category: category,
      path: '/opt/flumip/data/genomes/human/$name',
      size: size,
      indexed: indexed,
      indexing: indexing,
      active: active,
    );

/// Returns the genome the dialog was closed with, or null.
Future<Genome?> pumpPicker(
  WidgetTester tester, {
  List<String> categories = const ['human'],
  Map<String, List<Genome>> genomes = const {},
  String? initialCategory,
  int? selectedGenomeId,
  Future<List<Genome>> Function(String)? loadGenomes,
}) async {
  Genome? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<Genome>(
                context: context,
                builder: (_) => GenomePickerDialog(
                  categories: categories,
                  loadGenomes: loadGenomes ??
                      (c) async => genomes[c] ?? const <Genome>[],
                  initialCategory: initialCategory,
                  selectedGenomeId: selectedGenomeId,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('a single category opens itself', (tester) async {
    // Nothing to choose between, so making the user tap it first is a step for
    // its own sake.
    await pumpPicker(
      tester,
      categories: const ['human'],
      genomes: {
        'human': [g(name: 'hg38')],
      },
    );
    expect(find.text('hg38'), findsOneWidget);
  });

  testWidgets('with several categories, none opens until asked',
      (tester) async {
    await pumpPicker(
      tester,
      categories: const ['human', 'mouse'],
      genomes: {
        'human': [g(name: 'hg38')],
      },
    );
    expect(find.text('hg38'), findsNothing);

    await tester.tap(find.text('human'));
    await tester.pumpAndSettle();
    expect(find.text('hg38'), findsOneWidget);
  });

  testWidgets('opens where the project already is', (tester) async {
    await pumpPicker(
      tester,
      categories: const ['human', 'mouse'],
      initialCategory: 'mouse',
      genomes: {
        'mouse': [g(id: 9, name: 'mm39', category: 'mouse')],
      },
    );
    expect(find.text('mm39'), findsOneWidget);
  });

  testWidgets('picking a genome returns it and closes', (tester) async {
    Genome? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                picked = await showDialog<Genome>(
                  context: context,
                  builder: (_) => GenomePickerDialog(
                    categories: const ['human'],
                    loadGenomes: (_) async => [g(id: 7, name: 'hg38')],
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('hg38'));
    await tester.pumpAndSettle();

    expect(picked?.id, 7);
    expect(find.text('Choose a genome'), findsNothing);
  });

  testWidgets('a genome being indexed is disabled and says why',
      (tester) async {
    // ⚠️ The old dialog made this look broken: the row was tappable and tapping
    // it just closed the dialog with nothing changed.
    await pumpPicker(
      tester,
      genomes: {
        'human': [g(name: 'hg38', indexed: false, indexing: true)],
      },
    );

    expect(find.textContaining('not usable yet'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('hg38'), matching: find.byType(ListTile)),
    );
    expect(tile.enabled, isFalse);
    expect(tile.onTap, isNull);
  });

  testWidgets('an unindexed genome can still be chosen', (tester) async {
    // It gets indexed on first use, so refusing it would be wrong.
    await pumpPicker(
      tester,
      genomes: {
        'human': [g(name: 'hg38', indexed: false, indexing: false)],
      },
    );

    expect(find.text('Not indexed'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('hg38'), matching: find.byType(ListTile)),
    );
    expect(tile.enabled, isTrue);
  });

  testWidgets('an inactive genome is not offered at all', (tester) async {
    await pumpPicker(
      tester,
      genomes: {
        'human': [g(name: 'hidden', active: false), g(id: 2, name: 'hg38')],
      },
    );
    expect(find.text('hidden'), findsNothing);
    expect(find.text('hg38'), findsOneWidget);
  });

  testWidgets('the current genome is marked as selected', (tester) async {
    await pumpPicker(
      tester,
      selectedGenomeId: 3,
      genomes: {
        'human': [g(id: 3, name: 'hg38'), g(id: 4, name: 'hg19')],
      },
    );

    ListTile tileFor(String name) => tester.widget<ListTile>(
          find.ancestor(of: find.text(name), matching: find.byType(ListTile)),
        );
    expect(tileFor('hg38').selected, isTrue);
    expect(tileFor('hg19').selected, isFalse);
  });

  testWidgets('an empty category says so rather than showing nothing',
      (tester) async {
    await pumpPicker(tester, genomes: const {'human': []});
    expect(find.text('No genomes in this category.'), findsOneWidget);
  });

  testWidgets('an install with no genomes points at the genomes tab',
      (tester) async {
    await pumpPicker(tester, categories: const []);
    expect(find.textContaining('Genomes & SNP tab'), findsOneWidget);
  });

  testWidgets('a failed load is reported, not swallowed', (tester) async {
    await pumpPicker(
      tester,
      loadGenomes: (_) async => throw Exception('server said no'),
    );
    expect(find.textContaining('server said no'), findsOneWidget);
  });

  testWidgets('cancelling returns nothing', (tester) async {
    final picked = await pumpPicker(
      tester,
      genomes: {
        'human': [g()],
      },
    );
    expect(picked, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a genome'), findsNothing);
  });

  testWidgets('the size is human-readable', (tester) async {
    await pumpPicker(
      tester,
      genomes: {
        'human': [g(size: 150000000)],
      },
    );
    expect(find.textContaining('150 MB'), findsOneWidget);
  });
}
