import 'package:flumip_server/src/web/origin_guard.dart';
import 'package:flumip_server/src/web/routes/auth_routes.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

// Only the decisions can be tested here. Whether the routes really apply them —
// and whether Serverpod's own header middleware leaves the answer alone — is a
// question for curl against a running server.
void main() {
  group('normalizeOrigin', () {
    test('lowercases and drops a trailing slash and the default port', () {
      expect(
        normalizeOrigin('HTTPS://Mips.Example.org/'),
        'https://mips.example.org',
      );
      expect(
        normalizeOrigin('https://mips.example.org:443'),
        'https://mips.example.org',
      );
      expect(
        normalizeOrigin('http://mips.example.org:80'),
        'http://mips.example.org',
      );
      expect(normalizeOrigin('http://localhost:8082'), 'http://localhost:8082');
    });

    test('keeps IPv6 literals bracketed', () {
      expect(normalizeOrigin('http://[::1]:8082'), 'http://[::1]:8082');
    });

    test('is not fooled by things that are not origins', () {
      for (final raw in [
        '',
        'null',
        '*',
        'mips.example.org',
        'ftp://mips.example.org',
        'https://mips.example.org/path',
        'https://mips.example.org?x=1',
        'https://user@mips.example.org',
        'file:///etc/passwd',
      ]) {
        expect(normalizeOrigin(raw), isNull, reason: raw);
      }
    });
  });

  group('OriginPolicy.judge', () {
    const strict = OriginPolicy();

    test('no Origin is a non-browser client and is let through', () {
      expect(strict.judge(origin: null), OriginVerdict.noOrigin);
      expect(
        strict.judge(origin: null, secFetchSite: 'same-origin'),
        OriginVerdict.noOrigin,
      );
      // A typed-in URL.
      expect(
        strict.judge(origin: null, secFetchSite: 'none'),
        OriginVerdict.noOrigin,
      );
    });

    test('no Origin but Sec-Fetch-Site from another site is refused', () {
      // An <img> on another site: a no-cors GET, which carries no Origin.
      expect(
        strict.judge(origin: null, secFetchSite: 'cross-site'),
        OriginVerdict.refused,
      );
      expect(
        strict.judge(origin: null, secFetchSite: 'same-site'),
        OriginVerdict.refused,
      );
    });

    test('the configured public URL is the app', () {
      expect(
        strict.judge(
          origin: 'https://mips.example.org',
          host: '127.0.0.1:9082',
          appOrigin: 'https://mips.example.org/',
        ),
        OriginVerdict.sameOrigin,
      );
    });

    test('the host the request was addressed to is the app', () {
      // Reached directly, by address.
      expect(
        strict.judge(origin: 'http://10.0.0.5:9082', host: '10.0.0.5:9082'),
        OriginVerdict.sameOrigin,
      );
      // Behind a TLS proxy forwarding Host: the scheme differs, the port is
      // the default one on both sides.
      expect(
        strict.judge(
          origin: 'https://mips.example.org',
          host: 'mips.example.org',
        ),
        OriginVerdict.sameOrigin,
      );
      // Behind a proxy that rewrites Host but forwards the original.
      expect(
        strict.judge(
          origin: 'https://mips.example.org',
          host: '127.0.0.1:9082',
          forwardedHost: 'mips.example.org, inner.proxy',
        ),
        OriginVerdict.sameOrigin,
      );
    });

    test('another port on the same host is another origin', () {
      expect(
        strict.judge(origin: 'http://10.0.0.5:8000', host: '10.0.0.5:9082'),
        OriginVerdict.refused,
      );
      expect(
        strict.judge(
          origin: 'https://mips.example.org:8443',
          host: 'mips.example.org',
        ),
        OriginVerdict.refused,
      );
    });

    test('a page on another site is refused', () {
      expect(
        strict.judge(
          origin: 'https://evil.example',
          host: 'mips.example.org',
          appOrigin: 'https://mips.example.org',
        ),
        OriginVerdict.refused,
      );
      // A look-alike suffix is not the app.
      expect(
        strict.judge(
          origin: 'https://mips.example.org.evil.example',
          host: 'mips.example.org',
        ),
        OriginVerdict.refused,
      );
    });

    test('Origin: null (sandboxed frames, file:// pages) is refused', () {
      expect(
        strict.judge(origin: 'null', host: 'mips.example.org'),
        OriginVerdict.refused,
      );
    });

    test('the allowlist admits exactly its origins', () {
      const policy = OriginPolicy(allowlist: {'https://tools.example.org'});
      expect(
        policy.judge(
          origin: 'https://tools.example.org',
          host: 'mips.example.org',
        ),
        OriginVerdict.allowedCrossOrigin,
      );
      expect(
        policy.judge(
          origin: 'http://tools.example.org',
          host: 'mips.example.org',
        ),
        OriginVerdict.refused,
      );
    });

    test('loopback pages are allowed only when the policy says so', () {
      const dev = OriginPolicy(allowLoopback: true);
      expect(
        dev.judge(origin: 'http://localhost:54321', host: 'localhost:8082'),
        OriginVerdict.allowedCrossOrigin,
      );
      expect(
        dev.judge(origin: 'http://127.0.0.1:54321', host: 'localhost:8082'),
        OriginVerdict.allowedCrossOrigin,
      );
      expect(
        strict.judge(origin: 'http://localhost:54321', host: 'localhost:8082'),
        OriginVerdict.refused,
      );
      // Not a loopback host, even in development.
      expect(
        dev.judge(origin: 'http://evil.example', host: 'localhost:8082'),
        OriginVerdict.refused,
      );
    });
  });

  group('OriginPolicy.fromEnvironment', () {
    test('reads the allowlist and reports what it could not use', () {
      final rejected = <String>[];
      final policy = OriginPolicy.fromEnvironment(
        {
          OriginPolicy.allowedOriginsEnv:
              'https://Tools.example.org/, http://localhost:5000  *  nope',
        },
        runMode: 'production',
        rejected: rejected,
      );
      expect(policy.allowlist, {
        'https://tools.example.org',
        'http://localhost:5000',
      });
      expect(rejected, ['*', 'nope']);
      expect(policy.allowLoopback, isFalse);
    });

    test('allows loopback in development only', () {
      expect(
        OriginPolicy.fromEnvironment({}, runMode: 'development').allowLoopback,
        isTrue,
      );
      expect(
        OriginPolicy.fromEnvironment({}, runMode: 'staging').allowLoopback,
        isFalse,
      );
    });
  });

  group('apiRefusalStatus', () {
    test('POST and the preflight go through for allowed callers', () {
      for (final verdict in [
        OriginVerdict.noOrigin,
        OriginVerdict.sameOrigin,
        OriginVerdict.allowedCrossOrigin,
      ]) {
        expect(
          apiRefusalStatus(
            method: Method.post,
            path: '/project/list',
            verdict: verdict,
          ),
          isNull,
        );
        expect(
          apiRefusalStatus(
            method: Method.options,
            path: '/project/list',
            verdict: verdict,
          ),
          isNull,
        );
      }
    });

    test('any other method is a 405, whoever asks', () {
      for (final method in [
        Method.get,
        Method.head,
        Method.put,
        Method.delete,
        Method.patch,
      ]) {
        expect(
          apiRefusalStatus(
            method: method,
            path: '/project/deleteProject',
            verdict: OriginVerdict.noOrigin,
          ),
          405,
          reason: method.value,
        );
      }
    });

    test('the health probes stay readable with GET', () {
      for (final path in healthProbePaths) {
        expect(
          apiRefusalStatus(
            method: Method.get,
            path: path,
            verdict: OriginVerdict.noOrigin,
          ),
          isNull,
          reason: path,
        );
      }
    });

    test('a refused origin is a 403, preflight included', () {
      expect(
        apiRefusalStatus(
          method: Method.post,
          path: '/project/list',
          verdict: OriginVerdict.refused,
        ),
        403,
      );
      expect(
        apiRefusalStatus(
          method: Method.options,
          path: '/project/list',
          verdict: OriginVerdict.refused,
        ),
        403,
      );
    });
  });

  group('OriginGuard.withoutQuery', () {
    test('drops the query and keeps everything else', () {
      expect(
        OriginGuard.withoutQuery(
          Uri.parse('http://mips.example.org:9082/project/deleteProject?id=1'),
        ).toString(),
        'http://mips.example.org:9082/project/deleteProject',
      );
      expect(
        OriginGuard.withoutQuery(
          Uri.parse('/project/list?method=x'),
        ).toString(),
        '/project/list',
      );
    });

    test('leaves a URL without a query untouched', () {
      final url = Uri.parse('https://mips.example.org/project/list');
      expect(identical(OriginGuard.withoutQuery(url), url), isTrue);
    });
  });

  group('applyApiCors', () {
    Response withWildcard() => Response.ok(
      headers: Headers.build((h) {
        h['access-control-allow-origin'] = ['*'];
        h['vary'] = ['Accept-Encoding'];
      }),
    );

    test('echoes an allowed cross-origin caller', () {
      final out = applyApiCors(
        withWildcard(),
        verdict: OriginVerdict.allowedCrossOrigin,
        origin: 'http://localhost:54321',
      );
      expect(out.headers['access-control-allow-origin'], [
        'http://localhost:54321',
      ]);
      expect(out.headers['access-control-allow-credentials'], isNull);
      expect(out.headers['vary'], ['Accept-Encoding, Origin']);
    });

    test('never leaves a wildcard for anybody else', () {
      for (final verdict in [
        OriginVerdict.noOrigin,
        OriginVerdict.sameOrigin,
      ]) {
        final out = applyApiCors(
          withWildcard(),
          verdict: verdict,
          origin: null,
        );
        expect(out.headers['access-control-allow-origin'], isNull);
        expect(out.headers['vary'], ['Accept-Encoding, Origin']);
      }
    });
  });

  group('flowCookieMatches', () {
    test('only the same state matches', () {
      expect(flowCookieMatches('abc', 'abc'), isTrue);
      expect(flowCookieMatches('abc', 'abd'), isFalse);
      expect(flowCookieMatches(null, 'abc'), isFalse);
      expect(flowCookieMatches('', ''), isFalse);
    });
  });

  test('security headers carry no script policy', () {
    // A script CSP would need a project of its own for a Flutter web build.
    expect(
      securityResponseHeaders['content-security-policy'],
      "frame-ancestors 'none'",
    );
    expect(securityResponseHeaders['x-content-type-options'], 'nosniff');
  });
}
