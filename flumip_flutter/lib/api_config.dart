import 'package:flutter/foundation.dart' show kIsWeb;

/// Resolves the Serverpod API URL the client should talk to.
///
/// CI passes `--dart-define=API_URL=...` for the staging and production
/// deploys, and that always wins. Release builds published to GitHub Releases
/// cannot know the end user's hostname at compile time, so they omit the define
/// and the URL is derived from the page the app was served from instead — which
/// lets one prebuilt bundle work on any host.
const String apiUrlOverride = String.fromEnvironment('API_URL');

/// Fallback used off the web (unit tests, desktop debug runs) where there is no
/// page origin to derive from. Matches the development server's API port.
const String developmentApiUrl = 'http://localhost:8080/';

/// Maps the web server port to the API server port on the same host.
///
/// Serverpod serves the Flutter app and the API from two different ports; see
/// `flumip_server/config/production.yaml` and `staging.yaml`, and the config
/// that `deployment/setup-flumip.sh` generates.
const Map<int, int> webToApiPort = {
  9082: 9080, // production
  8092: 8090, // staging
};

/// Whether [pageUrl] looks like a local `flutter run` rather than an install.
///
/// `flutter run -d chrome` serves the app on its own port, which is neither an
/// API port nor one of [webToApiPort]. A localhost page on an unrecognised port
/// therefore means a development run, where the backend is the one described by
/// `flumip_server/config/development.yaml`. An install served on localhost uses
/// a known web port and is matched by [webToApiPort] instead.
bool _isLocalDevPage(Uri pageUrl) {
  const localHosts = {'localhost', '127.0.0.1', '::1'};
  return localHosts.contains(pageUrl.host) &&
      !webToApiPort.containsKey(pageUrl.port);
}

/// Derives the API URL from the URL the app itself was loaded from.
///
/// Falls back to the page's own port for anything not in [webToApiPort] — for
/// example a reverse proxy that routes the API on the same origin. A proxy that
/// does not do that needs an explicit `--dart-define=API_URL` build.
String apiUrlFor(Uri pageUrl) {
  if (_isLocalDevPage(pageUrl)) return developmentApiUrl;
  return Uri(
    scheme: pageUrl.scheme,
    host: pageUrl.host,
    port: webToApiPort[pageUrl.port] ?? pageUrl.port,
    path: '/',
  ).toString();
}

/// The API URL for this build: the compile-time override when one was given,
/// otherwise derived from the page origin on web.
String resolveApiUrl() {
  if (apiUrlOverride.isNotEmpty) return apiUrlOverride;
  if (!kIsWeb) return developmentApiUrl;
  return apiUrlFor(Uri.base);
}

/// Public URL of this app, baked in at build time by the CI deploys.
const String siteUrlOverride = String.fromEnvironment('SITE_URL');

/// Fallback used off the web. Matches the development web server's port.
const String developmentSiteUrl = 'http://localhost:8082';

/// The origin this app is served from, without a trailing slash.
///
/// UCSC custom-track links point back at this server's web port, so unlike
/// [apiUrlFor] the port is kept as-is — except during a local `flutter run`,
/// where tracks are served by the development backend rather than by the
/// Flutter dev server hosting the app.
String siteUrlFor(Uri pageUrl) {
  if (_isLocalDevPage(pageUrl)) return developmentSiteUrl;
  return Uri(
    scheme: pageUrl.scheme,
    host: pageUrl.host,
    port: pageUrl.port,
  ).toString();
}

/// The public URL for this build: the compile-time override when one was given,
/// otherwise the page's own origin on web.
String resolveSiteUrl() {
  if (siteUrlOverride.isNotEmpty) return siteUrlOverride;
  if (!kIsWeb) return developmentSiteUrl;
  return siteUrlFor(Uri.base);
}
