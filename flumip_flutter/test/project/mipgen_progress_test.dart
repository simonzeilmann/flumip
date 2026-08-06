import 'package:flumip_flutter/project/mipgen_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('current', () {
    test('is the last line with anything on it', () {
      const p = MipgenProgress(lines: ['starting', 'scanning', 'designing']);
      expect(p.current, 'designing');
    });

    test('skips the trailing blank lines a log usually ends with', () {
      const p = MipgenProgress(lines: ['working', '', '   ', '\t']);
      expect(p.current, 'working');
    });

    test('is null for an empty file', () {
      expect(const MipgenProgress.empty().current, isNull);
      expect(const MipgenProgress(lines: ['', ' ']).current, isNull);
    });

    test('is trimmed', () {
      const p = MipgenProgress(lines: ['  designing MIPs  ']);
      expect(p.current, 'designing MIPs');
    });
  });

  group('fraction', () {
    test('reads a percentage', () {
      expect(const MipgenProgress(lines: ['43% done']).fraction, 0.43);
      expect(const MipgenProgress(lines: ['done 7 %']).fraction, 0.07);
    });

    test('reads "3 of 12"', () {
      expect(
        const MipgenProgress(lines: ['gene 3 of 12']).fraction,
        closeTo(0.25, 0.0001),
      );
    });

    test('reads "3/12"', () {
      expect(
        const MipgenProgress(lines: ['gene 3/12']).fraction,
        closeTo(0.25, 0.0001),
      );
    });

    test('is null when the line says nothing about progress', () {
      expect(
        const MipgenProgress(lines: ['scanning the genome']).fraction,
        isNull,
      );
    });

    test('is null for an empty file, so the bar stays indeterminate', () {
      // ⚠️ Deliberately not 0.0. An empty bar reads as "started and stuck";
      // an indeterminate one reads as "working", which is the truth.
      expect(const MipgenProgress.empty().fraction, isNull);
    });

    test('clamps, because LinearProgressIndicator asserts out of range', () {
      // A debug build *crashes the tab* on a value outside 0..1, so a log line
      // reading "150%" would take the page down rather than draw a full bar.
      expect(const MipgenProgress(lines: ['150%']).fraction, 1.0);
      expect(const MipgenProgress(lines: ['gene 9 of 3']).fraction, 1.0);
    });

    test('does not divide by zero', () {
      expect(const MipgenProgress(lines: ['gene 0 of 0']).fraction, isNull);
    });

    test('only the last line counts', () {
      const p = MipgenProgress(lines: ['10% done', 'finishing up']);
      expect(p.fraction, isNull);
    });
  });

  group('the panel', () {
    Future<void> pump(WidgetTester tester, MipgenProgress progress,
        {Duration? elapsed}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MipgenProgressPanel(
              progress: progress,
              elapsed: elapsed,
              onShowLog: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('says what the run is doing', (tester) async {
      await pump(tester, const MipgenProgress(lines: ['designing arm pairs']));
      expect(find.text('designing arm pairs'), findsOneWidget);
    });

    testWidgets('says something before the log exists', (tester) async {
      // mipgen writes nothing for the first few seconds; a blank line there
      // looks like a failure.
      await pump(tester, const MipgenProgress.empty());
      expect(find.text('Starting up…'), findsOneWidget);
    });

    testWidgets('shows how long it has been going', (tester) async {
      await pump(
        tester,
        const MipgenProgress.empty(),
        elapsed: const Duration(minutes: 3, seconds: 7),
      );
      expect(find.text('3m 7s'), findsOneWidget);
    });

    testWidgets('shows hours once it has been that long', (tester) async {
      await pump(
        tester,
        const MipgenProgress.empty(),
        elapsed: const Duration(hours: 2, minutes: 5),
      );
      expect(find.text('2h 5m'), findsOneWidget);
    });

    testWidgets('an out-of-range value does not take the tab down',
        (tester) async {
      await pump(tester, const MipgenProgress(lines: ['999%']));
      expect(tester.takeException(), isNull);
    });
  });
}
