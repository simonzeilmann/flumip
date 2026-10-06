import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/auth/auth_runtime.dart';
import 'package:flumip_server/src/auth/authentication_handler.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/auth/auth_tokens.dart';
import 'package:flumip_server/src/services/auth_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_http_json_client.dart';
import '../support/matchers.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Who may reach the settings, and how.
///
/// Its own file rather than a group in `settings_service_test.dart`: these need
/// an [AuthRuntime] that can be made to enforce, and `withServerpod` group
/// bodies run at collection time — so registering a different fake in a second
/// group of that file would leave only one of them active for both.
void main() {
  const issuer = 'https://idp.example.org';
  final http = FakeHttpJsonClient();

  withServerpod('Settings access', (sessionBuilder, endpoints) {
    setup(
      httpClient: http,
      authRuntime: AuthRuntime(environment: const {}),
    );
    final session = sessionBuilder.build();
    final settingsService = SettingsService();

    setUp(() async {
      http.reset();
      await sl<AuthRuntime>().refresh(session);
    });

    Future<void> enforceSso() async {
      final settings = await settingsService.getSettings(session);
      settings
        ..loginRequired = true
        ..oidcIssuer = issuer
        ..oidcClientId = 'flumip'
        ..oidcClientSecret = 's3cret'
        ..authPublicUrl = 'https://flumip.example';
      await Settings.db.updateRow(session, settings);
      http.stubProvider(issuer: issuer);
      await sl<AuthRuntime>().refresh(session);
      expect(
        sl<AuthRuntime>().isEnforcing,
        isTrue,
        reason: 'the test setup itself must actually close the gate',
      );
    }

    /// A session builder carrying the given scopes, with no seeded rows: the
    /// settings gate reads `session.authenticated.scopes` and nothing else.
    TestSessionBuilder signedIn(String email, {bool isAdmin = false}) {
      return sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          email,
          isAdmin ? {adminScope} : const <Scope>{},
        ),
      );
    }

    group('while sign-in is not enforced', () {
      test('the settings password still works', () async {
        // The only way in on an install with no identities, so this must not
        // regress — it is how a default deployment is configured at all.
        await settingsService.getSettings(session);
        final settings = await settingsService.getSettingsExternal(
          session,
          'changeme',
        );
        expect(settings.baseDir, '/opt/flumip');
      }, tags: ['unit']);

      test('a wrong password is still refused', () async {
        await settingsService.getSettings(session);
        await expectLater(
          settingsService.getSettingsExternal(session, 'wrong'),
          throwsMessage('This password is not correct.'),
        );
      }, tags: ['unit']);

      test('userSettings offers the password and claims no admin', () async {
        final access = await endpoints.settings.userSettings(sessionBuilder);
        expect(access.isAdmin, isFalse);
        expect(access.passwordAccepted, isTrue);
      }, tags: ['integration']);
    });

    group('once sign-in is enforced', () {
      test('the settings password stops being accepted', () async {
        // The change: identity becomes the only way in, so a user who knows the
        // shared password cannot reach an administrator's settings with it.
        await enforceSso();
        await expectLater(
          settingsService.getSettingsExternal(session, 'changeme'),
          throwsMessage('This password is not correct.'),
        );
      }, tags: ['unit']);

      test('a signed-in non-admin cannot use the password either', () async {
        await enforceSso();
        await expectLater(
          endpoints.settings.getSettings(
            signedIn('alice@uni.example'),
            'changeme',
          ),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);

      test('an admin gets the settings with no password at all', () async {
        await enforceSso();
        final settings = await endpoints.settings.getSettings(
          signedIn('boss@uni.example', isAdmin: true),
          null,
        );
        expect(settings.baseDir, '/opt/flumip');
      }, tags: ['integration']);

      test('userSettings tells an admin not to ask for a password', () async {
        await enforceSso();
        final access = await endpoints.settings.userSettings(
          signedIn('boss@uni.example', isAdmin: true),
        );
        expect(access.isAdmin, isTrue);
        expect(access.passwordAccepted, isFalse);
      }, tags: ['integration']);

      test('userSettings offers a non-admin nothing', () async {
        // Which is what makes the tab render the "no settings available" view
        // rather than a password box that would be refused.
        await enforceSso();
        final access = await endpoints.settings.userSettings(
          signedIn('alice@uni.example'),
        );
        expect(access.isAdmin, isFalse);
        expect(access.passwordAccepted, isFalse);
      }, tags: ['integration']);
    });

    group('switching sign-in off', () {
      test('ends every session, including the admin who switched it', () async {
        await enforceSso();
        final alice = await seedSignedInUser(session, email: 'a@uni.example');
        final boss = await seedSignedInUser(
          session,
          email: 'boss@uni.example',
          isAdmin: true,
        );
        expect(await AuthSession.db.find(session), hasLength(2));

        final settings = await settingsService.getSettings(session);
        settings.loginRequired = false;
        await endpoints.settings.updateSettings(
          signedIn('boss@uni.example', isAdmin: true),
          null,
          settings,
        );

        // Both, not just the ordinary user: there is nothing left to be signed
        // in to, so the administrator goes too.
        expect(await AuthSession.db.find(session), isEmpty);
        expect(
          await AuthApiToken.db.find(session),
          isEmpty,
          reason: 'the cascade takes the bearers with the sessions',
        );
        // Referenced so the seeding is not mistaken for dead setup.
        expect(alice.user.id, isNotNull);
        expect(boss.user.id, isNotNull);
      }, tags: ['integration']);

      test('a saved change that leaves sign-in on keeps sessions', () async {
        // Only the transition ends sessions. Saving any other setting while
        // sign-in stays on must not sign the whole institute out.
        await enforceSso();
        await seedSignedInUser(session, email: 'a@uni.example');

        final settings = await settingsService.getSettings(session);
        settings.smtpServer = 'smtp.example.org';
        await endpoints.settings.updateSettings(
          signedIn('boss@uni.example', isAdmin: true),
          null,
          settings,
        );

        expect(await AuthSession.db.find(session), hasLength(1));
      }, tags: ['integration']);

      test('the revoked bearer is refused on the very next call', () async {
        // The regression test that matters. Deleting the rows is not enough:
        // the bearer lookup is a read-through localPrio cache, so a row deleted
        // underneath it keeps answering until the entry ages out. This warms the
        // cache first, exactly as a real request would have.
        await enforceSso();
        final alice = await seedSignedInUser(session, email: 'a@uni.example');
        const token = 'a-bearer-for-alice';
        await AuthApiToken.db.insertRow(
          session,
          AuthApiToken(
            authSessionId: alice.authSession.id!,
            tokenHash: AuthTokens.sha256Hex(token),
            email: 'a@uni.example',
            expires: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        );

        expect(
          await sl<AuthService>().resolveApiToken(session, token),
          isNotNull,
          reason: 'the cache is now warm, which is the point',
        );

        final settings = await settingsService.getSettings(session);
        settings.loginRequired = false;
        await endpoints.settings.updateSettings(
          signedIn('boss@uni.example', isAdmin: true),
          null,
          settings,
        );

        expect(await sl<AuthService>().resolveApiToken(session, token), isNull);
      }, tags: ['integration']);
    });

    test(
      'an admin session works even before the runtime is consulted',
      () async {
        // _isAdmin checks the scope first and returns before looking at the
        // runtime at all, so an admin is unaffected by anything to do with
        // enforcement or a half-initialised process.
        final settings = await endpoints.settings.getSettings(
          signedIn('boss@uni.example', isAdmin: true),
          null,
        );
        expect(settings.baseDir, '/opt/flumip');
      },
      tags: ['integration'],
    );
  });
}
