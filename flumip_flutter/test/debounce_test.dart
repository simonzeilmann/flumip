import 'package:flumip_flutter/debounce.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure tests, the sibling of `poll_test.dart`.
///
/// Everything here uses `Duration.zero` and `pumpEventQueue()` rather than waiting
/// on the clock: no test in this repo advances a real timer, and a debounce test
/// that slept for 250 ms would be the slowest test in the suite for no gain.
void main() {
  group('Debouncer', () {
    test('runs the action once the calls stop coming', () async {
      final fired = <String>[];
      Debouncer(Duration.zero).run(() => fired.add('once'));

      expect(
        fired,
        isEmpty,
        reason: 'it fires after the delay, not during run',
      );
      await pumpEventQueue();
      expect(fired, ['once']);
    });

    test('a burst of calls fires once, with the last action', () async {
      final fired = <String>[];
      final debouncer = Debouncer(Duration.zero);

      debouncer.run(() => fired.add('b'));
      debouncer.run(() => fired.add('br'));
      debouncer.run(() => fired.add('brc'));
      await pumpEventQueue();

      // The whole point: a typed word is one request, and it asks about the word
      // rather than about its first letter.
      expect(fired, ['brc']);
    });

    test('cancel drops a pending action', () async {
      final fired = <String>[];
      final debouncer = Debouncer(Duration.zero)..run(() => fired.add('gone'));

      debouncer.cancel();
      await pumpEventQueue();

      expect(fired, isEmpty);
    });

    test('pending reports whether something is waiting', () async {
      final debouncer = Debouncer(Duration.zero);
      expect(debouncer.pending, isFalse);

      debouncer.run(() {});
      expect(debouncer.pending, isTrue);

      debouncer.cancel();
      expect(debouncer.pending, isFalse);
    });

    test('⚠️ pending goes false once the action has fired', () async {
      // A one-shot Timer stays referenced after firing, so a `_timer != null`
      // implementation would claim a debounce was pending forever.
      final debouncer = Debouncer(Duration.zero)..run(() {});

      await pumpEventQueue();

      expect(debouncer.pending, isFalse);
    });
  });

  test('searchDebounce is short enough to feel immediate', () {
    expect(searchDebounce, lessThan(const Duration(milliseconds: 400)));
    expect(searchDebounce, greaterThan(const Duration(milliseconds: 150)));
  });
}
