import 'package:flumip_flutter/project/gene_editor.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gene list and the field under it.
///
/// Had no test at all, which is how "the cursor leaves the field after every
/// gene" survived — the widget works perfectly on a single gene, and a panel is
/// never filled one gene at a time in a test that does not exist.
Future<List<String>> pumpEditor(
  WidgetTester tester, {
  List<String> genes = const [],
  bool editable = true,
}) async {
  final added = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: GeneEditor(
          genes: genes,
          editable: editable,
          onAdd: added.add,
          onRemove: (_) {},
        ),
      ),
    ),
  );
  return added;
}

Finder get _field => find.byType(TextField);
Finder get _addButton => find.widgetWithIcon(IconButton, Icons.add);

bool _fieldHasFocus(WidgetTester tester) =>
    tester.widget<TextField>(_field).focusNode?.hasFocus ?? false;

void main() {
  group('adding a gene', () {
    testWidgets('submitting sends the trimmed text and clears the box', (
      tester,
    ) async {
      final added = await pumpEditor(tester);

      await tester.enterText(_field, '  BRCA1 ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(added, ['BRCA1']);
      expect(tester.widget<TextField>(_field).controller!.text, isEmpty);
    });

    testWidgets('the button adds the same way as the keyboard', (tester) async {
      final added = await pumpEditor(tester);

      await tester.enterText(_field, 'TP53');
      await tester.tap(_addButton);
      await tester.pump();

      expect(added, ['TP53']);
    });

    testWidgets('an empty box sends nothing', (tester) async {
      // Unguarded once, which sent an empty gene name to the server and turned
      // a stray keypress into a failure.
      final added = await pumpEditor(tester);

      await tester.enterText(_field, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(added, isEmpty);
    });
  });

  group('⚠️ where the cursor ends up', () {
    // A panel is filled several genes at a time, so the cost of losing focus is
    // paid once per gene: before this, every gene after the first needed the
    // field clicked again.
    testWidgets('pressing enter leaves the cursor in the field', (
      tester,
    ) async {
      await pumpEditor(tester);

      await tester.tap(_field);
      await tester.pump();
      await tester.enterText(_field, 'BRCA1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(_fieldHasFocus(tester), isTrue);
    });

    testWidgets('several genes in a row need no clicking between them', (
      tester,
    ) async {
      final added = await pumpEditor(tester);

      await tester.tap(_field);
      await tester.pump();
      for (final gene in ['BRCA1', 'TP53', 'MYH11']) {
        await tester.enterText(_field, gene);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(
          _fieldHasFocus(tester),
          isTrue,
          reason: 'focus was lost after $gene',
        );
      }

      expect(added, ['BRCA1', 'TP53', 'MYH11']);
    });

    testWidgets('the button hands focus back too', (tester) async {
      // Clicking it otherwise leaves focus on the button itself.
      await pumpEditor(tester);

      await tester.enterText(_field, 'TP53');
      await tester.tap(_addButton);
      await tester.pump();

      expect(_fieldHasFocus(tester), isTrue);
    });

    testWidgets('submitting an empty box still focuses the field', (
      tester,
    ) async {
      // It is where somebody is about to type.
      await pumpEditor(tester);

      await tester.tap(_addButton);
      await tester.pump();

      expect(_fieldHasFocus(tester), isTrue);
    });
  });

  group('the list', () {
    testWidgets('says so when there are no genes', (tester) async {
      await pumpEditor(tester);
      expect(find.text('None yet.'), findsOneWidget);
    });

    testWidgets('shows a chip per gene', (tester) async {
      await pumpEditor(tester, genes: ['BRCA1', 'TP53']);
      expect(find.text('BRCA1'), findsOneWidget);
      expect(find.text('TP53'), findsOneWidget);
    });

    testWidgets('offers no field once the BED file has been built', (
      tester,
    ) async {
      // The target regions are derived from this list, so changing it afterwards
      // would describe a design that was never run.
      await pumpEditor(tester, genes: ['BRCA1'], editable: false);

      expect(_field, findsNothing);
      expect(_addButton, findsNothing);
      expect(find.byType(InputChip), findsNothing);
    });
  });
}
