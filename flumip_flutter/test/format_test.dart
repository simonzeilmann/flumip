import 'package:flumip_flutter/format.dart';
import 'package:flutter_test/flutter_test.dart';

/// [formatBytes] had no tests when it lived inside `project_tile.dart`. Lifting
/// it out so the SNP list could share it made them free.
void main() {
  test('sub-kilobyte sizes are counted in bytes', () {
    expect(formatBytes(0), '0 bytes');
    expect(formatBytes(1), '1 bytes');
    expect(formatBytes(999), '999 bytes');
  });

  test('SI units, not binary ones', () {
    // A download manager and the operating system's own file listing both say
    // 1.00 kB for a thousand bytes. Disagreeing with them is worse than being
    // technically defensible.
    expect(formatBytes(1000), '1.00 kB');
    expect(formatBytes(1000000), '1.00 MB');
    expect(formatBytes(1000000000), '1.00 GB');
    expect(formatBytes(1000000000000), '1.00 TB');
  });

  test('decimals shrink as the number grows', () {
    expect(formatBytes(1500), '1.50 kB');
    expect(formatBytes(15000), '15.0 kB');
    expect(formatBytes(150000), '150 kB');
  });

  test('a realistic VCF size', () {
    expect(formatBytes(1500000000), '1.50 GB');
  });

  test('it does not run out of units', () {
    // Larger than a terabyte stays in terabytes rather than falling off the end
    // of the list.
    expect(formatBytes(5000000000000000), '5000 TB');
  });

  group('formatDuration', () {
    test('pads minutes and seconds so a column lines up', () {
      expect(formatDuration(const Duration(seconds: 3)), '00:00:03');
      expect(
        formatDuration(const Duration(minutes: 2, seconds: 3)),
        '00:02:03',
      );
    });

    test('a realistic design run', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    test('hours accumulate rather than wrapping at a day', () {
      // A big panel can design for longer than a day, and '01:00:00' for a
      // twenty-five hour run would be a lie rather than a rounding.
      expect(formatDuration(const Duration(hours: 25)), '25:00:00');
    });

    test('a negative duration is signed once, not twice', () {
      // Clock skew is the only way to get one; it used to render as '--1:00:00'
      // because the hours were negated as well as prefixed.
      expect(formatDuration(const Duration(hours: -1)), '-01:00:00');
    });
  });
}
