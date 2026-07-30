import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Names of the environment variables that override the stored settings.
///
/// An environment variable always wins over the database value, so that an
/// admin who has locked themselves out — or who wants the configuration to live
/// in their deployment tooling rather than in the app — has a way in that does
/// not require the app to be usable. [AuthConfig.envOverrides] reports which of
/// these were set so the settings tab can render those fields read-only instead
/// of letting someone save a value that silently has no effect.
abstract final class AuthEnv {
  static const enabled = 'FLUMIP_AUTH_ENABLED';
  static const issuer = 'FLUMIP_OIDC_ISSUER';
  static const clientId = 'FLUMIP_OIDC_CLIENT_ID';
  static const clientSecret = 'FLUMIP_OIDC_CLIENT_SECRET';
  static const adminEmails = 'FLUMIP_OIDC_ADMIN_EMAILS';
  static const allowedDomains = 'FLUMIP_OIDC_ALLOWED_DOMAINS';
  static const publicUrl = 'FLUMIP_PUBLIC_URL';
  static const strict = 'FLUMIP_AUTH_STRICT';
}

/// The effective authentication configuration: stored settings with environment
/// variables layered on top.
///
/// Immutable and derived by a pure function ([AuthConfig.resolve]) so that the
/// precedence rules can be tested without a database, a server or a network.
class AuthConfig {
  const AuthConfig({
    required this.loginRequired,
    required this.issuer,
    required this.clientId,
    required this.clientSecret,
    required this.scopes,
    required this.buttonLabel,
    required this.allowedDomains,
    required this.adminEmails,
    required this.redirectUri,
    required this.appOrigin,
    required this.cookieSecure,
    required this.strict,
    required this.envOverrides,
  });

  /// A configuration with authentication switched off. Used before the settings
  /// have been read for the first time, and as the fallback when reading them
  /// fails.
  static const disabled = AuthConfig(
    loginRequired: false,
    issuer: '',
    clientId: '',
    clientSecret: '',
    scopes: 'openid email profile',
    buttonLabel: 'Sign in with SSO',
    allowedDomains: <String>[],
    adminEmails: <String>[],
    redirectUri: '',
    appOrigin: '',
    cookieSecure: false,
    strict: false,
    envOverrides: <String>[],
  );

  /// Whether the admin has asked for authentication. Not the same as
  /// [isEnforcing]: an incomplete configuration is not enforced.
  final bool loginRequired;

  /// The OIDC issuer, e.g. `https://login.uni.example/realms/staff`.
  final String issuer;
  final String clientId;
  final String clientSecret;

  /// Space-separated scope list sent to the authorization endpoint.
  final String scopes;

  /// Label for the sign-in button in the app.
  final String buttonLabel;

  /// Lower-cased email domains allowed to sign in. Empty allows everyone the
  /// provider authenticates.
  final List<String> allowedDomains;

  /// Lower-cased email addresses granted the `admin` scope.
  final List<String> adminEmails;

  /// The absolute callback URL registered with the provider.
  final String redirectUri;

  /// Origin the app is served from, used as the post-sign-in landing page.
  final String appOrigin;

  /// Whether to mark the session cookie `Secure`.
  ///
  /// Derived from the public scheme rather than hard-coded: a `Secure` cookie on
  /// a plain-HTTP install is silently dropped by the browser, and sign-in then
  /// looks like a no-op with no error message anywhere.
  final bool cookieSecure;

  /// Refuse to fall back to unauthenticated access when the configuration is
  /// incomplete or the provider is unreachable.
  ///
  /// Off by default because a permanent lockout is the worse failure: with the
  /// default, a half-finished configuration leaves the install reachable and
  /// logs a warning, and flipping [loginRequired] already requires the settings
  /// password so this is not a bypass.
  final bool strict;

  /// Which environment variables were set, by their [AuthEnv] name.
  final List<String> envOverrides;

  /// Whether there is enough configuration to complete a sign-in.
  bool get isComplete =>
      issuer.isNotEmpty && clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// Whether requests should be rejected without a valid session.
  ///
  /// [hasDiscovery] is passed in rather than held here because discovery is a
  /// network result with its own lifetime; see [AuthRuntime].
  bool isEnforcing({required bool hasDiscovery}) {
    if (!loginRequired) return false;
    if (strict) return true;
    return isComplete && hasDiscovery;
  }

  /// Resolves the effective configuration from [settings] and [env].
  ///
  /// Pure: no I/O, no clock, no globals. [settings] is null before the first
  /// successful database read, in which case the environment alone decides.
  /// [clientSecret] comes from Serverpod's password mechanism
  /// (`passwords.yaml` or [AuthEnv.clientSecret]) and falls back to the stored
  /// [Settings.oidcClientSecret].
  static AuthConfig resolve({
    Settings? settings,
    required Map<String, String> env,
    String? clientSecret,
    ServerpodConfig? serverpodConfig,
  }) {
    final overrides = <String>[];

    // A blank value counts as unset. The generated env file ships with every key
    // present but commented out, so an admin who uncomments a key and leaves it
    // empty means "I have not filled this in yet" — not "blank out whatever is
    // configured in the database".
    String? envValue(String name) {
      final value = env[name]?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    String pick(String envName, String stored) {
      final value = envValue(envName);
      if (value == null) return stored;
      overrides.add(envName);
      return value;
    }

    // Must override in both directions: as a break-glass switch it has to be
    // able to turn authentication off, and an admin configuring everything from
    // their deployment tooling needs it to turn authentication on.
    var loginRequired = settings?.loginRequired ?? false;
    final enabledEnv = envValue(AuthEnv.enabled);
    if (enabledEnv != null) {
      final parsed = _parseBool(enabledEnv);
      if (parsed != null) {
        overrides.add(AuthEnv.enabled);
        loginRequired = parsed;
      }
    }

    final issuer = _stripTrailingSlash(
      pick(AuthEnv.issuer, settings?.oidcIssuer ?? ''),
    );
    final clientId = pick(AuthEnv.clientId, settings?.oidcClientId ?? '');
    final adminEmails = _splitList(
      pick(AuthEnv.adminEmails, settings?.oidcAdminEmails ?? ''),
    );
    final allowedDomains = _splitList(
      pick(AuthEnv.allowedDomains, settings?.oidcAllowedEmailDomains ?? ''),
    ).map(_stripLeadingAt).toList();

    // Serverpod resolves the secret before we get here: loadCustomPasswords
    // reads FLUMIP_OIDC_CLIENT_SECRET, falling back to passwords.yaml. Either
    // way it arrives as [clientSecret] and takes precedence over the stored one.
    final secret = clientSecret?.trim().isNotEmpty == true
        ? clientSecret!.trim()
        : (settings?.oidcClientSecret ?? '');
    if (envValue(AuthEnv.clientSecret) != null) {
      overrides.add(AuthEnv.clientSecret);
    }

    var strict = false;
    final strictEnv = envValue(AuthEnv.strict);
    if (strictEnv != null) {
      final parsed = _parseBool(strictEnv);
      if (parsed != null) {
        overrides.add(AuthEnv.strict);
        strict = parsed;
      }
    }

    final publicUrl = _stripTrailingSlash(
      pick(AuthEnv.publicUrl, settings?.authPublicUrl ?? ''),
    );
    final origin = publicUrl.isNotEmpty
        ? publicUrl
        : _deriveOrigin(serverpodConfig?.webServer);

    return AuthConfig(
      loginRequired: loginRequired,
      issuer: issuer,
      clientId: clientId,
      clientSecret: secret,
      scopes: _orDefault(settings?.oidcScopes, 'openid email profile'),
      buttonLabel: _orDefault(settings?.oidcButtonLabel, 'Sign in with SSO'),
      allowedDomains: allowedDomains,
      adminEmails: adminEmails,
      redirectUri: origin.isEmpty ? '' : '$origin/auth/callback',
      appOrigin: origin,
      cookieSecure: origin.startsWith('https://'),
      strict: strict,
      envOverrides: overrides,
    );
  }

  /// Whether [email] may sign in.
  ///
  /// An empty [allowedDomains] allows everyone the provider authenticates,
  /// which is the documented default. Matching is on the full domain or a
  /// subdomain of it, so `uni.example` admits `a@uni.example` and
  /// `b@dept.uni.example` but never `c@evil-uni.example`.
  bool isEmailAllowed(String email) {
    if (allowedDomains.isEmpty) return true;
    final domain = _domainOf(email);
    if (domain.isEmpty) return false;
    return allowedDomains.any(
      (allowed) => domain == allowed || domain.endsWith('.$allowed'),
    );
  }

  /// Whether [email] gets the `admin` scope. Exact, case-insensitive match.
  bool isAdminEmail(String email) =>
      adminEmails.contains(email.trim().toLowerCase());

  static String _domainOf(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0 || at == email.length - 1) return '';
    return email.substring(at + 1).trim().toLowerCase();
  }

  /// Accepts a domain written either as `uni.example` or as `@uni.example`,
  /// because both look right to someone filling in an allowlist.
  static String _stripLeadingAt(String domain) =>
      domain.startsWith('@') ? domain.substring(1) : domain;

  static List<String> _splitList(String raw) => raw
      .split(RegExp(r'[,\s;]+'))
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  static String _orDefault(String? value, String fallback) =>
      (value == null || value.trim().isEmpty) ? fallback : value.trim();

  /// A trailing slash on the issuer is the classic cause of a discovery 404,
  /// because the well-known path is appended to it.
  static String _stripTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static bool? _parseBool(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
      default:
        return null;
    }
  }

  /// Builds the origin from the web server's public address.
  ///
  /// Only correct when nothing sits in front of the server. Behind the reverse
  /// proxy this deployment assumes, the browser is at `https://host` while the
  /// server still thinks it is at `http://host:9082` — which is why
  /// [AuthEnv.publicUrl] and [Settings.authPublicUrl] exist and why the settings
  /// tab shows the computed redirect URI.
  static String _deriveOrigin(ServerConfig? webServer) {
    if (webServer == null) return '';
    final scheme = webServer.publicScheme;
    final host = webServer.publicHost;
    final port = webServer.publicPort;
    if (host.isEmpty) return '';
    final isDefaultPort =
        (scheme == 'https' && port == 443) || (scheme == 'http' && port == 80);
    return isDefaultPort ? '$scheme://$host' : '$scheme://$host:$port';
  }
}
