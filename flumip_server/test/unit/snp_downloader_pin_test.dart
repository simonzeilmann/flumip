import 'dart:async';
import 'dart:io';

import 'package:flumip_server/src/services/snp_downloader.dart';
import 'package:test/test.dart';

import '../support/temp_dir.dart';
import '../support/test_tls.dart';

/// [HttpSnpDownloader] connects to the address the guard vetted, and only that.
///
/// The threat is DNS rebinding: a hostile name server answers "public" when the
/// guard asks and "127.0.0.1" when the HTTP client asks again a moment later.
/// Every test here injects a resolver that does exactly that, and a connector
/// that records the address it is handed and then dials a server on 127.0.0.1
/// standing in for the remote host — so the whole thing runs without DNS or the
/// internet, and the recorded addresses are the evidence.
void main() {
  final publicA = InternetAddress('93.184.216.34');
  final publicB = InternetAddress('1.1.1.1');
  final loopback = InternetAddress.loopbackIPv4;

  late HttpServer server;
  late List<String> hostHeaders;
  late Map<String, void Function(HttpResponse)> routes;
  late List<(InternetAddress, int)> dialled;
  late Map<String, int> lookups;

  /// First answer per host from [first], every later one 127.0.0.1.
  HostResolver rebinding(Map<String, List<InternetAddress>> first) {
    return (host) async {
      final n = lookups[host] = (lookups[host] ?? 0) + 1;
      return n == 1 ? (first[host] ?? const []) : [loopback];
    };
  }

  /// Records what it was asked to dial, then dials the local test server.
  PinnedConnector recordingConnector({Set<InternetAddress> fail = const {}}) {
    return (address, port) {
      dialled.add((address, port));
      if (fail.contains(address)) {
        return Future.error(const SocketException('unreachable (test)'));
      }
      return Socket.startConnect(loopback, server.port);
    };
  }

  void serve(HttpRequest request) {
    hostHeaders.add(request.headers.value(HttpHeaders.hostHeader) ?? '');
    final handler = routes[request.uri.path];
    if (handler == null) {
      request.response.statusCode = 404;
    } else {
      handler(request.response);
    }
    request.response.close();
  }

  void body(HttpResponse r, String text) {
    r.contentLength = text.length;
    r.write(text);
  }

  setUp(() {
    hostHeaders = [];
    routes = {};
    dialled = [];
    lookups = {};
  });

  Future<int> download(HttpSnpDownloader downloader, String url, File target) =>
      downloader.download(
        Uri.parse(url),
        target,
        maxBytes: 1 << 20,
        allowedHosts: const [],
        onProgress: (_, _) {},
      );

  group('plain http', () {
    setUp(() async {
      server = await HttpServer.bind(loopback, 0);
      server.listen(serve);
    });
    tearDown(() => server.close(force: true));

    test('the vetted address is dialled even when the name later rebinds to '
        'loopback', () async {
      routes['/x.vcf'] = (r) => body(r, 'payload');
      final target = File('${createTempDir().path}/x.vcf');

      final downloader = HttpSnpDownloader(
        resolver: rebinding({
          'rebind.example': [publicA],
        }),
        connector: recordingConnector(),
      );
      final bytes = await download(
        downloader,
        'http://rebind.example/x.vcf',
        target,
      );

      expect(bytes, 7);
      expect(await target.readAsString(), 'payload');
      // ⚠️ The evidence: the only address ever dialled is the one that was
      // checked, and the name was looked up once — nothing downstream had a
      // chance to ask the rebinding resolver (or the OS) a second time.
      expect(dialled, [(publicA, 80)]);
      expect(lookups, {'rebind.example': 1});
      // The request itself is unchanged: Host is still the name.
      expect(hostHeaders, ['rebind.example']);
    }, tags: ['unit']);

    test('a redirect hop is pinned to its own vetted address', () async {
      routes['/a'] = (r) => r
        ..statusCode = 302
        ..headers.set(HttpHeaders.locationHeader, 'http://mirror.example/b');
      routes['/b'] = (r) => body(r, 'mirrored');
      final target = File('${createTempDir().path}/b.vcf');

      final downloader = HttpSnpDownloader(
        resolver: rebinding({
          'rebind.example': [publicA],
          'mirror.example': [publicB],
        }),
        connector: recordingConnector(),
      );
      await download(downloader, 'http://rebind.example/a', target);

      expect(await target.readAsString(), 'mirrored');
      expect(dialled, [(publicA, 80), (publicB, 80)]);
      expect(lookups, {'rebind.example': 1, 'mirror.example': 1});
      expect(hostHeaders, ['rebind.example', 'mirror.example']);
    }, tags: ['unit']);

    test(
      'a redirect to a name that resolves to loopback is never dialled',
      () async {
        routes['/a'] = (r) => r
          ..statusCode = 302
          ..headers.set(HttpHeaders.locationHeader, 'http://inside.example/');
        final target = File('${createTempDir().path}/a.vcf');

        final downloader = HttpSnpDownloader(
          resolver: rebinding({
            'rebind.example': [publicA],
            'inside.example': [loopback],
          }),
          connector: recordingConnector(),
        );

        await expectLater(
          download(downloader, 'http://rebind.example/a', target),
          throwsA(
            isA<SnpDownloadException>().having(
              (e) => e.message,
              'message',
              contains('redirected somewhere refused'),
            ),
          ),
        );
        expect(dialled, [(publicA, 80)]);
        expect(target.existsSync(), isFalse);
      },
      tags: ['unit'],
    );

    test(
      'with several vetted addresses, an unreachable one falls through to the '
      'next and nothing else is tried',
      () async {
        routes['/x.vcf'] = (r) => body(r, 'ok');
        final target = File('${createTempDir().path}/x.vcf');

        final downloader = HttpSnpDownloader(
          resolver: rebinding({
            'multi.example': [publicA, publicB],
          }),
          connector: recordingConnector(fail: {publicA}),
        );
        await download(downloader, 'http://multi.example/x.vcf', target);

        expect(await target.readAsString(), 'ok');
        expect(dialled, [(publicA, 80), (publicB, 80)]);
      },
      tags: ['unit'],
    );
  });

  group('the connection factory fails closed', () {
    test('a URL with no pin is refused instead of being looked up', () async {
      final factory = HttpSnpDownloader.pinnedConnectionFactory(
        {},
        connector: (a, p) => fail('must not dial'),
      );
      await expectLater(
        factory(Uri.parse('http://unpinned.example/'), null, null),
        throwsA(isA<SocketException>()),
      );
    }, tags: ['unit']);

    test('a proxy is refused even for a pinned URL', () async {
      final url = Uri.parse('http://pinned.example/');
      final factory = HttpSnpDownloader.pinnedConnectionFactory({
        HttpSnpDownloader.pinKey(url): [publicA],
      }, connector: (a, p) => fail('must not dial'));
      await expectLater(
        factory(url, 'proxy.internal', 3128),
        throwsA(isA<SocketException>()),
      );
    }, tags: ['unit']);
  });

  group('https', () {
    setUp(() async {
      server = await HttpServer.bindSecure(loopback, 0, testServerContext());
      server.listen(serve);
    });
    tearDown(() => server.close(force: true));

    HttpSnpDownloader tlsDownloader({SecurityContext? context}) =>
        HttpSnpDownloader(
          resolver: rebinding({
            testServerHost: [publicA],
            'wrong.example.test': [publicA],
          }),
          connector: recordingConnector(),
          securityContext: context ?? testClientContext(),
        );

    test('the certificate is verified against the hostname, not the pinned '
        'address', () async {
      // The socket goes to 93.184.216.34 (really 127.0.0.1), neither of which
      // is in the certificate. The handshake succeeding proves the name the
      // certificate was checked against is the URL's host.
      routes['/x.vcf'] = (r) => body(r, 'secure');
      final target = File('${createTempDir().path}/x.vcf');

      await download(tlsDownloader(), 'https://$testServerHost/x.vcf', target);

      expect(await target.readAsString(), 'secure');
      expect(dialled, [(publicA, 443)]);
      expect(hostHeaders, [testServerHost]);
    }, tags: ['unit']);

    test('a certificate for a different name is refused', () async {
      routes['/x.vcf'] = (r) => body(r, 'should not arrive');
      final target = File('${createTempDir().path}/x.vcf');

      await expectLater(
        download(tlsDownloader(), 'https://wrong.example.test/x.vcf', target),
        throwsA(
          isA<SnpDownloadException>().having(
            (e) => e.message,
            'message',
            'Could not reach that address.',
          ),
        ),
      );
      expect(hostHeaders, isEmpty);
      expect(target.existsSync(), isFalse);
    }, tags: ['unit']);

    test('a certificate from an untrusted authority is refused', () async {
      routes['/x.vcf'] = (r) => body(r, 'should not arrive');
      final target = File('${createTempDir().path}/x.vcf');

      await expectLater(
        download(
          tlsDownloader(context: SecurityContext(withTrustedRoots: false)),
          'https://$testServerHost/x.vcf',
          target,
        ),
        throwsA(isA<SnpDownloadException>()),
      );
      expect(hostHeaders, isEmpty);
    }, tags: ['unit']);
  });
}
