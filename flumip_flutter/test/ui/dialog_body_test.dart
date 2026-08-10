import 'package:flumip_flutter/ui/dialog_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bodyKey = Key('body');

  Future<void> pumpDialogAt(
    WidgetTester tester,
    Size window,
    double width,
  ) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // A fresh key per pump, so a repeated call gets a new Navigator rather
        // than reusing one that still has the previous dialog on its stack.
        key: ValueKey('$window-$width'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  content: DialogBody(
                    width: width,
                    child: const SizedBox(key: bodyKey, height: 60),
                  ),
                ),
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

  testWidgets('keeps the chosen width when the window allows it', (
    tester,
  ) async {
    await pumpDialogAt(tester, const Size(1400, 900), 560);
    expect(tester.getSize(find.byKey(bodyKey)).width, 560);
  });

  testWidgets('gives up only as much as it must on a narrow window', (
    tester,
  ) async {
    // The bug this fixes: a 560px SizedBox in an AlertDialog on a 480px
    // viewport overflows its dialog and paints the yellow-and-black stripe.
    await pumpDialogAt(tester, const Size(480, 900), 560);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(bodyKey)).width, lessThanOrEqualTo(480));
  });

  testWidgets('the widest dialog in the app survives a narrow window', (
    tester,
  ) async {
    for (final width in [460.0, 520.0, 560.0]) {
      await pumpDialogAt(tester, const Size(400, 800), width);
      expect(tester.takeException(), isNull, reason: 'at width $width');
    }
  });
}
