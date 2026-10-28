import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/auth/auth_controller.dart';
import 'package:flumip_flutter/auth/public_notice_screen.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flumip_flutter/project/expiry.dart';
import 'package:flumip_flutter/share_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A public instance, from the app's side: the entry notice, the guest it
/// produces, share links and expiry dates. All VM-only — the I/O is injected.
void main() {
  const publicConfig = AuthConfigSnapshot(
    enabled: true,
    buttonLabel: 'Sign in',
    publicMode: true,
    imprintUrl: 'https://uni.example/imprint',
    privacyUrl: 'https://uni.example/privacy',
    projectRetention: Duration(days: 7),
    maxProjectLifetime: Duration(days: 30),
  );

  const guestSession = SessionTokenResponse(
    token: 'guest-token',
    expiresIn: Duration(minutes: 30),
    email: 'guest',
    isGuest: true,
  );

  AuthController controllerFor({
    SessionTokenResponse? existing,
    Future<SessionTokenResponse> Function()? accept,
  }) {
    // Once accepted, `/auth/session` answers with the cookie the accept set.
    var accepted = existing != null;
    return AuthController(
      navigate: (_) {},
      fetchConfig: () async => publicConfig,
      fetchSession: () async => accepted ? guestSession : null,
      acceptTerms:
          accept ??
          () async {
            accepted = true;
            return guestSession;
          },
    );
  }

  group('the entry notice', () {
    test('a first visit needs acceptance, not a sign-in', () async {
      final controller = controllerFor();
      await controller.bootstrap();
      expect(controller.state, AuthState.needsAcceptance);
      expect(controller.authKeyProvider, isNull);
    });

    test('a returning guest goes straight in', () async {
      final controller = controllerFor(existing: guestSession);
      await controller.bootstrap();
      expect(controller.state, AuthState.signedIn);
      expect(controller.user!.isGuest, isTrue);
    });

    test('accepting signs the visitor in as a guest', () async {
      final controller = controllerFor();
      await controller.bootstrap();

      await controller.accept();

      expect(controller.state, AuthState.signedIn);
      expect(controller.user!.isGuest, isTrue);
      expect(controller.authKeyProvider, isNotNull);
    });

    test('a failed accept leaves the notice up and says why', () async {
      final controller = controllerFor(
        accept: () async => throw Exception('server says no'),
      );
      await controller.bootstrap();

      await controller.accept();

      expect(controller.state, AuthState.needsAcceptance);
      expect(controller.errorMessage, contains('server says no'));
      expect(controller.accepting, isFalse);
    });

    testWidgets('blocks the app until accepted, then lets it through', (
      tester,
    ) async {
      final controller = controllerFor();
      await controller.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => controller.state == AuthState.signedIn
                ? const Text('the app')
                : PublicNoticeScreen(
                    auth: controller,
                    onSignIn: () {},
                    openUrl: (_) {},
                  ),
          ),
        ),
      );

      expect(find.text('the app'), findsNothing);
      expect(find.text(publicCookieNotice), findsOneWidget);
      expect(find.text(defaultPublicTerms), findsOneWidget);
      expect(find.text('Imprint'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);

      // The notice scrolls; the default test window is shorter than it.
      await tester.ensureVisible(find.text('Decline'));
      await tester.tap(find.text('Decline'));
      await tester.pump();
      expect(find.text('the app'), findsNothing);
      expect(find.textContaining('cannot be used without'), findsOneWidget);

      await tester.ensureVisible(find.text('Accept and continue'));
      await tester.tap(find.text('Accept and continue'));
      await tester.pumpAndSettle();
      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets("an administrator's own terms replace the default", (
      tester,
    ) async {
      final controller = AuthController(
        navigate: (_) {},
        fetchConfig: () async => const AuthConfigSnapshot(
          enabled: false,
          buttonLabel: 'Sign in',
          publicMode: true,
          publicNoticeText: 'For teaching only.',
        ),
        fetchSession: () async => null,
      );
      await controller.bootstrap();

      await tester.pumpWidget(
        MaterialApp(
          home: PublicNoticeScreen(
            auth: controller,
            onSignIn: () {},
            openUrl: (_) {},
          ),
        ),
      );

      expect(find.text('For teaching only.'), findsOneWidget);
      expect(find.text(defaultPublicTerms), findsNothing);
      // The cookie paragraph is not the administrator's to remove.
      expect(find.text(publicCookieNotice), findsOneWidget);
      // No provider configured, so no way to offer a sign-in.
      expect(find.text('Administrator sign-in'), findsNothing);
    });
  });

  group('share links', () {
    test('the token is read from the fragment', () {
      expect(
        shareTokenFrom(Uri.parse('https://mips.example/#/p/abc_DEF-123')),
        'abc_DEF-123',
      );
      expect(shareTokenFrom(Uri.parse('https://mips.example/#p/abc')), 'abc');
    });

    test('an ordinary visit has no token', () {
      expect(shareTokenFrom(Uri.parse('https://mips.example/')), isNull);
      expect(shareTokenFrom(Uri.parse('https://mips.example/#/other')), isNull);
    });

    test('waits for the notice to be accepted before opening', () async {
      final controller = controllerFor();
      await controller.bootstrap();
      final redeemed = <String>[];
      var cleared = false;

      ShareLinkOpener(
        auth: controller,
        redeem: (token) async {
          redeemed.add(token);
          return Project(name: 'shared', options: 1, id: 4);
        },
        reveal: (_) async {},
        clearLink: () => cleared = true,
        report: (_) {},
      ).start('the-token');

      await Future<void>.delayed(Duration.zero);
      expect(redeemed, isEmpty, reason: 'nothing answers before acceptance');

      await controller.accept();
      await Future<void>.delayed(Duration.zero);
      expect(redeemed, ['the-token']);
      expect(cleared, isTrue);
    });

    test('a withdrawn link says so', () async {
      final controller = controllerFor(existing: guestSession);
      await controller.bootstrap();
      String? reported;

      ShareLinkOpener(
        auth: controller,
        redeem: (_) async => throw FlumipFileNotFoundException(
          message: 'This link does not lead to a project any more.',
        ),
        reveal: (_) async {},
        clearLink: () {},
        report: (message) => reported = message,
      ).start('gone');

      await Future<void>.delayed(Duration.zero);
      expect(reported, contains('does not lead to a project'));
    });
  });

  group('expiry', () {
    final created = DateTime.utc(2026, 10, 1, 12);

    Project project({DateTime? expires}) =>
        Project(name: 'p', options: 1, created: created, expires: expires);

    test('nothing is deleted on a server that keeps projects', () {
      const keeps = AuthConfigSnapshot(enabled: false, buttonLabel: '');
      expect(deletionDate(project(), keeps), isNull);
      expect(canExtend(project(), keeps), isFalse);
    });

    test('a project kept indefinitely has no date', () {
      final kept = project(expires: created.add(const Duration(days: 7)))
        ..keptIndefinitely = true;
      expect(deletionDate(kept, publicConfig), isNull);
      expect(canExtend(kept, publicConfig), isFalse);
    });

    test('the stored date is shown', () {
      final expires = created.add(const Duration(days: 10));
      expect(deletionDate(project(expires: expires), publicConfig), expires);
    });

    test('never earlier than the current window, as the server applies', () {
      final floor = endOfDay(created.add(const Duration(days: 7)));
      expect(deletionDate(project(), publicConfig), floor);
      expect(
        deletionDate(
          project(expires: created.add(const Duration(days: 1))),
          publicConfig,
        ),
        floor,
      );
    });

    test('a project goes when its last day is over', () {
      final deadline = deletionDate(project(), publicConfig)!.toLocal();
      expect([deadline.hour, deadline.minute], [0, 0]);
    });

    test('the date shown is the last day kept, not the midnight after', () {
      final shown = lastDayKept(DateTime(2026, 11, 5));
      expect([shown.year, shown.month, shown.day], [2026, 11, 4]);
    });

    test('the end of a day that is already midnight is itself', () {
      // Otherwise a stored deadline would creep a day later on every pass.
      expect(endOfDay(DateTime(2026, 11, 4)), DateTime(2026, 11, 4).toUtc());
    });

    test('Keep longer is offered until the maximum', () {
      expect(
        canExtend(
          project(expires: endOfDay(created.add(const Duration(days: 7)))),
          publicConfig,
        ),
        isTrue,
      );
      expect(
        canExtend(
          project(expires: endOfDay(created.add(const Duration(days: 30)))),
          publicConfig,
        ),
        isFalse,
      );
    });

    test('windows read as words', () {
      expect(describeRetention(const Duration(days: 7)), '7 days');
      expect(describeRetention(const Duration(days: 1)), '1 day');
      expect(describeRetention(const Duration(hours: 36)), '36 hours');
    });
  });
}
