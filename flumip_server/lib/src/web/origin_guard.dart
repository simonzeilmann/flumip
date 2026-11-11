import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:serverpod/serverpod.dart';

/// Decides whether a request may have come from a page on another site, and
/// refuses the ones that did.
///
/// ## Why this exists
///
/// On a default install there is no sign-in: everybody who can reach the server
/// is trusted. Serverpod's defaults answered every API response with
/// `Access-Control-Allow-Origin: *` and dispatched any HTTP method, with query
/// parameters merged into the call's arguments. Together that meant any web page
/// a user on the network happened to open could drive the API through that
/// user's browser — an `<img src=".../api/project/deleteProject?id=1">` was
/// enough, and so was a "simple" cross-origin `POST`, which the browser sends
/// without asking first. CORS only stops a page from *reading* the answer; it
/// does nothing about the request having been carried out.
///
/// The same applies to the cookie routes under `/auth`: a cross-site form could
/// sign a visitor out, or accept a public instance's terms on their behalf.
///
/// ## The decision
///
/// Made from the request headers alone, by the pure [OriginPolicy.judge], so it
/// is unit-testable without a server:
///
/// - **No `Origin`** — curl, scripts, the UCSC fetcher, anything that is not a
///   browser running somebody's page — is let through, unless the browser's own
///   `Sec-Fetch-Site` says the request came from another site. Browsers always
///   send `Origin` on a `POST`, so for state-changing calls this case is the
///   non-browser one.
/// - **The app's own origin** is allowed: the configured public URL
///   (`FLUMIP_PUBLIC_URL` or the web server's public address), or whatever host
///   the request itself was addressed to (`Host`, or `X-Forwarded-Host` from a
///   proxy). The second is what keeps an install reached by IP address, by a
///   short name and by its full name working without configuring each.
/// - **[OriginPolicy.allowedOriginsEnv]**, a comma-separated list, adds other
///   origins that may call the API cross-origin.
/// - **In development only**, any `http://localhost:<port>` page may call the
///   API, because `flutter run` serves the app on a port of its own (see
///   `flumip_flutter/lib/api_config.dart`).
/// - Everything else — including the literal `Origin: null` that sandboxed
///   frames and `file://` pages send — is refused.
///
/// ⚠️ Matching the request's own `Host` means this does **not** defend against
/// DNS rebinding, where an attacker's name is re-pointed at the server and the
/// browser considers the attack page same-origin. Nothing on the CORS side can;
/// only checking `Host` against a fixed list of names would, and that breaks
/// every install reached by more than one name.
enum OriginVerdict {
  /// No `Origin` header, and nothing else suggesting another site.
  noOrigin,

  /// The page is the app itself.
  sameOrigin,

  /// Another origin that is allowed to call the API: the allowlist, or a local
  /// `flutter run` in development. Gets CORS headers on the API, but not the
  /// cookie routes.
  allowedCrossOrigin,

  /// Anything else.
  refused,
}

/// The configured part of the decision: which other origins are allowed.
class OriginPolicy {
  const OriginPolicy({
    this.allowlist = const <String>{},
    this.allowLoopback = false,
  });

  /// Comma- or whitespace-separated origins that may call the API cross-origin,
  /// e.g. `https://tools.example.org, http://localhost:5000`.
  static const allowedOriginsEnv = 'FLUMIP_ALLOWED_ORIGINS';

  /// Builds the policy the running server uses.
  ///
  /// Entries that are not origins (a path, no scheme, `*`) are dropped rather
  /// than failing the boot, and returned in [rejected] so the caller can log
  /// them: a typo here must not stop the server, but must not pass silently
  /// either.
  factory OriginPolicy.fromEnvironment(
    Map<String, String> environment, {
    required String runMode,
    List<String>? rejected,
  }) {
    final raw = environment[allowedOriginsEnv] ?? '';
    final allowlist = <String>{};
    for (final entry in raw.split(RegExp(r'[\s,]+'))) {
      if (entry.isEmpty) continue;
      final normalized = normalizeOrigin(entry);
      if (normalized == null) {
        rejected?.add(entry);
      } else {
        allowlist.add(normalized);
      }
    }
    return OriginPolicy(
      allowlist: allowlist,
      allowLoopback: runMode == 'development',
    );
  }

  /// Normalized origins (see [normalizeOrigin]) allowed in addition to the
  /// app's own.
  final Set<String> allowlist;

  /// Whether any `http://localhost:<port>` page is allowed. Development only.
  final bool allowLoopback;

  static const _loopbackHosts = {'localhost', '127.0.0.1', '[::1]', '::1'};

  /// The verdict for a request with these headers.
  ///
  /// [appOrigin] is the configured public URL, empty when unknown. [host] and
  /// [forwardedHost] are the request's `Host` and `X-Forwarded-Host` headers.
  OriginVerdict judge({
    required String? origin,
    String? secFetchSite,
    String? host,
    String? forwardedHost,
    String appOrigin = '',
  }) {
    if (origin == null || origin.trim().isEmpty) {
      // `same-site` is refused too: a page on a sibling subdomain is not the
      // app, and a browser that sends Sec-Fetch-Site but no Origin is doing a
      // navigation or a no-cors GET, which is never how the app calls anything.
      final site = secFetchSite?.trim().toLowerCase();
      return site == 'cross-site' || site == 'same-site'
          ? OriginVerdict.refused
          : OriginVerdict.noOrigin;
    }

    final normalized = normalizeOrigin(origin);
    if (normalized == null) return OriginVerdict.refused;

    if (normalized == normalizeOrigin(appOrigin)) {
      return OriginVerdict.sameOrigin;
    }
    final parsed = Uri.parse(normalized);
    if (_sameAuthority(parsed, host) ||
        _sameAuthority(parsed, _firstListValue(forwardedHost))) {
      return OriginVerdict.sameOrigin;
    }
    if (allowlist.contains(normalized)) return OriginVerdict.allowedCrossOrigin;
    if (allowLoopback &&
        parsed.scheme == 'http' &&
        _loopbackHosts.contains(parsed.host)) {
      return OriginVerdict.allowedCrossOrigin;
    }
    return OriginVerdict.refused;
  }

  /// Whether [origin] names the same host and port as a `Host` header value.
  ///
  /// The scheme is not compared, because behind a TLS-terminating proxy the
  /// browser is on `https` while the request reaching us is plain `http`. A
  /// `Host` with no port means the default port of whichever scheme the browser
  /// used, which is the origin's.
  static bool _sameAuthority(Uri origin, String? hostHeader) {
    if (hostHeader == null) return false;
    final value = hostHeader.trim().toLowerCase();
    if (value.isEmpty) return false;
    final Uri host;
    try {
      host = Uri.parse('${origin.scheme}://$value');
    } on FormatException {
      return false;
    }
    if (host.host != origin.host) return false;
    // Uri fills in the scheme's default port when none is given, on both sides.
    return host.port == origin.port;
  }

  static String? _firstListValue(String? header) {
    if (header == null) return null;
    final first = header.split(',').first.trim();
    return first.isEmpty ? null : first;
  }
}

/// [raw] as a canonical origin — lowercase `scheme://host[:port]` with the
/// default port and any trailing slash dropped — or null if it is not one.
///
/// Only `http` and `https` count. `null` (the string), anything with a path,
/// query, fragment or user info, and anything unparseable is not an origin.
String? normalizeOrigin(String raw) {
  var value = raw.trim().toLowerCase();
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  if (value.isEmpty) return null;
  final Uri uri;
  try {
    uri = Uri.parse(value);
  } on FormatException {
    return null;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.path.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  final isDefaultPort =
      (uri.scheme == 'https' && uri.port == 443) ||
      (uri.scheme == 'http' && uri.port == 80);
  // `Uri.host` drops the brackets around an IPv6 literal; put them back.
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  return isDefaultPort
      ? '${uri.scheme}://$host'
      : '${uri.scheme}://$host:${uri.port}';
}

/// What [ApiRoute] and the API port do with a request, as an HTTP status: null
/// to let it through, otherwise the status to refuse it with.
///
/// - Only `POST` reaches an endpoint, plus the `OPTIONS` preflight. The
///   generated client sends nothing else, there is no streaming, and a `GET`
///   that changes state is exactly what an image tag can trigger. The one
///   exception is the read-only health probes.
/// - Then the origin: anything [OriginVerdict.refused] gets a 403, preflight
///   included, so the browser never sends the real request.
int? apiRefusalStatus({
  required Method method,
  required String path,
  required OriginVerdict verdict,
}) {
  final isHealthProbe =
      (method == Method.get || method == Method.head) &&
      healthProbePaths.contains(path);
  if (method != Method.post && method != Method.options && !isHealthProbe) {
    return 405;
  }
  if (verdict == OriginVerdict.refused) return 403;
  return null;
}

/// Serverpod's read-only health routes on the API router: the legacy `GET /`
/// and the Kubernetes-style probes. Paths are relative to the API root.
const healthProbePaths = {'/', '/livez', '/readyz', '/startupz'};

/// [OriginPolicy] wired to a live request and to the configured public URL.
///
/// One instance, [current], set up in `server.dart` before the server starts.
/// A global rather than a constructor argument so that a route can use it
/// without `server.dart` having to thread it through every constructor.
class OriginGuard {
  OriginGuard(this.policy, {String Function()? appOrigin})
    : _appOrigin = appOrigin ?? _configuredAppOrigin;

  /// The guard every route uses. Strict until `server.dart` configures it: no
  /// allowlist, no development loopback.
  static OriginGuard current = OriginGuard(const OriginPolicy());

  final OriginPolicy policy;
  final String Function() _appOrigin;

  /// Read per request, since an admin can change the public URL in Settings.
  static String _configuredAppOrigin() {
    try {
      return sl<AuthRuntime>().config.appOrigin;
    } catch (_) {
      // Not registered (a unit test, say): the Host comparison still works.
      return '';
    }
  }

  /// The verdict for [request].
  OriginVerdict judge(Request request) {
    final headers = request.headers;
    return policy.judge(
      origin: _header(headers, HeaderName.origin),
      secFetchSite: _header(headers, HeaderName.secFetchSite),
      host: _header(headers, HeaderName.host),
      forwardedHost: _header(headers, 'x-forwarded-host'),
      appOrigin: _appOrigin(),
    );
  }

  /// For the browser-only cookie routes (`/auth/guest`, `/auth/logout`, the SNP
  /// upload): a 403 unless [request] came from the app itself or from no page at
  /// all; null to let it through.
  ///
  /// Stricter than the API: an allowlisted origin is refused here too. These
  /// routes set or use the session cookie, which only ever belongs to the app's
  /// own origin, so no other page has a legitimate reason to call them.
  Response? refuseUnlessSameOrigin(Request request) {
    final verdict = judge(request);
    if (verdict == OriginVerdict.sameOrigin ||
        verdict == OriginVerdict.noOrigin) {
      return null;
    }
    return crossOriginRefusal();
  }

  /// The 403 every origin refusal answers with.
  static Response crossOriginRefusal() => Response.forbidden(
    body: Body.fromString(
      'This request came from a page on another site, so it was refused. '
      'Open FLUMIP itself and try again from there.',
      mimeType: MimeType.plainText,
    ),
  );

  /// The 405 for a method the API does not accept.
  static Response methodRefusal() => Response(
    405,
    body: Body.fromString(
      'The API only accepts POST requests.',
      mimeType: MimeType.plainText,
    ),
    headers: Headers.build((h) => h['allow'] = ['POST, OPTIONS']),
  );

  /// Middleware for Serverpod's own API port (`apiServer`).
  ///
  /// Nothing legitimate calls that port from a browser — every build calls
  /// `/api` on the web port — but it is bound to every interface, so it gets the
  /// same method and origin rules. It gets no CORS headers at all: with the
  /// wildcard gone from `httpResponseHeaders`, a browser cannot read from it.
  ///
  /// ⚠️ Serverpod's own header middleware is registered first, so it is the
  /// outer one and answers every `OPTIONS` itself before this runs. That is
  /// harmless (it dispatches nothing), and without an
  /// `Access-Control-Allow-Origin` in the answer the preflight fails.
  Middleware get apiPortMiddleware =>
      (next) => (request) {
        final refusal = apiRefusal(request);
        if (refusal != null) return refusal;
        return next(request.copyWith(url: withoutQuery(request.url)));
      };

  /// The refusal for an API request, or null to let it through.
  Response? apiRefusal(Request request) => refusalFor(
    apiRefusalStatus(
      method: request.method,
      path: request.url.path,
      verdict: judge(request),
    ),
  );

  /// The response for an [apiRefusalStatus] result.
  static Response? refusalFor(int? status) => switch (status) {
    null => null,
    405 => methodRefusal(),
    _ => crossOriginRefusal(),
  };

  /// [url] with its query string removed.
  ///
  /// Serverpod merges query parameters into the call's arguments, over the
  /// body's. The client never sends any, so dropping them makes the JSON body
  /// the only place arguments come from, and a URL alone can never carry a call.
  static Uri withoutQuery(Uri url) => url.hasQuery
      ? Uri(
          scheme: url.scheme.isEmpty ? null : url.scheme,
          userInfo: url.userInfo.isEmpty ? null : url.userInfo,
          host: url.hasAuthority ? url.host : null,
          port: url.hasPort ? url.port : null,
          path: url.path,
        )
      : url;

  static String? _header(Headers headers, Object name) {
    final values = headers[name];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }
}

/// Headers added to every web server response that has not set its own.
///
/// - `X-Content-Type-Options: nosniff` — a downloaded result file or an
///   uploaded SNP set is never reinterpreted as a script or a page.
/// - `X-Frame-Options: DENY` and `Content-Security-Policy: frame-ancestors
///   'none'` — no other site can frame the app and trick a click through it.
///   The app never frames itself. The CSP carries nothing else on purpose: a
///   real script policy for a Flutter web build is a project of its own.
/// - `Referrer-Policy: same-origin` — nothing about the app's URLs leaks to
///   other sites. Nothing relies on the referrer.
///
/// None of these affect the UCSC genome browser, which fetches tracks
/// server-side.
const securityResponseHeaders = <String, String>{
  'x-content-type-options': 'nosniff',
  'x-frame-options': 'DENY',
  'content-security-policy': "frame-ancestors 'none'",
  'referrer-policy': 'same-origin',
};

/// Middleware adding [securityResponseHeaders].
Handler securityHeadersMiddleware(Handler next) => (request) async {
  final result = await next(request);
  if (result is! Response) return result;
  return result.copyWith(
    headers: result.headers.transform((h) {
      for (final entry in securityResponseHeaders.entries) {
        h[entry.key] ??= [entry.value];
      }
    }),
  );
};

/// Applies the CORS answer for [verdict] to an API [response].
///
/// Echoes [origin] for an allowed cross-origin caller and removes
/// `Access-Control-Allow-Origin` for everybody else — whatever Serverpod's
/// header middleware put there. Never `Allow-Credentials`: the API authenticates
/// with a bearer header, not a cookie. `Vary: Origin` always, so a shared cache
/// cannot hand one caller's answer to another.
Response applyApiCors(
  Response response, {
  required OriginVerdict verdict,
  required String? origin,
}) {
  return response.copyWith(
    headers: response.headers.transform((h) {
      final normalized = origin == null ? null : normalizeOrigin(origin);
      h['access-control-allow-origin'] =
          verdict == OriginVerdict.allowedCrossOrigin && normalized != null
          ? [origin!.trim()]
          : null;
      final vary = (h['vary'] ?? const <String>[])
          .expand((v) => v.split(','))
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
      if (!vary.any((v) => v == '*' || v.toLowerCase() == 'origin')) {
        vary.add('Origin');
      }
      h['vary'] = [vary.join(', ')];
    }),
  );
}
