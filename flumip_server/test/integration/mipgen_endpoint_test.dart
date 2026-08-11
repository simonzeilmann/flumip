import 'dart:io';

import 'package:flumip_server/src/generated/project_options.dart';
import 'package:test/test.dart';

import '../support/seed.dart';
// Import the generated test helper file, it contains everything you need.
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Mipgen endpoint', (sessionBuilder, endpoints) {
    var session = sessionBuilder.build();

    test('creates a project', () async {
      // Point projectDir at a temp directory so the test does not depend on
      // /opt/flumip existing (createProject creates <projectDir>/<folderName>).
      final base = Directory.systemTemp.createTempSync('flumip_mipgen_ep_');
      addTearDown(() {
        if (base.existsSync()) base.deleteSync(recursive: true);
      });
      await overrideSettingsDirs(session, projectDir: base.path);

      final result = await endpoints.project.createProject(
        sessionBuilder,
        "int_test",
        ProjectOptions(id: 1),
      );
      expect(result.id, greaterThan(0));
    }, tags: ['integration']);
  });
}
