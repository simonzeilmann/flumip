import 'package:test/test.dart';

// Import the generated test helper file, it contains everything you need.
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Mipgen endpoint', (sessionBuilder, endpoints) {
    test('creates a project', () async {
      final result =
          await endpoints.project.createProject(sessionBuilder, "int_test");
      expect(result, true);
    },
    tags: ['integration']);
  });
}
