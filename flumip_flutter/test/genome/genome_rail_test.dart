import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/genome/genome_rail.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Genome genomeFixture({int id = 1, String name = 'hg38', int size = 3100000000}) =>
    Genome(
      id: id,
      name: name,
      description: '',
      path: '/opt/flumip/data/genomes/human/$name',
      size: size,
      indexed: false,
      indexing: false,
      active: true,
    );

Future<void> pumpRail(
  WidgetTester tester, {
  List<String> categories = const ['Homo sapiens', 'Mus musculus'],
  List<Genome> genomes = const [],
  String? expandedCategory,
  int? selectedGenomeId,
  String? loadingCategory,
  String? error,
  void Function(String?)? onCategoryToggled,
  void Function(Genome)? onGenomeSelected,
  VoidCallback? onCollectGenomes,
  VoidCallback? onCollectCustomSnps,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: GenomeRail(
            categories: categories,
            genomes: genomes,
            expandedCategory: expandedCategory,
            selectedGenomeId: selectedGenomeId,
            loadingCategory: loadingCategory,
            error: error,
            onCategoryToggled: onCategoryToggled ?? (_) {},
            onGenomeSelected: onGenomeSelected ?? (_) {},
            onCollectGenomes: onCollectGenomes ?? () {},
            onCollectCustomSnps: onCollectCustomSnps ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('lists the categories', (tester) async {
    await pumpRail(tester);
    expect(find.text('Homo sapiens'), findsOneWidget);
    expect(find.text('Mus musculus'), findsOneWidget);
  });

  testWidgets('genomes appear only under the open category', (tester) async {
    await pumpRail(tester, genomes: [genomeFixture(name: 'hg38')]);
    expect(find.text('hg38'), findsNothing);

    await pumpRail(
      tester,
      expandedCategory: 'Homo sapiens',
      genomes: [genomeFixture(name: 'hg38')],
    );
    expect(find.text('hg38'), findsOneWidget);
  });

  testWidgets('tapping a closed category asks to open it', (tester) async {
    String? asked;
    var called = false;
    await pumpRail(tester, onCategoryToggled: (c) {
      asked = c;
      called = true;
    });

    await tester.tap(find.text('Homo sapiens'));
    expect(called, isTrue);
    expect(asked, 'Homo sapiens');
  });

  testWidgets('tapping the open category asks to close it', (tester) async {
    String? asked = 'unset';
    await pumpRail(
      tester,
      expandedCategory: 'Homo sapiens',
      onCategoryToggled: (c) => asked = c,
    );

    await tester.tap(find.text('Homo sapiens'));
    expect(asked, isNull);
  });

  testWidgets('tapping a genome selects it', (tester) async {
    Genome? picked;
    await pumpRail(
      tester,
      expandedCategory: 'Homo sapiens',
      genomes: [genomeFixture(id: 7, name: 'hg38')],
      onGenomeSelected: (g) => picked = g,
    );

    await tester.tap(find.text('hg38'));
    expect(picked?.id, 7);
  });

  testWidgets('the size is shown per genome, human-readable', (tester) async {
    await pumpRail(
      tester,
      expandedCategory: 'Homo sapiens',
      genomes: [genomeFixture(size: 150000000)],
    );
    expect(find.text('150 MB'), findsOneWidget);
  });

  testWidgets('an open but empty category says so', (tester) async {
    await pumpRail(tester, expandedCategory: 'Homo sapiens');
    expect(find.text('No genomes in this category.'), findsOneWidget);
  });

  testWidgets('a loading category shows progress, not an empty message',
      (tester) async {
    await pumpRail(
      tester,
      expandedCategory: 'Homo sapiens',
      loadingCategory: 'Homo sapiens',
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('No genomes in this category.'), findsNothing);
  });

  testWidgets('never renders the old broken header', (tester) async {
    // ⚠️ A permanent guard. The pane this replaced read `selectedGenome?.category`
    // where it meant `selectedCategory`, so it rendered "Genomes for :" whenever
    // a category was open but no genome had been picked yet.
    await pumpRail(tester, expandedCategory: 'Homo sapiens');
    expect(find.textContaining('Genomes for'), findsNothing);
  });

  testWidgets('an error explains the list it sits above', (tester) async {
    await pumpRail(tester, error: 'The server did not answer.');
    expect(find.text('The server did not answer.'), findsOneWidget);
  });

  group('the library menu', () {
    testWidgets('offers both maintenance actions', (tester) async {
      await pumpRail(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Scan for new genomes'), findsOneWidget);
      expect(find.text('Recheck custom SNP sets'), findsOneWidget);
    });

    testWidgets('scanning calls back', (tester) async {
      var scanned = false;
      await pumpRail(tester, onCollectGenomes: () => scanned = true);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan for new genomes'));
      await tester.pumpAndSettle();

      expect(scanned, isTrue);
    });

    testWidgets('rechecking SNP sets calls back', (tester) async {
      var rechecked = false;
      await pumpRail(tester, onCollectCustomSnps: () => rechecked = true);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recheck custom SNP sets'));
      await tester.pumpAndSettle();

      expect(rechecked, isTrue);
    });
  });

  testWidgets('an install with no genomes says what to do', (tester) async {
    await pumpRail(tester, categories: const []);
    expect(find.textContaining('Scan for new genomes'), findsOneWidget);
  });
}
