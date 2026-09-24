import 'dart:async';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/project/project_inputs.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The left-hand column of an expanded project tile.
Project projectFixture({
  int? genome,
  int? snp,
  List<String>? genes,
  bool bedFileCreated = false,
  bool active = false,
  Duration? completedIn,
}) => Project(
  id: 1,
  name: 'inputs',
  description: '',
  genes: genes,
  genome: genome,
  snp: snp,
  bedFileCreated: bedFileCreated,
  active: active,
  completedIn: completedIn,
  error: '',
  warning: '',
  size: 0,
  options: 1,
  created: DateTime(2026),
);

Genome genomeFixture({int id = 3, String name = 'hg38'}) => Genome(
  id: id,
  name: name,
  description: '',
  category: 'Homo sapiens',
  path: '/opt/flumip/data/genomes/human/hg38',
  size: 3_100_000_000,
  indexed: true,
  indexing: false,
  active: true,
);

Snp snpFixture({
  int id = 9,
  String name = 'dbSNP common',
  SnpImportStatus status = SnpImportStatus.ready,
}) => Snp(
  id: id,
  name: name,
  vcfPath: '/opt/flumip/data/custom_snp/set.vcf.gz',
  tbiPath: '/opt/flumip/data/custom_snp/set.vcf.gz.tbi',
  folder: '/opt/flumip/data/custom_snp',
  custom: true,
  private: false,
  status: status,
  statusMessage: '',
  size: 1000,
  bytesDownloaded: 0,
  totalBytes: 0,
  created: DateTime(2026),
);

class Calls {
  int pickGenome = 0;
  final added = <String>[];
  final removed = <String>[];
  int? snpId;
  bool snpChanged = false;
}

Future<Calls> pumpInputs(
  WidgetTester tester, {
  required Project project,
  Genome? genome,
  Snp? snp,
  Future<List<Snp>>? snpsForGenome,
  String? errorMessage,
}) async {
  final calls = Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: ProjectInputsColumn(
              project: project,
              genome: genome,
              snp: snp,
              snpsForGenome: snpsForGenome,
              errorMessage: errorMessage,
              onDismissError: () {},
              onPickGenome: () => calls.pickGenome++,
              onSnpChanged: (id) {
                calls.snpChanged = true;
                calls.snpId = id;
              },
              onAddGene: calls.added.add,
              onRemoveGene: calls.removed.add,
            ),
          ),
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  group('isEditable', () {
    test('a project that has never run can be changed', () {
      expect(ProjectInputsColumn.isEditable(projectFixture()), isTrue);
    });

    test('a running project cannot', () {
      expect(
        ProjectInputsColumn.isEditable(projectFixture(active: true)),
        isFalse,
      );
    });

    test('a finished project cannot', () {
      // Its inputs describe what was actually designed.
      expect(
        ProjectInputsColumn.isEditable(
          projectFixture(completedIn: const Duration(minutes: 5)),
        ),
        isFalse,
      );
    });
  });

  group('the genome', () {
    testWidgets('a project with none is invited to choose', (tester) async {
      final calls = await pumpInputs(tester, project: projectFixture());

      expect(find.text('None chosen'), findsOneWidget);
      await tester.tap(find.text('Choose'));
      expect(calls.pickGenome, 1);
    });

    testWidgets('⚠️ a chosen genome can still be changed', (tester) async {
      // The picker used to disappear the moment a genome was set, replaced by
      // plain text — so a genome chosen by mistake could not be corrected
      // without deleting the project.
      await pumpInputs(
        tester,
        project: projectFixture(genome: 3),
        genome: genomeFixture(),
      );

      expect(find.text('hg38'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets('says it is loading rather than showing a placeholder name', (
      tester,
    ) async {
      // ⚠️ This is why the genome is a nullable rather than the
      // `Genome(name: 'default')` sentinel it used to be: that sentinel rendered
      // as a real genome called "default", and had no id for the SNP query.
      await pumpInputs(tester, project: projectFixture(genome: 3));

      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('default'), findsNothing);
    });

    testWidgets('a finished project shows it without a button', (tester) async {
      await pumpInputs(
        tester,
        project: projectFixture(
          genome: 3,
          completedIn: const Duration(minutes: 5),
        ),
        genome: genomeFixture(),
      );

      expect(find.text('hg38'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
    });
  });

  group('the SNP set', () {
    testWidgets('asks for a genome first', (tester) async {
      await pumpInputs(tester, project: projectFixture());
      expect(find.text('Choose a genome first.'), findsOneWidget);
    });

    testWidgets('⚠️ waits rather than reaching for an id that is not there yet', (
      tester,
    ) async {
      // The frame between opening a tile and its genome arriving. The previous
      // version did `genome.id!` here, which throws — and a thrown build is the
      // red error screen over the whole tab.
      await pumpInputs(tester, project: projectFixture(genome: 3));

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('offers the sets for the genome, and no set at all', (
      tester,
    ) async {
      final calls = await pumpInputs(
        tester,
        project: projectFixture(genome: 3),
        genome: genomeFixture(),
        snpsForGenome: Future.value([snpFixture()]),
      );
      await tester.pumpAndSettle();

      // Nothing chosen yet, so the field reads as the null option.
      expect(find.text('No SNP set'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<Snp?>));
      await tester.pumpAndSettle();
      expect(find.text('dbSNP common'), findsOneWidget);

      await tester.tap(find.text('dbSNP common'));
      await tester.pumpAndSettle();
      expect(calls.snpChanged, isTrue);
      expect(calls.snpId, 9);
    });

    testWidgets('a set that is not ready cannot be picked', (tester) async {
      await pumpInputs(
        tester,
        project: projectFixture(genome: 3),
        genome: genomeFixture(),
        snpsForGenome: Future.value([
          snpFixture(status: SnpImportStatus.downloading),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Snp?>));
      await tester.pumpAndSettle();

      // Its state is spelled out on the item rather than the item silently
      // doing nothing when tapped.
      expect(find.textContaining('dbSNP common ('), findsOneWidget);
    });

    testWidgets('an empty list says so', (tester) async {
      await pumpInputs(
        tester,
        project: projectFixture(genome: 3),
        genome: genomeFixture(),
        snpsForGenome: Future.value(const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('No SNP sets for this genome.'), findsOneWidget);
    });

    testWidgets('⚠️ a set that has gone away does not throw, and says so', (
      tester,
    ) async {
      // A DropdownButton whose value matches no item throws. An SNP can be
      // deleted, or stop being visible, out from under a project.
      await pumpInputs(
        tester,
        project: projectFixture(genome: 3, snp: 999),
        genome: genomeFixture(),
        snpsForGenome: Future.value([snpFixture()]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('no longer available'), findsOneWidget);
    });

    testWidgets('a failure to load is reported, not shown as an empty list', (
      tester,
    ) async {
      // A Completer rather than `Future.error`, which would land in the test
      // zone as an unhandled error before the FutureBuilder ever listens.
      final failing = Completer<List<Snp>>();
      await pumpInputs(
        tester,
        project: projectFixture(genome: 3),
        genome: genomeFixture(),
        snpsForGenome: failing.future,
      );
      failing.completeError(StateError('nope'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load SNP sets'), findsOneWidget);
      expect(find.text('No SNP sets for this genome.'), findsNothing);
    });

    testWidgets('a finished project shows its set as plain text', (
      tester,
    ) async {
      await pumpInputs(
        tester,
        project: projectFixture(
          genome: 3,
          snp: 9,
          completedIn: const Duration(minutes: 5),
        ),
        genome: genomeFixture(),
        snp: snpFixture(),
      );

      expect(find.text('dbSNP common'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<Snp?>), findsNothing);
    });
  });

  group('the genes', () {
    testWidgets('an empty panel says so', (tester) async {
      await pumpInputs(tester, project: projectFixture());
      expect(find.text('None yet.'), findsOneWidget);
    });

    testWidgets('genes are chips, and removable before the BED file', (
      tester,
    ) async {
      final calls = await pumpInputs(
        tester,
        project: projectFixture(genes: ['BRCA1', 'TP53']),
      );

      expect(find.byType(InputChip), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.close).first);
      expect(calls.removed, ['BRCA1']);
    });

    testWidgets('a built BED file freezes the list', (tester) async {
      // The target regions are derived from these genes, so changing them
      // afterwards would describe a design that was never run.
      await pumpInputs(
        tester,
        project: projectFixture(genes: ['BRCA1'], bedFileCreated: true),
      );

      expect(find.byType(InputChip), findsNothing);
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Add a gene'), findsNothing);
    });

    testWidgets('submitting the field adds a gene and clears it', (
      tester,
    ) async {
      final calls = await pumpInputs(tester, project: projectFixture());

      await tester.enterText(find.byType(TextField), '  BRCA1  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(calls.added, ['BRCA1']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('an empty box sends nothing', (tester) async {
      // Was unguarded, so pressing the button with an empty box sent an empty
      // gene name to the server and produced a failure for no reason.
      final calls = await pumpInputs(tester, project: projectFixture());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byTooltip('Add gene'));
      await tester.pump();

      expect(calls.added, isEmpty);
    });
  });

  testWidgets('an error is shown above the inputs it explains', (tester) async {
    await pumpInputs(
      tester,
      project: projectFixture(),
      errorMessage: 'Failed to reload project: no route to host',
    );

    expect(find.textContaining('no route to host'), findsOneWidget);
  });
}
