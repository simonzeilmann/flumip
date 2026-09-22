import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/foundation.dart';

/// What this caller is allowed to do, according to the server.
///
/// **Asked, never inferred**, for the reason `SettingsTab` documents: an
/// administrator needs no settings password and must not be shown a box asking
/// for one, and an ordinary user must not be shown administrative buttons that
/// would only fail.
///
/// ⚠️ `authController.user?.isAdmin` is *not* good enough here, and the gap
/// matters. On an install with no sign-in, `user` is null and that shortcut
/// reports "not an administrator" — yet that is precisely the install where the
/// settings password *is* the administrative credential, and where
/// [passwordAccepted] is the only thing that says so. Only the server knows.
///
/// Its one piece of I/O is a constructor parameter, so the state machine is
/// testable on the Dart VM exactly like `AuthController`.
class AccessController extends ChangeNotifier {
  AccessController({required this._fetchAccess, this._auth}) {
    // The tabs are all built before the bearer token exists — `TabBarView`
    // constructs every one of them at startup — so the first answer describes an
    // anonymous caller. Re-asking whenever sign-in state changes is what stops a
    // signed-in administrator being shown a password prompt.
    _auth?.addListener(reload);
  }

  final Future<UserSettingsDto> Function() _fetchAccess;
  final Listenable? _auth;

  UserSettingsDto? _access;
  bool _failed = false;

  /// True once the server has confirmed this caller is an administrator.
  ///
  /// False until answered, so nothing destructive is ever offered on the strength
  /// of a guess.
  bool get isAdmin => _access?.isAdmin ?? false;

  /// True when the settings password is still a usable administrative
  /// credential, which is to say while sign-in is not being enforced.
  bool get passwordAccepted => _access?.passwordAccepted ?? false;

  /// Whether the caller could turn out to be an administrator at all.
  ///
  /// When this is false there is no point offering an administrative action: it
  /// would fail whatever password were typed.
  bool get mayAdminister => isAdmin || passwordAccepted;

  /// True when the question itself could not be answered.
  ///
  /// ⚠️ Kept separate from "not an administrator" on purpose. Falling back to
  /// showing a password box on a failed lookup turns every transient network
  /// blip into "type a password", which teaches people to type it.
  bool get failed => _failed;

  /// True before the first answer has arrived.
  bool get loading => _access == null && !_failed;

  Future<void> reload() async {
    try {
      _access = await _fetchAccess();
      _failed = false;
    } catch (_) {
      _access = null;
      _failed = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _auth?.removeListener(reload);
    super.dispose();
  }
}
