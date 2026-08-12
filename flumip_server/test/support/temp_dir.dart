import 'dart:io';

import 'package:test/test.dart';

/// Creates a unique temporary directory for a filesystem test and registers an
/// [addTearDown] callback to delete it after the test completes.
Directory createTempDir([String prefix = 'flumip_test']) {
  final dir = Directory.systemTemp.createTempSync('${prefix}_');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return dir;
}
