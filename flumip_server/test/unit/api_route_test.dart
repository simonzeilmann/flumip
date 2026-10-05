import 'package:flumip_server/src/web/routes/api_route.dart';
import 'package:test/test.dart';

// Only the prefix arithmetic can be tested here. Whether a request on the web
// port really reaches an endpoint is a routing question this suite cannot see —
// verify it with curl against a running server.
void main() {
  group('ApiRoute.stripPrefix', () {
    test('turns /api/<endpoint>/<method> into /<endpoint>/<method>', () {
      expect(
        ApiRoute.stripPrefix(
          Uri.parse('https://mips.example.org/api/project/list'),
        ).path,
        '/project/list',
      );
    });

    test('keeps the scheme, host, port and query', () {
      expect(
        ApiRoute.stripPrefix(
          Uri.parse('http://mips.example.org:9082/api/project/list?x=1'),
        ).toString(),
        'http://mips.example.org:9082/project/list?x=1',
      );
    });

    test('maps the bare prefix to the root', () {
      expect(
        ApiRoute.stripPrefix(Uri.parse('https://mips.example.org/api')).path,
        '/',
      );
      expect(
        ApiRoute.stripPrefix(Uri.parse('https://mips.example.org/api/')).path,
        '/',
      );
    });
  });
}
