// Tests for the API URL resolution every build uses.
//
// No build knows its hostname, so the client works out the API address from
// the page origin at runtime. The web server answers API calls under /api
// itself, so that address is always the page's own origin — which is what lets
// one bundle work on any host, directly or behind a reverse proxy.

import 'package:flumip_flutter/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('apiUrlFor', () {
    test('calls /api on the production web port itself', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:9082/')),
        'http://mips.example.org:9082/api/',
      );
    });

    test('calls /api on the staging web port itself', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:8092/')),
        'http://mips.example.org:8092/api/',
      );
    });

    test('stays on the page origin behind a TLS-terminating proxy', () {
      // The case the old 9082 -> 9080 port mapping could not serve: on 443
      // there is no second port to map to, and a proxy should need only one
      // upstream.
      expect(
        apiUrlFor(Uri.parse('https://mips.example.org/')),
        'https://mips.example.org/api/',
      );
    });

    test('keeps a non-standard proxy port', () {
      expect(
        apiUrlFor(Uri.parse('https://mips.example.org:8443/')),
        'https://mips.example.org:8443/api/',
      );
    });

    test('points a local flutter run at the development backend', () {
      // `flutter run -d chrome` serves the app on its own port, so the page
      // port says nothing about where the API is.
      expect(apiUrlFor(Uri.parse('http://localhost:8083/')), developmentApiUrl);
      expect(
        apiUrlFor(Uri.parse('http://127.0.0.1:54321/')),
        developmentApiUrl,
      );
    });

    test('treats a known web port on localhost as an install', () {
      // setup-flumip.sh defaults to --host localhost, which must keep working.
      expect(
        apiUrlFor(Uri.parse('http://localhost:9082/')),
        'http://localhost:9082/api/',
      );
    });

    test(
      'treats localhost behind a proxy on the default port as an install',
      () {
        // No `flutter run` ever serves on 80 or 443.
        expect(
          apiUrlFor(Uri.parse('https://localhost/')),
          'https://localhost/api/',
        );
      },
    );

    test('drops any path from the page URL', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:9082/projects/7')),
        'http://mips.example.org:9082/api/',
      );
    });
  });

  group('siteUrlFor', () {
    test('keeps the web port, since tracks are served by this server', () {
      expect(
        siteUrlFor(Uri.parse('http://mips.example.org:9082/')),
        'http://mips.example.org:9082',
      );
    });

    test('omits a default port so links stay clean behind a proxy', () {
      expect(
        siteUrlFor(Uri.parse('https://mips.example.org/')),
        'https://mips.example.org',
      );
    });

    test('points a local flutter run at the development web server', () {
      // Tracks are served by flumip_server, not by the Flutter dev server.
      expect(
        siteUrlFor(Uri.parse('http://localhost:8083/')),
        developmentSiteUrl,
      );
    });

    test('has no trailing slash, as callers append a path', () {
      // Used as '$siteUrl/ucsc_track/<token>' in project_result_actions.dart.
      expect(
        siteUrlFor(Uri.parse('http://localhost:9082/')),
        isNot(endsWith('/')),
      );
    });
  });

  group('resolveApiUrl', () {
    test('uses the development fallback off the web', () {
      // Unit tests run on the VM, where there is no page origin to derive from.
      expect(resolveApiUrl(), developmentApiUrl);
    });
  });

  group('developmentApiUrl', () {
    test('is the development web port, which answers the API under /api', () {
      // Nothing talks to the API port directly any more; a local `flutter run`
      // goes through the web server like every install does.
      expect(developmentApiUrl, '$developmentSiteUrl$apiPath');
    });
  });

  group('resolveSiteUrl', () {
    test('uses the development fallback off the web', () {
      expect(resolveSiteUrl(), developmentSiteUrl);
    });
  });

  group('uploadsAreSameOrigin', () {
    test('an install is same-origin, so the cookie travels', () {
      // The app is served by the web server itself, which is where the session
      // cookie lives — the whole reason a raw PUT can be authorized at all.
      expect(
        uploadsAreSameOrigin(
          Uri.parse('https://flumip.uni.example/'),
          'https://flumip.uni.example',
        ),
        isTrue,
      );
    });

    test('a path on the page does not matter, only the origin', () {
      expect(
        uploadsAreSameOrigin(
          Uri.parse('https://flumip.uni.example/some/deep/link'),
          'https://flumip.uni.example',
        ),
        isTrue,
      );
    });

    test('a localhost install on a matching port is same-origin', () {
      expect(
        uploadsAreSameOrigin(
          Uri.parse('http://localhost:8082/'),
          'http://localhost:8082',
        ),
        isTrue,
      );
    });

    test('a flutter run is NOT same-origin', () {
      // ⚠️ The case this exists for. `flutter run` serves the app on 8083 while
      // resolveSiteUrl points at the development backend on 8082, so the PUT is
      // cross-origin, preflights, and never starts. Same structural reason
      // sign-in cannot be tested there.
      expect(
        uploadsAreSameOrigin(
          Uri.parse('http://localhost:8083/'),
          'http://localhost:8082',
        ),
        isFalse,
      );
    });

    test('a different scheme is not the same origin', () {
      expect(
        uploadsAreSameOrigin(
          Uri.parse('http://flumip.uni.example/'),
          'https://flumip.uni.example',
        ),
        isFalse,
      );
    });

    test('a different host is not the same origin', () {
      expect(
        uploadsAreSameOrigin(
          Uri.parse('https://flumip.uni.example/'),
          'https://other.uni.example',
        ),
        isFalse,
      );
    });

    test('an unparseable site URL is not treated as same-origin', () {
      expect(
        uploadsAreSameOrigin(Uri.parse('https://flumip.uni.example/'), ''),
        isFalse,
      );
    });

    test('a malformed site URL does not crash the app', () {
      // ⚠️ resolveUploadsAvailable runs in a top-level `final`, so a throw here
      // would take the whole app down at startup rather than merely disabling
      // uploading. The site URL is derived from the page address today, but
      // this guard is what keeps a bad one from ever being fatal.
      for (final bad in ['', '   ', 'not a url', '://nope', 'flumip.example']) {
        expect(
          () => uploadsAreSameOrigin(Uri.parse('https://x.example/'), bad),
          returnsNormally,
          reason: 'site URL "$bad"',
        );
        expect(
          uploadsAreSameOrigin(Uri.parse('https://x.example/'), bad),
          isFalse,
        );
      }
    });

    test('a page URL with no origin is handled too', () {
      expect(
        uploadsAreSameOrigin(Uri.parse('about:blank'), 'https://x.example'),
        isFalse,
      );
    });
  });
}
