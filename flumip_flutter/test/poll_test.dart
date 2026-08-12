import 'package:flumip_flutter/poll.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pollInterval', () {
    test('is brisk while something can still move', () {
      expect(pollInterval(anyLive: true), const Duration(seconds: 2));
    });

    test('relaxes once everything has settled', () {
      expect(pollInterval(anyLive: false), const Duration(seconds: 20));
    });

    test('backs off after failures', () {
      expect(
        pollInterval(anyLive: true, consecutiveFailures: 1),
        const Duration(seconds: 4),
      );
      expect(
        pollInterval(anyLive: true, consecutiveFailures: 2),
        const Duration(seconds: 8),
      );
    });

    test('the backoff is capped so it always recovers', () {
      // Without the cap, a server that was down for a while would take hours to
      // be noticed coming back.
      expect(
        pollInterval(anyLive: true, consecutiveFailures: 99),
        const Duration(seconds: 16),
      );
    });
  });
  group('genomePollInterval', () {
    test('does not poll a genome that is not indexing', () {
      // The whole point of the move. The genome tab used to re-fetch every five
      // seconds for as long as a genome was selected, which rebuilt the tab
      // twelve times a minute for data that cannot change on its own — and could
      // land mid-toggle and put the Active switch back.
      expect(genomePollInterval(indexing: false), isNull);
    });

    test('watches an index being built', () {
      expect(genomePollInterval(indexing: true), const Duration(seconds: 2));
    });

    test('backs off like everything else', () {
      expect(
        genomePollInterval(indexing: true, consecutiveFailures: 2),
        const Duration(seconds: 8),
      );
    });
  });
}
