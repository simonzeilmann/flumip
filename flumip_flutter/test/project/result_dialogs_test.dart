import 'package:flumip_flutter/project/result_dialogs.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UcscTrackDialog', () {
    Future<String?> pumpPicker(
      WidgetTester tester,
      Map<String, String> regions,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosen = await showDialog<String>(
                    context: context,
                    builder: (_) => UcscTrackDialog(regions: regions),
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
      return chosen;
    }

    testWidgets('lists every region once', (tester) async {
      await pumpPicker(tester, {
        'chr1:100-200': 'https://ucsc/1',
        'chr7:300-400': 'https://ucsc/2',
      });

      expect(find.text('chr1:100-200'), findsOneWidget);
      expect(find.text('chr7:300-400'), findsOneWidget);
    });

    testWidgets('returns the URL of the region picked', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  chosen = await showDialog<String>(
                    context: context,
                    builder: (_) => const UcscTrackDialog(
                      regions: {
                        'chr1:100-200': 'https://ucsc/one',
                        'chr7:300-400': 'https://ucsc/two',
                      },
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
      await tester.tap(find.text('chr7:300-400'));
      await tester.pumpAndSettle();

      expect(chosen, 'https://ucsc/two');
    });

    testWidgets('is a single dialog — nothing opens on top of it', (
      tester,
    ) async {
      // ⚠️ The regression guard. The flow this replaces showed the raw track
      // file in one dialog and opened a *second* dialog from a button inside it
      // to pick the region.
      await pumpPicker(tester, {
        'chr1:100-200': 'https://ucsc/1',
        'chr7:300-400': 'https://ucsc/2',
      });
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancelling returns nothing', (tester) async {
      final chosen = await pumpPicker(tester, {'chr1:1-2': 'https://ucsc/1'});
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });
  });

  group('showTextFileDialog', () {
    Future<void> pumpViewer(
      WidgetTester tester, {
      required List<String> lines,
      String title = 'MIPs result',
      String empty = 'No result file found.',
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showTextFileDialog(
                  context,
                  title: title,
                  lines: lines,
                  emptyMessage: empty,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the lines and counts them', (tester) async {
      await pumpViewer(tester, lines: ['one', 'two', 'three']);
      expect(find.text('3 lines'), findsOneWidget);
      expect(find.text('one'), findsOneWidget);
    });

    testWidgets('says "1 line" rather than "1 lines"', (tester) async {
      await pumpViewer(tester, lines: ['only']);
      expect(find.text('1 line'), findsOneWidget);
    });

    testWidgets('a summary replaces the line count where one is given',
        (tester) async {
      // ⚠️ "10 lines" was the misleading part: a result file interleaves MIPs
      // with mipgen's remarks, so the count says nothing about what was
      // produced.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showTextFileDialog(
                  context,
                  title: 'SNP MIPs result',
                  lines: const ['>header', '>note', 'a row', 'another'],
                  summary: '2 MIPs · 1 note',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('2 MIPs · 1 note'), findsOneWidget);
      expect(find.text('4 lines'), findsNothing);
    });

    testWidgets('an empty file says so and offers no copy', (tester) async {
      await pumpViewer(tester, lines: const []);
      expect(find.text('No result file found.'), findsOneWidget);
      expect(find.text('Copy all'), findsNothing);
    });

    testWidgets('a long file does not build every row at once', (tester) async {
      // The old dialog built one Text per line inside a ListBody, so a
      // thousand-line result built a thousand widgets before it could draw.
      await pumpViewer(
        tester,
        lines: List.generate(5000, (i) => 'row $i with some columns'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('5000 lines'), findsOneWidget);
      // Only what fits is realised.
      expect(find.text('row 4999 with some columns'), findsNothing);
    });
  });
}
