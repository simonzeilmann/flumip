import 'package:flutter/foundation.dart' show kIsWeb;

/// Works out where the API and the site are from the page the app was loaded
/// from.
///
/// Every build is the same — release, staging and production alike — and none
/// of them knows its hostname: an install is a single origin, so the page's own
/// origin is the answer. That is what lets one bundle be installed anywhere,
/// directly or behind a reverse proxy, with nothing baked in at build time.

/// Fallback used off the web (unit tests, desktop debug runs) and by a local
/// `flutter run`, where the page origin says nothing about the server. The
/// development server's web port, which answers the API under [apiPath].
const String developmentApiUrl = 'http://localhost:8082/api/';

/// The web ports a FLUMIP install serves the app on: production, staging, and
/// the development server. See `flumip_server/config/*.yaml` and the config that
/// `deployment/setup-flumip.sh` generates.
const Set<int> installWebPorts = {9082, 8092, 8082};

/// Where the web server answers API calls, relative to its own origin.
///
/// The server serves the API a second time under this path on the web port
/// (`ApiRoute` in flumip_server), so an install is a single origin and a
/// reverse proxy in front of it needs one upstream.
const String apiPath = '/api/';

/// Whether [pageUrl] looks like a local `flutter run` rather than an install.
///
/// `flutter run -d chrome` serves the app on a port of its own, which is none of
/// [installWebPorts] and never the scheme's default. A localhost page on such a
/// port therefore means a development run, whose backend is the one described
/// by `flumip_server/config/development.yaml`. An install served on localhost
/// uses a known web port, or 80/443 behind a proxy, and is not caught here.
bool _isLocalDevPage(Uri pageUrl) {
  const localHosts = {'localhost', '127.0.0.1', '::1'};
  return localHosts.contains(pageUrl.host) &&
      pageUrl.hasPort &&
      !installWebPorts.contains(pageUrl.port);
}

/// Derives the API URL from the URL the app itself was loaded from.
///
/// Always the page's own origin plus [apiPath], whatever the port — directly on
/// 9082, or on 443 behind a TLS-terminating proxy. Before the web server
/// answered API calls itself this mapped 9082 to 9080, which no proxy on 443
/// could satisfy.
String apiUrlFor(Uri pageUrl) {
  if (_isLocalDevPage(pageUrl)) return developmentApiUrl;
  return Uri(
    scheme: pageUrl.scheme,
    host: pageUrl.host,
    port: pageUrl.port,
    path: apiPath,
  ).toString();
}

/// The API URL for this page, derived from its origin on web.
String resolveApiUrl() {
  if (!kIsWeb) return developmentApiUrl;
  return apiUrlFor(Uri.base);
}

/// Fallback used off the web. Matches the development web server's port.
const String developmentSiteUrl = 'http://localhost:8082';

/// The origin this app is served from, without a trailing slash.
///
/// UCSC custom-track links point back at this server's web port, so the port
/// is kept as-is — except during a local `flutter run`, where tracks are served
/// by the development backend rather than by the Flutter dev server hosting the
/// app.
String siteUrlFor(Uri pageUrl) {
  if (_isLocalDevPage(pageUrl)) return developmentSiteUrl;
  return Uri(
    scheme: pageUrl.scheme,
    host: pageUrl.host,
    port: pageUrl.port,
  ).toString();
}

/// The public URL for this page: its own origin on web.
String resolveSiteUrl() {
  if (!kIsWeb) return developmentSiteUrl;
  return siteUrlFor(Uri.base);
}

/// Whether a raw-body upload to the site origin can carry the session cookie.
///
/// True in every install, where the app is served by the web server itself, so
/// the `PUT /snp_upload/...` is same-origin: the browser attaches the HttpOnly
/// cookie by itself and there is no preflight.
///
/// ⚠️ **False during a `flutter run`**, which serves the app on its own port
/// while [resolveSiteUrl] points at the development backend. The upload then
/// becomes cross-origin, so the browser sends an `OPTIONS` preflight that a relic
/// `Route(methods: {Method.put})` does not answer — and the upload never starts,
/// reported as an opaque CORS error naming nothing useful.
///
/// This is the same structural limitation that already makes sign-in untestable
/// in that configuration; see the comments in `.vscode/launch.json`. The app
/// detects it and says so rather than failing mysteriously. **Importing by URL
/// still works there**, because that is an ordinary bearer-authenticated endpoint
/// call, which the API answers with permissive CORS headers — that keeps half
/// the development loop alive.
///
/// ⚠️ `Uri.origin` **throws** rather than returning null for a URL with no scheme
/// or host (a `file://` page, say), and the answer is computed in a top-level
/// `final`, so an unguarded call would take the whole app down at startup. Both
/// sides are guarded, and anything unusable answers "not same-origin", which
/// merely disables uploading.
bool uploadsAreSameOrigin(Uri pageUrl, String siteUrl) {
  final site = Uri.tryParse(siteUrl);
  if (site == null) return false;
  return _originOrNull(site) != null &&
      _originOrNull(site) == _originOrNull(pageUrl);
}

String? _originOrNull(Uri url) {
  if (url.scheme.isEmpty || url.host.isEmpty) return null;
  try {
    return url.origin;
  } catch (_) {
    return null;
  }
}

/// Whether this build can upload files to the server.
bool resolveUploadsAvailable() {
  if (!kIsWeb) return false;
  return uploadsAreSameOrigin(Uri.base, resolveSiteUrl());
}
