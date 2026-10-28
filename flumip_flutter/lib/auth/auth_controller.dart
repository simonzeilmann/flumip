import 'dart:convert';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../error_text.dart';

/// Where the app is with respect to signing in.
enum AuthState {
  /// Before [AuthController.bootstrap] has finished.
  unknown,

  /// This server offers no sign-in. The default, and the case where the app
  /// behaves exactly as it did before any of this existed.
  disabled,

  /// A sign-in is offered and nobody is signed in.
  signedOut,

  /// Signed in, or — on a public instance — a guest who accepted the entry
  /// notice. [AuthController.user]'s `isGuest` tells the two apart.
  signedIn,

  /// A public instance, and this browser has not accepted the entry notice
  /// yet. Nothing on the server answers until it does.
  needsAcceptance,
}

/// Drives the app's sign-in state.
///
/// Its two pieces of I/O — asking the server whether sign-in is offered, and
/// fetching a bearer from `/auth/session` — are constructor parameters, so the
/// state machine is unit-testable without a browser or a server. See
/// `test/auth/auth_controller_test.dart`.
class AuthController extends ChangeNotifier {
  AuthController({
    required this._fetchConfig,
    required this._fetchSession,
    required this._navigate,
    this._acceptTerms,
  });

  /// Builds the controller the running app uses.
  ///
  /// [siteUrl] is the origin the app was served from, which is also the web
  /// server's — see `api_config.dart`. The `/auth/*` routes are there because
  /// that is where the session cookie lives.
  ///
  /// [navigate] performs a full-page navigation. It is supplied by the caller
  /// rather than done here so that this library imports nothing web-only and the
  /// state machine can be tested on the Dart VM.
  factory AuthController.forApp({
    required Client client,
    required String siteUrl,
    required void Function(String url) navigate,
  }) => AuthController(
    navigate: navigate,
    fetchConfig: () async {
      final config = await client.auth.config();
      return AuthConfigSnapshot(
        enabled: config.enabled,
        buttonLabel: config.buttonLabel,
        publicMode: config.publicMode,
        publicNoticeText: config.publicNoticeText,
        imprintUrl: config.imprintUrl,
        privacyUrl: config.privacyUrl,
        projectRetention: _hours(config.projectRetentionHours),
        maxProjectLifetime: _hours(config.maxProjectLifetimeHours),
      );
    },
    fetchSession: () => fetchSessionToken(siteUrl),
    acceptTerms: () => acceptAsGuest(siteUrl),
  );

  static Duration? _hours(int? hours) =>
      hours == null ? null : Duration(hours: hours);

  final Future<AuthConfigSnapshot> Function() _fetchConfig;
  final Future<SessionTokenResponse?> Function() _fetchSession;
  final void Function(String url) _navigate;
  final Future<SessionTokenResponse> Function()? _acceptTerms;

  AuthState _state = AuthState.unknown;
  AuthState get state => _state;

  String _buttonLabel = 'Sign in with SSO';
  String get buttonLabel => _buttonLabel;

  AuthConfigSnapshot _config = const AuthConfigSnapshot(
    enabled: false,
    buttonLabel: 'Sign in with SSO',
  );

  /// What the server said about itself at bootstrap: whether it is public,
  /// what the entry notice says, and how long projects are kept.
  AuthConfigSnapshot get config => _config;

  bool _accepting = false;

  /// Whether [accept] is waiting for the server.
  bool get accepting => _accepting;

  SessionTokenResponse? _user;

  /// The signed-in user, or null.
  SessionTokenResponse? get user => _user;

  String? _errorMessage;

  /// Why bootstrap could not determine the state, if it could not.
  String? get errorMessage => _errorMessage;

  MutexRefresherClientAuthKeyProvider? _authKeyProvider;

  /// The provider to install on the client, or null when there is nothing to
  /// authenticate with.
  MutexRefresherClientAuthKeyProvider? get authKeyProvider => _authKeyProvider;

  /// Determines whether a sign-in is needed and, if so, whether we have one.
  ///
  /// Never throws: a server that cannot answer must not stop the app from
  /// starting, because on a default install there is nothing to sign in to
  /// anyway.
  Future<void> bootstrap() async {
    try {
      final config = await _fetchConfig();
      _config = config;
      _buttonLabel = config.buttonLabel;

      if (!config.enabled && !config.publicMode) {
        // Leave authKeyProvider null so not a single request carries an
        // Authorization header. That keeps the default install byte-for-byte as
        // it was, and avoids waking the server's authentication handler at all.
        _set(AuthState.disabled);
        return;
      }

      final session = await _fetchSession();
      if (session == null) {
        _set(_signedOutState);
        return;
      }
      await _startSession(session);
    } catch (e) {
      _errorMessage = describeError(e);
      _set(AuthState.disabled);
    }
  }

  /// Accepts the entry notice: the server creates this browser's guest
  /// identity, sets its cookie, and hands back a bearer.
  ///
  /// Never throws. A failure leaves the notice up with [errorMessage] set, so
  /// the visitor can try again.
  Future<void> accept() async {
    final acceptTerms = _acceptTerms;
    if (acceptTerms == null || _accepting) return;
    _accepting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _startSession(await acceptTerms());
    } catch (e) {
      _errorMessage = describeError(e);
      notifyListeners();
    } finally {
      _accepting = false;
      notifyListeners();
    }
  }

  Future<void> _startSession(SessionTokenResponse session) async {
    _user = session;
    // Only installed once we know there is a session to refresh. Installing a
    // refreshing provider earlier risks a deadlock, because the header getter
    // triggers a refresh and the config call above is itself unauthenticated.
    _authKeyProvider = SessionAuthKeyProvider.wrapped(
      fetchSession: _fetchSession,
    );
    // Prime it so the first real request has a header rather than paying for a
    // round trip mid-flight.
    await _authKeyProvider!.refreshAuthKey(force: true);
    _errorMessage = null;
    _set(AuthState.signedIn);
  }

  /// Where a browser with no usable session lands: the entry notice on a
  /// public instance, the sign-in screen otherwise.
  AuthState get _signedOutState =>
      _config.publicMode ? AuthState.needsAcceptance : AuthState.signedOut;

  /// Re-checks whether the session is still good, after a 401 for instance.
  Future<void> revalidate() async {
    if (_state == AuthState.disabled) return;
    final result = await _authKeyProvider?.refreshAuthKey(force: true);
    if (result == RefreshAuthKeyResult.success) return;
    _user = null;
    _authKeyProvider = null;
    _set(_signedOutState);
  }

  /// Starts a sign-in.
  ///
  /// A full-page navigation, not a popup or a new tab: the cookie has to be set
  /// in the browsing context the app is actually running in, and the redirect
  /// chain ends by loading the app again.
  void signIn(String siteUrl) => _navigate('$siteUrl/auth/login');

  /// Signs out.
  ///
  /// Also a full-page navigation, so the server can clear the cookie — only it
  /// can, since the cookie is `HttpOnly`.
  void signOut(String siteUrl) {
    _user = null;
    _authKeyProvider = null;
    _navigate('$siteUrl/auth/logout');
  }

  void _set(AuthState state) {
    _state = state;
    notifyListeners();
  }
}

/// The answer to "does this server want a sign-in?" — and, on a public
/// instance, what the entry notice says and how long projects are kept.
class AuthConfigSnapshot {
  const AuthConfigSnapshot({
    required this.enabled,
    required this.buttonLabel,
    this.publicMode = false,
    this.publicNoticeText = '',
    this.imprintUrl = '',
    this.privacyUrl = '',
    this.projectRetention,
    this.maxProjectLifetime,
  });

  final bool enabled;
  final String buttonLabel;
  final bool publicMode;

  /// Replaces the notice's terms paragraph when not empty.
  final String publicNoticeText;
  final String imprintUrl;
  final String privacyUrl;

  /// How long a new project is kept, or null when nothing is deleted
  /// automatically.
  final Duration? projectRetention;

  /// The furthest "Keep longer" goes, measured from creation. Null exactly when
  /// [projectRetention] is.
  final Duration? maxProjectLifetime;
}

/// `POST /auth/guest`: accepts the entry notice on a public instance.
///
/// Same-origin, so the cookie it sets is stored without any further flag; the
/// answer is the same shape as `/auth/session`'s.
Future<SessionTokenResponse> acceptAsGuest(String siteUrl) async {
  final response = await http.post(
    Uri.parse('$siteUrl/auth/guest'),
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw http.ClientException(
      _serverError(response.body) ??
          'Unexpected status ${response.statusCode} from /auth/guest',
    );
  }
  return SessionTokenResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
}

String? _serverError(String body) {
  try {
    final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
    return error is String && error.isNotEmpty ? error : null;
  } catch (_) {
    return null;
  }
}

/// Fetches `/auth/session` from [siteUrl], returning null when not signed in.
///
/// Uses `package:http` directly rather than the Serverpod client because this is
/// a plain route on the web server, not an endpoint.
///
/// No `withCredentials` is needed even though the request must carry the session
/// cookie: [siteUrl] is the origin the app was served from, and browsers always
/// send cookies on same-origin requests. That flag only governs cross-origin
/// ones — which is precisely why the API calls, which *are* cross-origin, have to
/// use an `Authorization` header instead.
Future<SessionTokenResponse?> fetchSessionToken(String siteUrl) async {
  final response = await http.get(
    Uri.parse('$siteUrl/auth/session'),
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode == 401) return null;
  if (response.statusCode != 200) {
    throw http.ClientException(
      'Unexpected status ${response.statusCode} from /auth/session',
    );
  }
  return SessionTokenResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
}
