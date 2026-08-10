import 'package:flumip_flutter/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The regression test for the complaint that started this work: on a wide
/// monitor the app rendered every list edge to edge, so a project row was one
/// item on a 3400px line.
void main() {
  const childKey = Key('capped-child');

  Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  group('ContentWidth', () {
    testWidgets('caps the content on a wide display', (tester) async {
      await pumpAt(
        tester,
        3440,
        const ContentWidth(
          padding: EdgeInsets.zero,
          child: SizedBox(key: childKey, height: 100),
        ),
      );

      expect(tester.getSize(find.byKey(childKey)).width, ContentWidth.content);
    });

    testWidgets('uses the whole width when there is less than the cap', (
      tester,
    ) async {
      await pumpAt(
        tester,
        1000,
        const ContentWidth(
          padding: EdgeInsets.zero,
          child: SizedBox(key: childKey, height: 100),
        ),
      );

      expect(tester.getSize(find.byKey(childKey)).width, 1000);
    });

    testWidgets('centres what it caps', (tester) async {
      await pumpAt(
        tester,
        3000,
        const ContentWidth(
          padding: EdgeInsets.zero,
          child: SizedBox(key: childKey, height: 100),
        ),
      );

      final box = tester.getRect(find.byKey(childKey));
      expect(box.left, (3000 - ContentWidth.content) / 2);
      expect(box.right, 3000 - (3000 - ContentWidth.content) / 2);
    });

    testWidgets('the form cap is narrower than the content cap', (
      tester,
    ) async {
      // A form is not a table: two field columns, not three data columns.
      expect(ContentWidth.form, lessThan(ContentWidth.content));
      expect(ContentWidth.content, lessThan(ContentWidth.wide));
    });

    testWidgets('an Expanded child still resolves inside the cap', (
      tester,
    ) async {
      // `Center` loosens constraints, and the projects tab puts an
      // `Expanded > ListView` inside this. Loose is still bounded, so it
      // resolves — but it is worth holding the line, because the failure mode
      // is an unbounded-height exception at runtime rather than at compile time.
      await pumpAt(
        tester,
        1600,
        Column(
          children: [
            const ContentWidth(
              padding: EdgeInsets.zero,
              child: SizedBox(key: childKey, height: 50),
            ),
            Expanded(child: Container()),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
