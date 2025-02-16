import 'package:test/test.dart';

// Import the generated test helper file, it contains everything you need.
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Mipgen endpoint', (sessionBuilder, endpoints) {
    test('creates a project', () async {
      final result =
          await endpoints.mipgen.createProject(sessionBuilder, "int_test");
      expect(result, true);
    },
    tags: ['integration']);

    test('sample test', () {
      expect(1, 1);
    },
    tags: ['integration', 'action']);
  });
}
