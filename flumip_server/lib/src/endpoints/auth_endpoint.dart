import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// What the app needs in order to decide whether to show a sign-in screen.
///
/// Plain [Endpoint], never a [FlumipEndpoint]: the app calls [config] before it
/// has any credential at all, so requiring one would be circular.
class AuthEndpoint extends Endpoint {
  AuthService get authService => sl<AuthService>();

  /// Whether this server wants a sign-in, and what to label the button.
  ///
  /// Answered unauthenticated on purpose. It leaks only whether SSO is on and a
  /// label an administrator chose — both of which are visible from the sign-in
  /// page anyway.
  Future<AuthConfigDto> config(Session session) async {
    final runtime = sl<AuthRuntime>();
    return AuthConfigDto(
      // Show the sign-in button whenever signing in is possible, not only when
      // it is compulsory: an install can reasonably want identities without
      // locking anonymous users out.
      enabled: runtime.canSignIn,
      buttonLabel: runtime.config.buttonLabel,
    );
  }

  /// The signed-in user, or null when this request carries no valid session.
  Future<AuthUserDto?> me(Session session) async {
    final authenticated = session.authenticated;
    if (authenticated == null) return null;

    final authSessionId = int.tryParse(authenticated.authId);
    final authSession = authSessionId == null
        ? null
        : await AuthSession.db.findById(session, authSessionId);
    final user = authSession == null
        ? null
        : await FlumipUser.db.findById(session, authSession.userId);

    return AuthUserDto(
      email: authenticated.userIdentifier,
      displayName: user?.displayName ?? '',
      isAdmin: authenticated.scopes.contains(adminScope),
    );
  }

  /// Ends this browser session everywhere.
  ///
  /// Revokes the [AuthSession] named by the token's `authId`, which cascades to
  /// every bearer minted from it — so other tabs lose access too, which is what
  /// signing out should mean. The cookie itself is cleared by `/auth/logout`,
  /// since only the web server can set headers on the app's own origin.
  Future<void> logout(Session session) async {
    final authId = session.authenticated?.authId;
    final authSessionId = int.tryParse(authId ?? '');
    if (authSessionId == null) return;
    await authService.revokeSession(session, authSessionId);
    session.log('Signed out session $authSessionId', level: LogLevel.info);
  }
}
