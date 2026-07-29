// Tests for the API URL resolution used by release builds.
//
// Release tarballs are built without --dart-define=API_URL, so the client has
// to work out the API address from the page origin at runtime. These tests pin
// the port mapping that makes one prebuilt bundle usable on any host.

import 'package:flumip_flutter/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('apiUrlFor', () {
    test('maps the production web port to the production API port', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:9082/')),
        'http://mips.example.org:9080/',
      );
    });

    test('maps the staging web port to the staging API port', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:8092/')),
        'http://mips.example.org:8090/',
      );
    });

    test('preserves the host when serving from localhost', () {
      expect(
        apiUrlFor(Uri.parse('http://localhost:9082/')),
        'http://localhost:9080/',
      );
    });

    test('keeps the scheme so an https page reaches an https API', () {
      expect(
        apiUrlFor(Uri.parse('https://mips.example.org:9082/')),
        'https://mips.example.org:9080/',
      );
    });

    test('falls back to the page port for a same-origin reverse proxy', () {
      // Port 443 is not a known web server port, so the API is assumed to be
      // proxied on the same origin rather than shifted to another port.
      expect(
        apiUrlFor(Uri.parse('https://mips.example.org/')),
        'https://mips.example.org/',
      );
    });

    test('points a local flutter run at the development backend', () {
      // `flutter run -d chrome` serves the app on its own port, so the page
      // port says nothing about where the API is.
      expect(
        apiUrlFor(Uri.parse('http://localhost:8083/')),
        developmentApiUrl,
      );
      expect(
        apiUrlFor(Uri.parse('http://127.0.0.1:54321/')),
        developmentApiUrl,
      );
    });

    test('still maps a known web port on localhost, for a local install', () {
      // setup-flumip.sh defaults to --host localhost, which must keep working.
      expect(
        apiUrlFor(Uri.parse('http://localhost:9082/')),
        'http://localhost:9080/',
      );
    });

    test('drops any path from the page URL', () {
      expect(
        apiUrlFor(Uri.parse('http://mips.example.org:9082/projects/7')),
        'http://mips.example.org:9080/',
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
      // Used as '$siteUrl/ucsc_track/<id>' in project_tile.dart.
      expect(siteUrlFor(Uri.parse('http://localhost:9082/')), isNot(endsWith('/')));
    });
  });

  group('resolveApiUrl', () {
    test('uses the development fallback off the web', () {
      // Unit tests run on the VM, where there is no page origin to derive from.
      // CI's deploy builds pass --dart-define=API_URL, which takes precedence
      // over both branches; that path cannot be exercised from a test.
      expect(apiUrlOverride, isEmpty);
      expect(resolveApiUrl(), developmentApiUrl);
    });
  });

  group('resolveSiteUrl', () {
    test('uses the development fallback off the web', () {
      expect(siteUrlOverride, isEmpty);
      expect(resolveSiteUrl(), developmentSiteUrl);
    });
  });
}
