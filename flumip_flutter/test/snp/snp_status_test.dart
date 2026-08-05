import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/snp_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isTerminal', () {
    test('ready and failed are terminal, the rest are not', () {
      expect(isTerminal(SnpImportStatus.ready), isTrue);
      expect(isTerminal(SnpImportStatus.failed), isTrue);
      expect(isTerminal(SnpImportStatus.pending), isFalse);
      expect(isTerminal(SnpImportStatus.downloading), isFalse);
      expect(isTerminal(SnpImportStatus.indexing), isFalse);
    });
  });

  group('progressFraction', () {
    test('is null when the total is unknown, so the bar is indeterminate', () {
      // A server that sent no Content-Length. An indeterminate bar is honest;
      // a bar stuck at zero looks broken.
      expect(progressFraction(0, 0), isNull);
      expect(progressFraction(5000, 0), isNull);
      expect(progressFraction(0, -1), isNull);
    });

    test('is the ratio in between', () {
      expect(progressFraction(0, 100), 0.0);
      expect(progressFraction(50, 100), 0.5);
      expect(progressFraction(100, 100), 1.0);
    });

    test('clamps, because an out-of-range value asserts in LinearProgressIndicator',
        () {
      // Not defensive tidying. A debug build *crashes the tab* on a value outside
      // 0..1, so a server that miscounts — a redirect counted twice, a
      // Content-Length that was a lie — would take the page down.
      expect(progressFraction(150, 100), 1.0);
      expect(progressFraction(-10, 100), 0.0);
    });
  });

  group('pollInterval', () {
    test('is brisk while something can still move', () {
      expect(pollInterval(anyLive: true), const Duration(seconds: 2));
    });

    test('relaxes once everything has settled', () {
      expect(pollInterval(anyLive: false), const Duration(seconds: 20));
    });

    test('backs off after failures', () {
      expect(pollInterval(anyLive: true, consecutiveFailures: 1),
          const Duration(seconds: 4));
      expect(pollInterval(anyLive: true, consecutiveFailures: 2),
          const Duration(seconds: 8));
    });

    test('the backoff is capped so it always recovers', () {
      // Without the cap, a server that was down for a while would take hours to
      // be noticed coming back.
      expect(pollInterval(anyLive: true, consecutiveFailures: 99),
          const Duration(seconds: 16));
    });
  });

  group('labels', () {
    test('every status has a label, a colour and an icon', () {
      for (final status in SnpImportStatus.values) {
        expect(statusLabel(status), isNotEmpty);
        expect(() => statusColour(status), returnsNormally);
        expect(() => statusIcon(status), returnsNormally);
      }
    });
  });
}
