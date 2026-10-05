import 'package:serverpod_client/serverpod_client.dart';

/// The API bearer for one browser session, refreshed from `/auth/session`.
///
/// ## Why the token is fetched rather than stored
///
/// The durable credential is an `HttpOnly` cookie on the web server's origin,
/// which this code deliberately cannot read. API calls authenticate with an
/// `Authorization` header instead — a credential the browser never attaches on
/// its own, so no other site can spend it (see `AuthApiToken` on the server).
/// `/auth/session` is the bridge: same origin as the app, so the browser attaches
/// the cookie automatically, and it answers with a short-lived bearer.
///
/// The bearer lives in [_token] and nowhere else — never `localStorage`, never a
/// URL. A page reload starts from the cookie again, so there is no long-lived
/// credential for a script to steal.
///
/// ## Refresh behaviour
///
/// Wrap this in the framework's [MutexRefresherClientAuthKeyProvider] (see
/// [SessionAuthKeyProvider.wrapped]). That decorator serialises concurrent
/// refreshes *and* remembers a `failedUnauthorized` result, so once the session
/// is genuinely gone it stops asking. That memoisation is what keeps the app's
/// ten-second polling timers from turning an expired session into a refresh
/// storm.
class SessionAuthKeyProvider implements RefresherClientAuthKeyProvider {
  SessionAuthKeyProvider({
    required this._fetchSession,
    this.refreshMargin = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Fetches `/auth/session`. Injected so this is testable without a browser.
  final Future<SessionTokenResponse?> Function() _fetchSession;

  /// How long before expiry to renew.
  ///
  /// Renewing early means a request in flight when the token expires does not
  /// have to fail and be retried.
  final Duration refreshMargin;

  final DateTime Function() _now;

  String? _token;
  DateTime? _expires;

  /// Set once `/auth/session` has answered 401, cleared by a forced refresh.
  ///
  /// This is the poll-storm guard, and it has to live here rather than being left
  /// to [MutexRefresherClientAuthKeyProvider]. That decorator memoises a
  /// `failedUnauthorized` only while the delegate still returns the *same*
  /// non-null header — and this provider drops its token on 401, precisely so no
  /// dead bearer keeps getting sent. With a null header the decorator's guard
  /// never fires, so without this flag the app's ten-second polling timers would
  /// hammer `/auth/session` once per tick per timer forever.
  bool _sessionIsDead = false;

  /// The identity behind the current token, for the app bar.
  SessionTokenResponse? get lastSession => _lastSession;
  SessionTokenResponse? _lastSession;

  /// Wraps a new provider in the framework's mutex decorator.
  ///
  /// Always use this rather than the bare provider: without it, the several
  /// timers in the app can each trigger a refresh at once.
  static MutexRefresherClientAuthKeyProvider wrapped({
    required Future<SessionTokenResponse?> Function() fetchSession,
  }) => MutexRefresherClientAuthKeyProvider(
    SessionAuthKeyProvider(fetchSession: fetchSession),
  );

  /// The `Authorization` header value, or null when there is no token.
  ///
  /// **Bearer, not Basic.** Serverpod's `wrapAsBasicAuthHeaderValue` exists for
  /// its own auth keys, which have the shape `id:hash`; relic's typed
  /// `authorization` header parser decodes a `Basic` value and splits it on a
  /// colon, so an opaque token without one is rejected with a 400 *before the
  /// authentication handler ever runs*. Verified against a running server: the
  /// same token is a 400 as Basic and fine as Bearer.
  @override
  Future<String?> get authHeaderValue async {
    final token = _token;
    if (token == null) return null;
    return wrapAsBearerAuthHeaderValue(token);
  }

  @override
  Future<RefreshAuthKeyResult> refreshAuthKey({bool force = false}) async {
    if (force) {
      // An explicit re-check: the caller wants to know whether the session came
      // back, so stop remembering that it was gone.
      _sessionIsDead = false;
    } else {
      if (_sessionIsDead) return RefreshAuthKeyResult.failedUnauthorized;
      if (!_needsRefresh) return RefreshAuthKeyResult.skipped;
    }

    final SessionTokenResponse? session;
    try {
      session = await _fetchSession();
    } catch (_) {
      // Network trouble rather than a rejected credential: report it as such so
      // the decorator does not memoise it as "permanently unauthorised" and give
      // up on a session that is actually still valid.
      return RefreshAuthKeyResult.failedOther;
    }

    if (session == null) {
      // The cookie is gone, expired, or was signed out. Drop the token so no
      // dead bearer is sent, and remember this so we stop asking.
      _token = null;
      _expires = null;
      _lastSession = null;
      _sessionIsDead = true;
      return RefreshAuthKeyResult.failedUnauthorized;
    }

    _token = session.token;
    _expires = _now().add(session.expiresIn);
    _lastSession = session;
    _sessionIsDead = false;
    return RefreshAuthKeyResult.success;
  }

  /// Forgets the token without contacting the server.
  ///
  /// Used on sign-out, where the browser navigates to `/auth/logout` and the
  /// server revokes the session anyway.
  void clear() {
    _token = null;
    _expires = null;
    _lastSession = null;
    _sessionIsDead = true;
  }

  bool get _needsRefresh {
    if (_token == null) return true;
    final expires = _expires;
    if (expires == null) return true;
    return _now().isAfter(expires.subtract(refreshMargin));
  }
}

/// What `/auth/session` returns.
class SessionTokenResponse {
  const SessionTokenResponse({
    required this.token,
    required this.expiresIn,
    required this.email,
    this.displayName = '',
    this.isAdmin = false,
  });

  factory SessionTokenResponse.fromJson(Map<String, dynamic> json) =>
      SessionTokenResponse(
        token: json['token'] as String,
        expiresIn: Duration(seconds: (json['expiresIn'] as num).toInt()),
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        isAdmin: json['isAdmin'] as bool? ?? false,
      );

  final String token;
  final Duration expiresIn;
  final String email;
  final String displayName;
  final bool isAdmin;
}
