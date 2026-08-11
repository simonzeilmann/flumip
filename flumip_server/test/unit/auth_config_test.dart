import 'package:flumip_server/src/auth/auth_config.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

/// Pure tests: [AuthConfig.resolve] does no I/O, so none of this needs a
/// database, a server or a network. These cover the precedence rules that decide
/// whether an install is reachable at all, so they are the load-bearing tests of
/// the whole authentication change.
void main() {
  Settings storedSettings({
    bool loginRequired = false,
    String issuer = '',
    String clientId = '',
    String? clientSecret,
    String adminEmails = '',
    String allowedDomains = '',
    String publicUrl = '',
    String scopes = 'openid email profile',
    String buttonLabel = 'Sign in with SSO',
  }) => Settings(
    loginRequired: loginRequired,
    oidcIssuer: issuer,
    oidcClientId: clientId,
    oidcClientSecret: clientSecret,
    oidcAdminEmails: adminEmails,
    oidcAllowedEmailDomains: allowedDomains,
    oidcScopes: scopes,
    oidcButtonLabel: buttonLabel,
    authPublicUrl: publicUrl,
  );

  ServerpodConfig configWithWebServer({
    required String scheme,
    required String host,
    required int port,
  }) => ServerpodConfig(
    apiServer: ServerConfig(
      port: 8080,
      publicHost: host,
      publicPort: 8080,
      publicScheme: scheme,
    ),
    webServer: ServerConfig(
      port: port,
      publicHost: host,
      publicPort: port,
      publicScheme: scheme,
    ),
  );

  /// A configuration complete enough that only the enabling flag is in question.
  Settings complete({bool loginRequired = true}) => storedSettings(
    loginRequired: loginRequired,
    issuer: 'https://idp.example.org',
    clientId: 'flumip',
    clientSecret: 's3cret',
  );

  group('defaults', () {
    test('no settings and no environment means authentication is off', () {
      final config = AuthConfig.resolve(env: const {});
      expect(config.loginRequired, isFalse);
      expect(config.isComplete, isFalse);
      expect(config.isEnforcing(hasDiscovery: true), isFalse);
      expect(config.envOverrides, isEmpty);
    });

    test('a default settings row means authentication is off', () {
      final config = AuthConfig.resolve(settings: Settings(), env: const {});
      expect(config.loginRequired, isFalse);
      expect(config.isEnforcing(hasDiscovery: true), isFalse);
    });
  });

  group('FLUMIP_AUTH_ENABLED overrides in both directions', () {
    test('false beats a stored true — this is the break-glass switch', () {
      final config = AuthConfig.resolve(
        settings: complete(loginRequired: true),
        env: const {AuthEnv.enabled: 'false'},
      );
      expect(config.loginRequired, isFalse);
      expect(config.isEnforcing(hasDiscovery: true), isFalse);
      expect(config.envOverrides, contains(AuthEnv.enabled));
    });

    test('true beats a stored false', () {
      final config = AuthConfig.resolve(
        settings: complete(loginRequired: false),
        env: const {AuthEnv.enabled: 'true'},
      );
      expect(config.loginRequired, isTrue);
      expect(config.isEnforcing(hasDiscovery: true), isTrue);
    });

    test('unset falls through to the stored value', () {
      final config = AuthConfig.resolve(
        settings: complete(loginRequired: true),
        env: const {},
      );
      expect(config.loginRequired, isTrue);
      expect(config.envOverrides, isNot(contains(AuthEnv.enabled)));
    });

    test('blank counts as unset, not as false', () {
      final config = AuthConfig.resolve(
        settings: complete(loginRequired: true),
        env: const {AuthEnv.enabled: '  '},
      );
      expect(config.loginRequired, isTrue);
      expect(config.envOverrides, isNot(contains(AuthEnv.enabled)));
    });

    test('unparseable counts as unset rather than silently disabling', () {
      final config = AuthConfig.resolve(
        settings: complete(loginRequired: true),
        env: const {AuthEnv.enabled: 'maybe'},
      );
      expect(config.loginRequired, isTrue);
    });

    for (final truthy in ['true', 'TRUE', '1', 'yes', 'on']) {
      test('"$truthy" enables', () {
        final config = AuthConfig.resolve(
          settings: complete(loginRequired: false),
          env: {AuthEnv.enabled: truthy},
        );
        expect(config.loginRequired, isTrue);
      });
    }

    for (final falsy in ['false', 'FALSE', '0', 'no', 'off']) {
      test('"$falsy" disables', () {
        final config = AuthConfig.resolve(
          settings: complete(loginRequired: true),
          env: {AuthEnv.enabled: falsy},
        );
        expect(config.loginRequired, isFalse);
      });
    }
  });

  group('environment beats the database, per field', () {
    test('issuer, client id, admin emails and allowed domains', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(
          issuer: 'https://stored.example.org',
          clientId: 'stored-client',
          adminEmails: 'stored@example.org',
          allowedDomains: 'stored.example.org',
        ),
        env: const {
          AuthEnv.issuer: 'https://env.example.org',
          AuthEnv.clientId: 'env-client',
          AuthEnv.adminEmails: 'env@example.org',
          AuthEnv.allowedDomains: 'env.example.org',
        },
      );
      expect(config.issuer, 'https://env.example.org');
      expect(config.clientId, 'env-client');
      expect(config.adminEmails, ['env@example.org']);
      expect(config.allowedDomains, ['env.example.org']);
      expect(
        config.envOverrides,
        containsAll([
          AuthEnv.issuer,
          AuthEnv.clientId,
          AuthEnv.adminEmails,
          AuthEnv.allowedDomains,
        ]),
      );
    });

    test('a blank environment value leaves the stored value alone', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(issuer: 'https://stored.example.org'),
        env: const {AuthEnv.issuer: ''},
      );
      expect(config.issuer, 'https://stored.example.org');
      expect(config.envOverrides, isEmpty);
    });

    test('the resolved client secret wins over the stored one', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(clientSecret: 'from-db'),
        env: const {AuthEnv.clientSecret: 'from-env'},
        clientSecret: 'from-env',
      );
      expect(config.clientSecret, 'from-env');
      expect(config.envOverrides, contains(AuthEnv.clientSecret));
    });

    test('the stored secret is used when no password is configured', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(clientSecret: 'from-db'),
        env: const {},
      );
      expect(config.clientSecret, 'from-db');
      expect(config.envOverrides, isEmpty);
    });
  });

  group('isEnforcing fails open on an incomplete configuration', () {
    test('enabled but no issuer does not enforce', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(
          loginRequired: true,
          clientId: 'flumip',
          clientSecret: 's3cret',
        ),
        env: const {},
      );
      expect(config.loginRequired, isTrue);
      expect(config.isComplete, isFalse);
      expect(config.isEnforcing(hasDiscovery: true), isFalse);
    });

    test('enabled but no client secret does not enforce', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(
          loginRequired: true,
          issuer: 'https://idp.example.org',
          clientId: 'flumip',
        ),
        env: const {},
      );
      expect(config.isComplete, isFalse);
      expect(config.isEnforcing(hasDiscovery: true), isFalse);
    });

    test('complete but discovery never succeeded does not enforce', () {
      final config = AuthConfig.resolve(settings: complete(), env: const {});
      expect(config.isComplete, isTrue);
      expect(config.isEnforcing(hasDiscovery: false), isFalse);
    });

    test('complete with discovery enforces', () {
      final config = AuthConfig.resolve(settings: complete(), env: const {});
      expect(config.isEnforcing(hasDiscovery: true), isTrue);
    });

    test('FLUMIP_AUTH_STRICT enforces even when incomplete', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(loginRequired: true),
        env: const {AuthEnv.strict: 'true'},
      );
      expect(config.strict, isTrue);
      expect(config.isComplete, isFalse);
      expect(config.isEnforcing(hasDiscovery: false), isTrue);
    });

    test('FLUMIP_AUTH_STRICT never enforces when login is not required', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(loginRequired: false),
        env: const {AuthEnv.strict: 'true'},
      );
      expect(config.isEnforcing(hasDiscovery: false), isFalse);
    });
  });

  group('redirect URI derivation', () {
    test('https on 443 omits the port', () {
      final config = AuthConfig.resolve(
        env: const {},
        serverpodConfig: configWithWebServer(
          scheme: 'https',
          host: 'flumip.example.org',
          port: 443,
        ),
      );
      expect(config.appOrigin, 'https://flumip.example.org');
      expect(config.redirectUri, 'https://flumip.example.org/auth/callback');
      expect(config.cookieSecure, isTrue);
    });

    test('http on 80 omits the port', () {
      final config = AuthConfig.resolve(
        env: const {},
        serverpodConfig: configWithWebServer(
          scheme: 'http',
          host: 'flumip.example.org',
          port: 80,
        ),
      );
      expect(config.redirectUri, 'http://flumip.example.org/auth/callback');
      expect(config.cookieSecure, isFalse);
    });

    test('a non-default port is kept', () {
      final config = AuthConfig.resolve(
        env: const {},
        serverpodConfig: configWithWebServer(
          scheme: 'http',
          host: 'demo.example.org',
          port: 8092,
        ),
      );
      expect(config.redirectUri, 'http://demo.example.org:8092/auth/callback');
    });

    test('authPublicUrl wins over the derived origin', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(publicUrl: 'https://flumip.uni.example'),
        env: const {},
        serverpodConfig: configWithWebServer(
          scheme: 'http',
          host: 'internal',
          port: 8092,
        ),
      );
      expect(config.redirectUri, 'https://flumip.uni.example/auth/callback');
      expect(config.cookieSecure, isTrue);
    });

    test('FLUMIP_PUBLIC_URL wins over authPublicUrl', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(publicUrl: 'https://stored.example.org'),
        env: const {AuthEnv.publicUrl: 'https://env.example.org'},
      );
      expect(config.redirectUri, 'https://env.example.org/auth/callback');
      expect(config.envOverrides, contains(AuthEnv.publicUrl));
    });

    test('a trailing slash on the public URL does not double up', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(publicUrl: 'https://flumip.example.org/'),
        env: const {},
      );
      expect(config.redirectUri, 'https://flumip.example.org/auth/callback');
    });

    test('no web server and no public URL yields no redirect URI', () {
      final config = AuthConfig.resolve(env: const {});
      expect(config.redirectUri, isEmpty);
      expect(config.appOrigin, isEmpty);
    });
  });

  group('issuer normalisation', () {
    test('a trailing slash is stripped', () {
      // Left in place it produces `…//.well-known/openid-configuration`, which
      // most providers answer with a 404.
      final config = AuthConfig.resolve(
        settings: storedSettings(issuer: 'https://idp.example.org/realms/x/'),
        env: const {},
      );
      expect(config.issuer, 'https://idp.example.org/realms/x');
    });

    test('surrounding whitespace is stripped', () {
      final config = AuthConfig.resolve(
        env: const {AuthEnv.issuer: '  https://idp.example.org  '},
      );
      expect(config.issuer, 'https://idp.example.org');
    });
  });

  group('isEmailAllowed', () {
    AuthConfig withDomains(String domains) => AuthConfig.resolve(
      settings: storedSettings(allowedDomains: domains),
      env: const {},
    );

    test('an empty allowlist admits everyone', () {
      final config = withDomains('');
      expect(config.allowedDomains, isEmpty);
      expect(config.isEmailAllowed('anyone@anywhere.example'), isTrue);
    });

    test('an exact domain match is admitted', () {
      expect(
        withDomains('uni.example').isEmailAllowed('a@uni.example'),
        isTrue,
      );
    });

    test('a subdomain of an allowed domain is admitted', () {
      expect(
        withDomains('uni.example').isEmailAllowed('a@dept.uni.example'),
        isTrue,
      );
    });

    test('a domain that merely ends with the allowed one is refused', () {
      // The bug this guards against: a naive `endsWith` admits evil-uni.example
      // for an allowlist of uni.example.
      expect(
        withDomains('uni.example').isEmailAllowed('a@evil-uni.example'),
        isFalse,
      );
    });

    test('matching is case-insensitive on both sides', () {
      expect(
        withDomains('UNI.example').isEmailAllowed('A@Uni.EXAMPLE'),
        isTrue,
      );
    });

    test('an unrelated domain is refused', () {
      expect(
        withDomains('uni.example').isEmailAllowed('a@other.example'),
        isFalse,
      );
    });

    test('a malformed address is refused', () {
      final config = withDomains('uni.example');
      expect(config.isEmailAllowed('not-an-email'), isFalse);
      expect(config.isEmailAllowed('trailing@'), isFalse);
      expect(config.isEmailAllowed(''), isFalse);
    });

    test('domains may be written with or without a leading @', () {
      expect(
        withDomains('@uni.example').isEmailAllowed('a@uni.example'),
        isTrue,
      );
    });

    test('several domains may be given, comma or space separated', () {
      final config = withDomains('uni.example, other.example\nthird.example');
      expect(config.allowedDomains, hasLength(3));
      expect(config.isEmailAllowed('a@other.example'), isTrue);
      expect(config.isEmailAllowed('a@third.example'), isTrue);
      expect(config.isEmailAllowed('a@fourth.example'), isFalse);
    });
  });

  group('isAdminEmail', () {
    test('an exact, case-insensitive match grants admin', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(adminEmails: 'Boss@Uni.example'),
        env: const {},
      );
      expect(config.isAdminEmail('boss@uni.example'), isTrue);
      expect(config.isAdminEmail('BOSS@UNI.EXAMPLE'), isTrue);
    });

    test('a domain is not enough — admin is per address', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(adminEmails: 'boss@uni.example'),
        env: const {},
      );
      expect(config.isAdminEmail('someone@uni.example'), isFalse);
    });

    test('nobody is an admin by default', () {
      expect(
        AuthConfig.resolve(env: const {}).isAdminEmail('a@uni.example'),
        isFalse,
      );
    });
  });

  group('scopes and button label', () {
    test('fall back to their defaults when stored blank', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(scopes: '', buttonLabel: ''),
        env: const {},
      );
      expect(config.scopes, 'openid email profile');
      expect(config.buttonLabel, 'Sign in with SSO');
    });

    test('are taken from the settings when set', () {
      final config = AuthConfig.resolve(
        settings: storedSettings(
          scopes: 'openid email',
          buttonLabel: 'Uni login',
        ),
        env: const {},
      );
      expect(config.scopes, 'openid email');
      expect(config.buttonLabel, 'Uni login');
    });
  });
}
