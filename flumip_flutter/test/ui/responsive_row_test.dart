import 'package:flumip_flutter/ui/layout.dart';
import 'package:flumip_flutter/ui/responsive_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpInWidth(
      WidgetTester tester, double width, Widget child) async {
    // The default test surface is 800x600, which would clamp any SizedBox wider
    // than that and quietly test the narrow branch instead of the wide one.
    tester.view.physicalSize = Size(width + 200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    );
  }

  const a = Key('a');
  const b = Key('b');
  const c = Key('c');

  ResponsiveRow three({double minChildWidth = 300}) => ResponsiveRow(
        minChildWidth: minChildWidth,
        children: const [
          SizedBox(key: a, height: 20),
          SizedBox(key: b, height: 20),
          SizedBox(key: c, height: 20),
        ],
      );

  testWidgets('lays out side by side when every child fits', (tester) async {
    // 3 × 300 + 2 × 16 spacing = 932.
    await pumpInWidth(tester, 1000, three());

    expect(find.byType(Row), findsOneWidget);
    expect(tester.getRect(find.byKey(a)).top, tester.getRect(find.byKey(b)).top);
  });

  testWidgets('stacks when they would be squeezed', (tester) async {
    await pumpInWidth(tester, 700, three());

    expect(find.byType(Row), findsNothing);
    expect(
      tester.getRect(find.byKey(b)).top,
      greaterThan(tester.getRect(find.byKey(a)).top),
    );
  });

  testWidgets('every child is present in both layouts', (tester) async {
    for (final width in [1400.0, 400.0]) {
      await pumpInWidth(tester, width, three());
      expect(find.byKey(a), findsOneWidget, reason: 'at $width');
      expect(find.byKey(b), findsOneWidget, reason: 'at $width');
      expect(find.byKey(c), findsOneWidget, reason: 'at $width');
    }
  });

  testWidgets('flex gives a hostname the room a port does not need',
      (tester) async {
    await pumpInWidth(
      tester,
      900,
      const ResponsiveRow(
        minChildWidth: 200,
        flex: [3, 1],
        children: [
          SizedBox(key: a, height: 20),
          SizedBox(key: b, height: 20),
        ],
      ),
    );

    final server = tester.getSize(find.byKey(a)).width;
    final port = tester.getSize(find.byKey(b)).width;
    expect(server, closeTo(port * 3, 1));
  });

  testWidgets('decides from its own width, not the window', (tester) async {
    // ⚠️ The bug the width cap would have introduced. On a wide display, a row
    // inside a narrow capped form must still stack — `MediaQuery` would report
    // the window and lay out three columns in a space that fits one.
    tester.view.physicalSize = const Size(3440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContentWidth(
            maxWidth: 600,
            padding: EdgeInsets.zero,
            child: three(),
          ),
        ),
      ),
    );

    expect(find.byType(Row), findsNothing);
  });

  testWidgets('an unbounded width has room for anything', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 1200, child: three()),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Row), findsWidgets);
  });
}
