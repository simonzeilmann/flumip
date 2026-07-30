import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:serverpod/serverpod.dart';

/// The scope granted to addresses on the admin list.
const adminScope = Scope('admin');

/// Resolves a bearer token to an [AuthenticationInfo], or to null.
///
/// ## Why this is installed unconditionally
///
/// Serverpod's [defaultAuthenticationHandler] **throws `UnimplementedError`**,
/// and `Session.initializeAuthentication` calls the handler whenever a request
/// carries an `authorization` header. Installing ours only when SSO is switched
/// on would therefore mean that a browser holding a token from before SSO was
/// turned off would get a 500 on *every call to every endpoint* — including the
/// settings endpoint needed to fix it, and with nothing in the UI to suggest
/// clearing the credential. So it is always installed, and it treats "no
/// authentication configured" as "this token resolves to nobody".
///
/// ## Why it must never throw
///
/// Same reason: a throw here becomes a 500 on an unrelated endpoint rather than
/// a clean "not authenticated". Every failure — a malformed token, a dropped
/// database connection, a cache miss handler blowing up — has to come out as
/// null so the framework can answer 401 and the client can recover by signing in
/// again. Hence the catch-all.
Future<AuthenticationInfo?> flumipAuthenticationHandler(
  Session session,
  String token,
) async {
  try {
    if (token.isEmpty) return null;

    final row = await sl<AuthService>().resolveApiToken(session, token);
    if (row == null) return null;

    return AuthenticationInfo(
      // The email, not the user id: it is what endpoints will want, and
      // AuthenticationInfo rejects an empty identifier.
      row.email,
      row.isAdmin ? {adminScope} : const <Scope>{},
      // The browser session, so that logout can revoke every token minted from
      // it via session.authenticated!.authId with no extra lookup.
      authId: '${row.authSessionId}',
    );
  } catch (e, stackTrace) {
    session.log(
      'Resolving an authentication token failed; treating the request as '
      'unauthenticated.',
      level: LogLevel.error,
      exception: e,
      stackTrace: stackTrace,
    );
    return null;
  }
}
