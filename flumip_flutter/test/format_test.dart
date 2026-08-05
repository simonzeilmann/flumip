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
}
