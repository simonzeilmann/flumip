import 'dart:convert';

import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Where the app is with respect to signing in.
enum AuthState {
  /// Before [AuthController.bootstrap] has finished.
  unknown,

  /// This server offers no sign-in. The default, and the case where the app
  /// behaves exactly as it did before any of this existed.
  disabled,

  /// A sign-in is offered and nobody is signed in.
  signedOut,

  /// Signed in.
  signedIn,
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
  });

  /// Builds the controller the running app uses.
  ///
  /// [siteUrl] is the origin the app was served from, which is also the web
  /// server's — see `api_config.dart`. The `/auth/*` routes are there, not on the
  /// API origin, because that is where the session cookie lives.
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
      );
    },
    fetchSession: () => fetchSessionToken(siteUrl),
  );

  final Future<AuthConfigSnapshot> Function() _fetchConfig;
  final Future<SessionTokenResponse?> Function() _fetchSession;
  final void Function(String url) _navigate;

  AuthState _state = AuthState.unknown;
  AuthState get state => _state;

  String _buttonLabel = 'Sign in with SSO';
  String get buttonLabel => _buttonLabel;

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
      _buttonLabel = config.buttonLabel;

      if (!config.enabled) {
        // Leave authKeyProvider null so not a single request carries an
        // Authorization header. That keeps the default install byte-for-byte as
        // it was, and avoids waking the server's authentication handler at all.
        _set(AuthState.disabled);
        return;
      }

      final session = await _fetchSession();
      if (session == null) {
        _set(AuthState.signedOut);
        return;
      }

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
      _set(AuthState.signedIn);
    } catch (e) {
      _errorMessage = '$e';
      _set(AuthState.disabled);
    }
  }

  /// Re-checks whether the session is still good, after a 401 for instance.
  Future<void> revalidate() async {
    if (_state == AuthState.disabled) return;
    final result = await _authKeyProvider?.refreshAuthKey(force: true);
    if (result == RefreshAuthKeyResult.success) return;
    _user = null;
    _authKeyProvider = null;
    _set(AuthState.signedOut);
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

/// The answer to "does this server want a sign-in?".
class AuthConfigSnapshot {
  const AuthConfigSnapshot({required this.enabled, required this.buttonLabel});

  final bool enabled;
  final String buttonLabel;
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
