import 'dart:convert';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/password_hash.dart';
import 'package:flumip_server/src/web/origin_guard.dart';
import 'package:serverpod/serverpod.dart';

/// Name of the session cookie.
///
/// Prefixed so it cannot collide with anything else served from the same host,
/// which matters when FLUMIP shares a domain with another application behind the
/// same reverse proxy.
const authCookieName = 'flumip_auth';

/// Name of the cookie binding a sign-in to the browser that started it.
///
/// Holds the flow's `state`, scoped to `/auth/callback` and living only as long
/// as the flow does. See [AuthLoginRoute] for why it exists.
const authFlowCookieName = 'flumip_auth_flow';

/// The routes that make up the sign-in flow, run by the *web* server.
///
/// Doing the whole OIDC round trip here rather than in the Flutter app is what
/// keeps the client secret on the server, keeps the ID token out of the browser,
/// and lets the durable credential be an `HttpOnly` cookie instead of something
/// in `localStorage`. The app never sees a provider token; it trades the cookie
/// for a short-lived bearer at [AuthSessionRoute].
///
/// This works because the app is always same-origin with the web server — every
/// build is published into `web/app` and served by `FlutterRoute`, and the API
/// is answered there too, under `/api`. API calls nonetheless authenticate with
/// an `Authorization` header rather than the cookie; see `AuthApiToken` for why.

/// Reads the session cookie from a request, tolerating a malformed header.
///
/// `CookieHeader.parse` throws on, for example, duplicate cookie names — which
/// can be caused by an unrelated cookie set elsewhere on the domain. That must
/// not break signing in, so parse failures are treated as "no cookie".
String? _readAuthCookie(Request request) =>
    _readCookie(request, authCookieName);

String? _readCookie(Request request, String name) {
  final header = _cookieHeaderOrNull(request);
  return header?.getCookie(name)?.value;
}

/// The parsed `Cookie` header, or null when it is absent or does not parse.
///
/// Relic 2.0.0-rc.3 dropped `getValueFrom(orElse:)`; `headers(accessor)` throws
/// an `InvalidHeaderException` on a header it cannot decode.
CookieHeader? _cookieHeaderOrNull(Request request) {
  try {
    return request.headers(Headers.cookie);
  } on Exception {
    return null;
  }
}

Headers _cookieHeaders({
  required String value,
  required bool secure,
  required Duration maxAge,
  String name = authCookieName,
  String path = '/',
}) => Headers.build(
  (h) => h.setCookie = _setCookie(
    value: value,
    secure: secure,
    maxAge: maxAge,
    name: name,
    path: path,
  ),
);

SetCookieHeader _setCookie({
  required String value,
  required bool secure,
  required Duration maxAge,
  String name = authCookieName,
  String path = '/',
}) {
  // Relic 2 split the type: `SetCookie` is one cookie, `SetCookieHeader` is the
  // list of them the response header carries — one `Set-Cookie` line each. This
  // must stay a single-element list; two lines would have the second parsed as a
  // nameless cookie, and an empty list would emit no header at all, which looks
  // exactly like a cancelled sign-in. `path` also went from `Uri` to `String`,
  // which is what it always was — `Uri.parse('/')` was a round trip for nothing.
  return SetCookieHeader([
    SetCookie(
      name: name,
      value: value,
      path: path,
      httpOnly: true,
      // Never readable from JavaScript, so an XSS in the app cannot exfiltrate
      // the durable credential.
      secure: secure,
      // Lax rather than Strict: the cookie is set on the redirect back from the
      // identity provider, which is a cross-site navigation. Strict would drop
      // it and sign-in would silently do nothing.
      sameSite: SameSite.lax,
      maxAge: maxAge.inSeconds,
    ),
  ]);
}

/// `GET /auth/login` — starts the flow and redirects to the provider.
///
/// Also sets [authFlowCookieName] to the flow's `state`, which
/// [AuthCallbackRoute] insists on seeing again. Without it a flow was bound to
/// nothing but its URL: somebody could start a sign-in in their own browser,
/// stop at the redirect back, and send the callback link to a colleague, who
/// would then be signed in **as them** — and whatever that colleague uploaded
/// would land in the other person's account ("login CSRF"). With it, a callback
/// only completes in the browser that started the flow.
///
/// A GET, and safe as one: it signs nobody in and changes nothing but a
/// short-lived row and cookie.
class AuthLoginRoute extends Route {
  AuthLoginRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final authService = sl<AuthService>();
    // Opportunistic housekeeping: cheap, and it keeps the flow table from
    // accumulating abandoned rows without needing a scheduled job.
    await authService.pruneExpired(session);

    try {
      final url = await authService.beginFlow(session);
      final state = url.queryParameters['state'];
      if (state == null || state.isEmpty) return Response.seeOther(url);
      return Response.seeOther(
        url,
        headers: _cookieHeaders(
          name: authFlowCookieName,
          value: state,
          // Scoped to the callback, so it is not sent anywhere else.
          path: '/auth/callback',
          secure: sl<AuthRuntime>().config.cookieSecure,
          maxAge: AuthService.flowLifetime,
        ),
      );
    } on AuthFlowException catch (e) {
      session.log(
        'Could not start a sign-in: ${e.message}',
        level: LogLevel.warning,
      );
      // 503 rather than 500: this is "not available", and the message is written
      // for whoever is looking at the screen.
      return Response(
        503,
        body: Body.fromString(e.message, mimeType: MimeType.plainText),
      );
    }
  }
}

/// `GET /auth/callback` — completes the flow, sets the cookie, returns to the app.
class AuthCallbackRoute extends Route {
  AuthCallbackRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final query = request.url.queryParameters;

    // The provider reports refusals here, e.g. access_denied when someone
    // cancels at the consent screen.
    final error = query['error'];
    if (error != null) {
      final description = query['error_description'] ?? '';
      session.log(
        'The identity provider refused the sign-in: $error '
        '$description',
      );
      return Response.badRequest(
        body: Body.fromString(
          'The identity provider refused this sign-in: $error'
          '${description.isEmpty ? '' : '\n$description'}',
          mimeType: MimeType.plainText,
        ),
      );
    }

    final code = query['code'];
    final state = query['state'];
    if (code == null || state == null) {
      return Response.badRequest(
        body: Body.fromString(
          'This callback URL is missing the code or state parameter. It is not '
          'meant to be opened directly — start at /auth/login.',
          mimeType: MimeType.plainText,
        ),
      );
    }

    final config = sl<AuthRuntime>().config;

    // See AuthLoginRoute. Checked before the flow is looked up, so a callback
    // opened in the wrong browser does not use up the flow it names.
    if (!flowCookieMatches(_readCookie(request, authFlowCookieName), state)) {
      session.log(
        'Refused a sign-in callback that this browser did not start.',
        level: LogLevel.warning,
      );
      return Response.forbidden(
        body: Body.fromString(
          'This sign-in was not started in this browser, or it took too long. '
          'Start again from the sign-in button.',
          mimeType: MimeType.plainText,
        ),
      );
    }

    try {
      final result = await sl<AuthService>().completeCallback(
        session,
        code: code,
        state: state,
      );
      // Redirect to the app rather than rendering anything, so the browser ends
      // up on a clean URL with no code or state left in the address bar or in
      // the session history.
      return Response.seeOther(
        Uri.parse('/'),
        headers: _cookieHeaders(
          value: result.cookieValue,
          // Derived from the public scheme, never hard-coded: a Secure cookie on
          // a plain-HTTP install is silently dropped by the browser and sign-in
          // looks like a no-op with no error anywhere.
          secure: config.cookieSecure,
          maxAge: AuthService.sessionLifetime,
        ),
      );
    } on AuthFlowException catch (e) {
      session.log(
        'A sign-in could not be completed: ${e.message}',
        level: LogLevel.warning,
      );
      return Response.forbidden(
        body: Body.fromString(e.message, mimeType: MimeType.plainText),
      );
    }
  }
}

/// `GET /auth/session` — trades the cookie for a short-lived API bearer.
///
/// Same-origin with the app, so the browser sends the cookie automatically and
/// the app never has to hold the durable credential itself.
class AuthSessionRoute extends Route {
  AuthSessionRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final cookie = _readAuthCookie(request);
    if (cookie == null) {
      return _noSession('There is no sign-in cookie on this request.');
    }

    final IssuedApiToken? issued;
    try {
      issued = await sl<AuthService>().issueApiToken(session, cookie);
    } on TermsNotAcceptedException {
      return _noSession(
        'The terms of use have changed since you last accepted them.',
      );
    }
    if (issued == null) {
      return _noSession('This sign-in has expired or was signed out.');
    }
    return _tokenResponse(issued, renewCookie: issued.isGuest ? cookie : null);
  }

  /// A 401 that, on a public instance, also tells the app to show the entry
  /// notice. Nothing is created and no cookie is set until it is accepted.
  Response _noSession(String message) => Response.unauthorized(
    body: Body.fromString(
      jsonEncode({
        'error': message,
        'needsAcceptance': sl<AuthRuntime>().config.publicMode,
      }),
      mimeType: MimeType.json,
    ),
  );
}

/// `POST /auth/guest` — the entry notice's "Accept and continue" button.
///
/// The only way a guest comes into existence: records the acceptance, starts the
/// guest session, sets the cookie, and answers exactly like `/auth/session` so
/// the app can carry straight on. Since nothing else issues a guest cookie, a
/// visitor who has not accepted the notice cannot reach a single endpoint.
///
/// A POST, never a GET: `SameSite=Lax` sends the cookie on a cross-site
/// top-level GET, so a link on another site could otherwise accept the terms on
/// a visitor's behalf.
///
/// ⚠️ Being a POST is not enough on its own. A form on another site can still
/// POST here as a top-level navigation, and the browser stores the `Set-Cookie`
/// of the answer — so the terms would be accepted and a guest session forced
/// onto the visitor without them ever seeing the notice. Hence the origin check:
/// only the app's own page (or a client that is no browser at all) gets in.
class AuthGuestRoute extends Route {
  AuthGuestRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final refusal = OriginGuard.current.refuseUnlessSameOrigin(request);
    if (refusal != null) return refusal;

    final auth = sl<AuthService>();
    final CompletedSignIn accepted;
    try {
      accepted = await auth.acceptAsGuest(
        session,
        cookieValue: _readAuthCookie(request),
      );
    } on AuthFlowException catch (e) {
      return Response.notFound(
        body: Body.fromString(
          jsonEncode({'error': e.message}),
          mimeType: MimeType.json,
        ),
      );
    }

    final issued = await auth.issueApiToken(session, accepted.cookieValue);
    if (issued == null) {
      return Response.unauthorized(
        body: Body.fromString(
          jsonEncode({'error': 'This session could not be started.'}),
          mimeType: MimeType.json,
        ),
      );
    }
    return _tokenResponse(issued, renewCookie: accepted.cookieValue);
  }
}

/// The JSON both `/auth/session` and `/auth/guest` answer with.
///
/// [renewCookie] re-sends the cookie with a fresh `Max-Age`. Only ever for a
/// guest, whose session slides forward on every visit: without it the browser
/// would drop the cookie at its original expiry while the session it names was
/// still alive.
Response _tokenResponse(IssuedApiToken issued, {String? renewCookie}) {
  final now = DateTime.now().toUtc();
  return Response.ok(
    body: Body.fromString(
      jsonEncode({
        'token': issued.token,
        'expiresIn': issued.expires.difference(now).inSeconds,
        'email': issued.email,
        'displayName': issued.displayName,
        'isAdmin': issued.isAdmin,
        'isGuest': issued.isGuest,
      }),
      mimeType: MimeType.json,
    ),
    headers: Headers.build((h) {
      // A bearer token must never be cached by a proxy or by the browser.
      h['cache-control'] = ['no-store'];
      if (renewCookie != null) {
        h.setCookie = _setCookie(
          value: renewCookie,
          secure: sl<AuthRuntime>().config.cookieSecure,
          maxAge: issued.sessionExpires.difference(now),
        );
      }
    }),
  );
}

/// `/auth/logout` — revokes the session, clears the cookie, returns to the app.
///
/// `POST` does the work. It used to be a GET, reached by a plain navigation —
/// which meant any page on any site could sign a visitor out with an
/// `<img src=".../auth/logout">`, since `SameSite=Lax` still sends the cookie
/// on a cross-site GET. A POST additionally has to come from the app's own
/// origin, so a cross-site form cannot do it either.
///
/// The app posts with `fetch` and then reloads itself. The answer is a redirect
/// to the app either way, so a plain HTML form posting here works too.
///
/// `GET` answers with a page holding a single "Sign out" button that posts back
/// here. That keeps an old app bundle (one still cached by the service worker)
/// and a bookmarked link working, while needing a real click — which cannot be
/// faked from another site, since the page refuses to be framed.
class AuthLogoutRoute extends Route {
  AuthLogoutRoute() : super(methods: {Method.get, Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    if (request.method == Method.get) return _confirmationPage();

    final refusal = OriginGuard.current.refuseUnlessSameOrigin(request);
    if (refusal != null) return refusal;

    final cookie = _readAuthCookie(request);
    if (cookie != null) {
      await sl<AuthService>().revokeByCookie(session, cookie);
    }

    return Response.seeOther(
      Uri.parse('/'),
      headers: _cookieHeaders(
        value: '',
        secure: sl<AuthRuntime>().config.cookieSecure,
        // Max-Age=0 tells the browser to drop it immediately.
        maxAge: Duration.zero,
      ),
    );
  }

  static Response _confirmationPage() => Response.ok(
    body: Body.fromString(
      '<!doctype html>\n'
      '<html lang="en"><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '<title>Sign out of FLUMIP</title></head>'
      '<body style="font-family: sans-serif; margin: 3rem auto; '
      'max-width: 30rem; padding: 0 1rem;">'
      '<h1>Sign out of FLUMIP?</h1>'
      '<form method="post" action="/auth/logout">'
      '<button type="submit">Sign out</button> '
      '<a href="/">Back to FLUMIP</a>'
      '</form></body></html>\n',
      mimeType: MimeType.html,
    ),
    headers: Headers.build((h) => h['cache-control'] = ['no-store']),
  );
}

/// Whether the sign-in flow cookie [cookie] belongs to the callback's [state].
///
/// Compared in constant time: the cookie is a secret of the same kind as the
/// state itself.
bool flowCookieMatches(String? cookie, String state) {
  if (cookie == null || cookie.isEmpty || state.isEmpty) return false;
  return constantTimeEquals(utf8.encode(cookie), utf8.encode(state));
}
