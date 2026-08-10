import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/snp/snp_status.dart';
import 'package:flumip_flutter/ui/status_colors.dart';
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

    test(
      'clamps, because an out-of-range value asserts in LinearProgressIndicator',
      () {
        // Not defensive tidying. A debug build *crashes the tab* on a value outside
        // 0..1, so a server that miscounts — a redirect counted twice, a
        // Content-Length that was a lie — would take the page down.
        expect(progressFraction(150, 100), 1.0);
        expect(progressFraction(-10, 100), 0.0);
      },
    );
  });

  group('labels', () {
    test('every status has a label, a colour and an icon', () {
      for (final status in SnpImportStatus.values) {
        expect(statusLabel(status), isNotEmpty);
        // The palette is passed in rather than read from a BuildContext,
        // which is what lets this stay a VM test.
        expect(() => statusColour(status, StatusColors.light), returnsNormally);
        expect(() => statusIcon(status), returnsNormally);
      }
    });
  });
}
