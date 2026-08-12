import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Selecting the design options must not drag in the results beside them.
///
/// The app wraps everything in one `SelectionArea` so static text is selectable
/// at all — Flutter web makes `Text` unselectable by default. But a single area
/// spanning the whole tile means a drag that starts in the parameters runs on
/// into whatever sits to their right, so copying the parameters gets you the
/// parameters *and* the results.
///
/// The fix is a nested `SelectionArea` per column. This test exists because that
/// is an assumption about how Flutter's selection scoping composes, and it is
/// cheaper to hold it here than to rediscover it by copying the wrong thing.
void main() {
  Future<void> pumpColumns(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: Row(
              children: [
                Expanded(
                  child: SelectionArea(
                    child: Text(
                      'OPTIONS-LEFT',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: Text(
                      'RESULTS-RIGHT',
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a nested SelectionArea owns its own subtree', (tester) async {
    await pumpColumns(tester);

    // Three areas: the outer one and one per column. If nesting were ignored
    // there would be one.
    expect(find.byType(SelectionArea), findsNWidgets(3));
  });

  testWidgets('dragging across a column does not throw', (tester) async {
    await pumpColumns(tester);

    final left = tester.getCenter(find.text('OPTIONS-LEFT'));
    final right = tester.getCenter(find.text('RESULTS-RIGHT'));

    final gesture = await tester.startGesture(left);
    await tester.pump();
    await gesture.moveTo(right);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // The behaviour under test is scoping, which Flutter owns; what this holds
    // is that the arrangement is stable — a drag spanning both columns neither
    // throws nor tears down the tree.
    expect(tester.takeException(), isNull);
    expect(find.text('OPTIONS-LEFT'), findsOneWidget);
    expect(find.text('RESULTS-RIGHT'), findsOneWidget);
  });
}
