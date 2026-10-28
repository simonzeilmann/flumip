import 'dart:convert';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/serverpod.dart';

/// Name of the session cookie.
///
/// Prefixed so it cannot collide with anything else served from the same host,
/// which matters when FLUMIP shares a domain with another application behind the
/// same reverse proxy.
const authCookieName = 'flumip_auth';

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
String? _readAuthCookie(Request request) {
  final header = Headers.cookie.getValueFrom(
    request.headers,
    orElse: (_) => null,
  );
  return header?.getCookie(authCookieName)?.value;
}

Headers _cookieHeaders({
  required String value,
  required bool secure,
  required Duration maxAge,
}) => Headers.build(
  (h) => h.setCookie = _setCookie(value: value, secure: secure, maxAge: maxAge),
);

SetCookieHeader _setCookie({
  required String value,
  required bool secure,
  required Duration maxAge,
}) {
  // Relic 2 split the type: `SetCookie` is one cookie, `SetCookieHeader` is the
  // list of them the response header carries — one `Set-Cookie` line each. This
  // must stay a single-element list; two lines would have the second parsed as a
  // nameless cookie, and an empty list would emit no header at all, which looks
  // exactly like a cancelled sign-in. `path` also went from `Uri` to `String`,
  // which is what it always was — `Uri.parse('/')` was a round trip for nothing.
  return SetCookieHeader([
    SetCookie(
      name: authCookieName,
      value: value,
      path: '/',
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
      return Response.seeOther(url);
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
class AuthGuestRoute extends Route {
  AuthGuestRoute() : super(methods: {Method.post});

  @override
  Future<Result> handleCall(Session session, Request request) async {
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

/// `GET /auth/logout` — revokes the session, clears the cookie, returns to the app.
///
/// A GET because it is reached by a plain navigation from the app; it is
/// idempotent and carries no side effect beyond ending the caller's own session.
class AuthLogoutRoute extends Route {
  AuthLogoutRoute() : super(methods: {Method.get});

  @override
  Future<Result> handleCall(Session session, Request request) async {
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
}
