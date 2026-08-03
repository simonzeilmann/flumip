import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/auth/id_token.dart';
import 'package:flumip_server/src/auth/oidc_client.dart';
import 'package:flumip_server/src/auth/oidc_discovery.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Raised when a sign-in cannot be completed. The message is shown to the
/// person signing in, so it must say what to do rather than what went wrong
/// internally.
class AuthFlowException implements Exception {
  AuthFlowException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? message : '$message (underlying cause: $cause)';
}

/// What `/auth/callback` needs in order to set the cookie and redirect.
class CompletedSignIn {
  const CompletedSignIn({required this.cookieValue, required this.session});

  /// The raw cookie value. Only ever exists in this object and in the
  /// `Set-Cookie` header — the database holds its sha256.
  final String cookieValue;
  final AuthSession session;
}

/// What `/auth/session` hands to the app.
class IssuedApiToken {
  const IssuedApiToken({
    required this.token,
    required this.expires,
    required this.email,
    required this.displayName,
    required this.isAdmin,
  });

  final String token;
  final DateTime expires;
  final String email;
  final String displayName;
  final bool isAdmin;
}

/// The database-facing half of authentication.
///
/// Owns the three tables and the rules about their lifetimes. The protocol
/// itself lives in [OidcClient] and the configuration in [AuthRuntime], so this
/// class is about persistence and policy only.
class AuthService {
  AuthService();

  /// How long an authorization request stays redeemable.
  ///
  /// Generous enough for someone to complete a real sign-in including a second
  /// factor, short enough that abandoned rows do not accumulate.
  static const flowLifetime = Duration(minutes: 15);

  /// How long a browser stays signed in without going back to the provider.
  static const sessionLifetime = Duration(hours: 12);

  /// How long an API bearer stays valid.
  ///
  /// Short because it is trivially re-minted from the cookie, and because it is
  /// the credential that travels in a header to a different origin.
  static const apiTokenLifetime = Duration(minutes: 30);

  AuthRuntime get _runtime => sl<AuthRuntime>();
  OidcClient get _oidc => sl<OidcClient>();

  /// Starts a sign-in: records the flow and returns the URL to redirect to.
  ///
  /// Throws [AuthFlowException] when the provider is not configured or was not
  /// reachable, because there is nowhere to redirect to in that case.
  Future<Uri> beginFlow(Session session) async {
    final config = _runtime.config;
    final discovery = _runtime.discovery;

    // Checked before the configuration, so that an install where sign-in has
    // been switched off — including via the FLUMIP_AUTH_ENABLED break-glass
    // switch, which leaves the stored OIDC settings intact — says so, rather
    // than blaming the provider it is no longer talking to.
    if (!config.loginRequired) {
      throw AuthFlowException(
        'Single sign-on is switched off on this server, so there is nothing to '
        'sign in to. You should be able to use FLUMIP without signing in.',
      );
    }
    if (!config.isComplete) {
      throw AuthFlowException(
        'Single sign-on is not fully configured on this server. An '
        'administrator needs to set the issuer, client ID and client secret in '
        'Settings.',
      );
    }
    if (discovery == null) {
      throw AuthFlowException(
        'This server cannot currently reach the identity provider at '
        '${config.issuer}. ${_runtime.discoveryError ?? ''}'.trim(),
      );
    }
    if (config.redirectUri.isEmpty) {
      throw AuthFlowException(
        'This server does not know its own public URL, so it cannot build a '
        'redirect URI. An administrator needs to set the public URL in '
        'Settings or ${AuthEnv.publicUrl} in the environment.',
      );
    }

    final state = AuthTokens.newToken();
    final nonce = AuthTokens.newToken();
    final codeVerifier = AuthTokens.newCodeVerifier();

    await AuthFlow.db.insertRow(
      session,
      AuthFlow(
        state: state,
        codeVerifier: codeVerifier,
        nonce: nonce,
        redirectUri: config.redirectUri,
        expires: DateTime.now().toUtc().add(flowLifetime),
      ),
    );

    return _oidc.authorizationUrl(
      discovery: discovery,
      config: config,
      state: state,
      nonce: nonce,
      codeVerifier: codeVerifier,
    );
  }

  /// Redeems an authorization code and creates a signed-in session.
  ///
  /// The flow row is deleted before the exchange, which is what makes `state`
  /// and `nonce` single-use: a replayed callback finds no row and is refused,
  /// with no extra bookkeeping.
  Future<CompletedSignIn> completeCallback(
    Session session, {
    required String code,
    required String state,
  }) async {
    final config = _runtime.config;
    final discovery = _runtime.discovery;
    if (discovery == null || !config.isComplete) {
      throw AuthFlowException(
        'Single sign-on is not currently available on this server.',
      );
    }

    final flow = await AuthFlow.db.findFirstRow(
      session,
      where: (t) => t.state.equals(state),
    );
    if (flow == null) {
      throw AuthFlowException(
        'This sign-in link has already been used or was not issued by this '
        'server. Please start again.',
      );
    }
    // Consume it whether or not the rest succeeds.
    await AuthFlow.db.deleteRow(session, flow);

    final now = DateTime.now().toUtc();
    if (now.isAfter(flow.expires)) {
      throw AuthFlowException(
        'This sign-in took too long and has expired. Please start again.',
      );
    }

    final TokenResponse tokens;
    try {
      tokens = await _oidc.exchangeCode(
        discovery: discovery,
        config: config,
        code: code,
        codeVerifier: flow.codeVerifier,
      );
    } catch (e) {
      session.log('The authorization code exchange failed: $e',
          level: LogLevel.error);
      throw AuthFlowException(
        'The identity provider refused this sign-in. If this keeps happening, '
        'an administrator should check that the redirect URI registered with '
        'the provider is exactly "${config.redirectUri}".',
        cause: e,
      );
    }

    // The only call to IdTokenClaims.parse. See the comment on that class: the
    // signature is deliberately not verified, which is only sound because the
    // token came straight from the token endpoint over TLS just now. Do not move
    // this call anywhere a client can reach.
    final IdTokenClaims claims;
    try {
      claims = IdTokenClaims.parse(tokens.idToken);
      claims.validate(
        issuer: config.issuer,
        clientId: config.clientId,
        nonce: flow.nonce,
        now: now,
      );
    } catch (e) {
      session.log('The ID token was rejected: $e', level: LogLevel.error);
      throw AuthFlowException(
        'The identity provider returned a token this server could not accept.',
        cause: e,
      );
    }

    var email = claims.email ?? '';
    var displayName = claims.name ?? '';
    if (email.isEmpty) {
      // Not every provider puts email in the ID token even when the scope was
      // granted, so fall back to userinfo before giving up.
      final info = await _fetchUserinfo(session, discovery, tokens.accessToken);
      email = (info?['email'] as String?)?.trim() ?? '';
      displayName = displayName.isNotEmpty
          ? displayName
          : ((info?['name'] ?? info?['preferred_username']) as String? ?? '');
    }
    if (email.isEmpty) {
      throw AuthFlowException(
        'The identity provider did not tell this server your email address. '
        'An administrator needs to grant the "email" scope to the FLUMIP '
        'client.',
      );
    }

    email = email.toLowerCase();
    if (!config.isEmailAllowed(email)) {
      session.log(
        'Refused sign-in for $email: not in the allowed domains '
        '(${config.allowedDomains.join(', ')}).',
        level: LogLevel.warning,
      );
      throw AuthFlowException(
        'The account $email is not allowed to use this FLUMIP server.',
      );
    }

    final user = await _upsertUser(
      session,
      issuer: claims.issuer,
      subject: claims.subject,
      email: email,
      displayName: displayName,
      now: now,
    );

    final cookieValue = AuthTokens.newToken();
    final authSession = await AuthSession.db.insertRow(
      session,
      AuthSession(
        userId: user.id!,
        cookieHash: AuthTokens.sha256Hex(cookieValue),
        email: email,
        isAdmin: config.isAdminEmail(email),
        expires: now.add(sessionLifetime),
      ),
    );

    session.log(
      'Signed in $email (admin: ${authSession.isAdmin}) via ${claims.issuer}',
      level: LogLevel.info,
    );
    return CompletedSignIn(cookieValue: cookieValue, session: authSession);
  }

  /// Mints a short-lived API bearer for the holder of [cookieValue].
  ///
  /// Returns null when the cookie is unknown or expired, which the route turns
  /// into a 401 and the app into "not signed in".
  Future<IssuedApiToken?> issueApiToken(
    Session session,
    String cookieValue,
  ) async {
    final authSession = await _sessionForCookie(session, cookieValue);
    if (authSession == null) return null;

    final now = DateTime.now().toUtc();
    final token = AuthTokens.newToken();
    // Never outlive the browser session that authorised it.
    final expires = _earliest(now.add(apiTokenLifetime), authSession.expires);

    await AuthApiToken.db.insertRow(
      session,
      AuthApiToken(
        authSessionId: authSession.id!,
        tokenHash: AuthTokens.sha256Hex(token),
        email: authSession.email,
        isAdmin: authSession.isAdmin,
        expires: expires,
      ),
    );

    authSession.lastSeen = now;
    await AuthSession.db.updateRow(session, authSession);

    final user = await FlumipUser.db.findById(session, authSession.userId);
    return IssuedApiToken(
      token: token,
      expires: expires,
      email: authSession.email,
      displayName: user?.displayName ?? '',
      isAdmin: authSession.isAdmin,
    );
  }

  /// Looks up a bearer token, reading through a process-local cache.
  ///
  /// The cache turns an indexed query per authenticated request into a map
  /// lookup. It stays correct because [revokeSession] invalidates the group in
  /// the same process that holds the cache — see the note on [AuthRuntime] about
  /// what would change with several processes.
  ///
  /// Returns null rather than throwing for anything it cannot resolve; the
  /// authentication handler depends on that.
  Future<AuthApiToken?> resolveApiToken(Session session, String token) async {
    final hash = AuthTokens.sha256Hex(token);
    final key = cacheKeyForToken(hash);

    final cached = await session.caches.localPrio.get<AuthApiToken>(key);
    if (cached != null) {
      return DateTime.now().toUtc().isAfter(cached.expires) ? null : cached;
    }

    final row = await AuthApiToken.db.findFirstRow(
      session,
      where: (t) => t.tokenHash.equals(hash),
    );
    if (row == null) return null;

    final remaining = row.expires.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return null;

    await session.caches.localPrio.put(
      key,
      row,
      lifetime: remaining,
      group: cacheGroupForSession(row.authSessionId),
    );
    return row;
  }

  /// Ends a signed-in session and every bearer minted from it.
  ///
  /// The cascade on `auth_api_token.authSessionId` deletes the tokens, and
  /// invalidating the cache group drops them from the lookup cache — so the very
  /// next request with one of those bearers is refused.
  Future<void> revokeSession(Session session, int authSessionId) async {
    await AuthSession.db.deleteWhere(
      session,
      where: (t) => t.id.equals(authSessionId),
    );
    await broadcastRevocation(session, authSessionId);
  }

  /// Ends **every** session on this server, and returns how many.
  ///
  /// Used when an administrator switches sign-in off. Leaving sessions alive
  /// would mean the app still shows people as signed in, and still treats an
  /// administrator as one, on an install that no longer authenticates anybody —
  /// their tokens would go on being accepted for as long as they last.
  ///
  /// ⚠️ **Deleting the rows is not sufficient**, which is why this loops rather
  /// than being one `deleteWhere`. The bearer lookup is a read-through
  /// `localPrio` cache, so a row deleted underneath it keeps answering until the
  /// entry ages out — up to the token lifetime. That is the documented trap with
  /// a manual `DELETE FROM auth_session`, and it would apply here in exactly the
  /// same way. Each session's cache group has to be invalidated by id.
  Future<int> revokeAllSessions(Session session) async {
    final sessions = await AuthSession.db.find(session);
    if (sessions.isEmpty) return 0;

    // Cascades to auth_api_token, so the bearers go with the sessions.
    await AuthSession.db.deleteWhere(session, where: (t) => t.id > 0);
    for (final revoked in sessions) {
      await broadcastRevocation(session, revoked.id!);
    }
    return sessions.length;
  }

  /// Ends the session identified by a cookie value. Used by `/auth/logout`.
  Future<void> revokeByCookie(Session session, String cookieValue) async {
    final authSession = await AuthSession.db.findFirstRow(
      session,
      where: (t) => t.cookieHash.equals(AuthTokens.sha256Hex(cookieValue)),
    );
    if (authSession == null) return;
    await revokeSession(session, authSession.id!);
  }

  /// The single propagation point for revocation.
  ///
  /// With several server processes this becomes
  /// `session.messages.authenticationRevoked(...)`; today the cache being
  /// invalidated is the only one there is.
  Future<void> broadcastRevocation(Session session, int authSessionId) =>
      session.caches.localPrio.invalidateGroup(
        cacheGroupForSession(authSessionId),
      );

  /// Deletes expired flows, sessions and tokens.
  ///
  /// Called opportunistically from `/auth/login` and from the refresh tick
  /// rather than from a scheduled future call: these tables are small, and one
  /// fewer moving part is worth more than precise timing.
  Future<void> pruneExpired(Session session) async {
    final now = DateTime.now().toUtc();
    try {
      await AuthFlow.db.deleteWhere(session, where: (t) => t.expires < now);
      await AuthApiToken.db.deleteWhere(session, where: (t) => t.expires < now);
      // Cascades to any remaining tokens of the session.
      await AuthSession.db.deleteWhere(session, where: (t) => t.expires < now);
    } catch (e) {
      session.log('Pruning expired authentication rows failed: $e',
          level: LogLevel.warning);
    }
  }

  /// Cache key for a bearer token hash.
  static String cacheKeyForToken(String tokenHash) => 'auth:token:$tokenHash';

  /// Cache group holding every bearer minted from one browser session, so that
  /// revocation is a single invalidation.
  static String cacheGroupForSession(int authSessionId) =>
      'auth:session:$authSessionId';

  Future<AuthSession?> _sessionForCookie(
    Session session,
    String cookieValue,
  ) async {
    if (cookieValue.isEmpty) return null;
    final authSession = await AuthSession.db.findFirstRow(
      session,
      where: (t) => t.cookieHash.equals(AuthTokens.sha256Hex(cookieValue)),
    );
    if (authSession == null) return null;
    if (DateTime.now().toUtc().isAfter(authSession.expires)) return null;
    return authSession;
  }

  Future<Map<String, dynamic>?> _fetchUserinfo(
    Session session,
    OidcDiscovery discovery,
    String? accessToken,
  ) async {
    if (accessToken == null) return null;
    try {
      return await _oidc.userinfo(
        discovery: discovery,
        accessToken: accessToken,
      );
    } catch (e) {
      session.log('The userinfo request failed: $e', level: LogLevel.warning);
      return null;
    }
  }

  /// Finds or creates the identity record for `(issuer, subject)`.
  ///
  /// Keyed on that pair rather than on the email, because email is a mutable
  /// attribute: someone changing their name at an institution keeps the same
  /// subject and should keep the same record.
  Future<FlumipUser> _upsertUser(
    Session session, {
    required String issuer,
    required String subject,
    required String email,
    required String displayName,
    required DateTime now,
  }) async {
    final existing = await FlumipUser.db.findFirstRow(
      session,
      where: (t) => t.issuer.equals(issuer) & t.subject.equals(subject),
    );
    if (existing != null) {
      existing
        ..email = email
        ..lastLogin = now;
      if (displayName.isNotEmpty) existing.displayName = displayName;
      return FlumipUser.db.updateRow(session, existing);
    }
    return FlumipUser.db.insertRow(
      session,
      FlumipUser(
        email: email,
        subject: subject,
        issuer: issuer,
        displayName: displayName,
        created: now,
        lastLogin: now,
      ),
    );
  }

  static DateTime _earliest(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
