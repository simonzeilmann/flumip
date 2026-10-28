import 'package:flumip_client/flumip_client.dart';

import 'auth/auth_controller.dart';
import 'error_text.dart';

/// The share-link token in [uri], or null when the page was opened normally.
///
/// A share link is `<site>/#/p/<token>` — see `shareLinkFor`. The token lives in
/// the fragment so that it never reaches a server log; that also means only the
/// app itself can read it, which is what this is for.
String? shareTokenFrom(Uri uri) {
  final match = RegExp(r'^/?p/([A-Za-z0-9_-]+)/?$').firstMatch(uri.fragment);
  return match?.group(1);
}

/// Opens the project a share link points at, once there is a session to open it
/// with.
///
/// On a public instance that is only after the entry notice has been accepted —
/// before then the server answers nothing — so this waits on [AuthController]
/// rather than acting at start-up. On an install with no sign-in it goes ahead
/// at once.
///
/// Browser-free, like everything outside `main.dart`: reading the address bar
/// and rewriting it are handed in as callbacks.
class ShareLinkOpener {
  ShareLinkOpener({
    required this._auth,
    required this._redeem,
    required this._reveal,
    required this._clearLink,
    required this._report,
  });

  final AuthController _auth;
  final Future<Project> Function(String token) _redeem;

  /// Puts the project in front of the user: refresh the list, open its tile.
  final Future<void> Function(Project project) _reveal;

  /// Takes the token out of the address bar, so a reload or a bookmark does
  /// not redeem it again and the link is not left on screen to be copied.
  final void Function() _clearLink;

  /// Shows a message — why the link could not be opened.
  final void Function(String message) _report;

  String? _token;

  /// Begins waiting to open [token]. Does nothing for a null token.
  void start(String? token) {
    if (token == null) return;
    _token = token;
    _auth.addListener(_check);
    _check();
  }

  Future<void> _check() async {
    final token = _token;
    if (token == null) return;
    final state = _auth.state;
    if (state != AuthState.signedIn && state != AuthState.disabled) return;

    _token = null;
    _auth.removeListener(_check);
    _clearLink();
    try {
      await _reveal(await _redeem(token));
    } on FlumipFileNotFoundException catch (e) {
      _report(e.message);
    } catch (e) {
      _report('Could not open the shared project: ${describeError(e)}');
    }
  }
}
