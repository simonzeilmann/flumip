import 'package:flumip_flutter/app.dart';
import 'package:flumip_flutter/auth/auth_controller.dart';
import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flumip_flutter/auth/signed_in_menu.dart';
import 'package:flumip_flutter/search/search_dialog.dart';
import 'package:flumip_flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell: the sign-in gate, the app bar, the tab order and the footer.
///
/// ⚠️ **None of this could be tested while it lived in `main.dart`**, which
/// imports `dart:js_interop` and so does not compile on the VM at all. It moved
/// to `app.dart` with its dependencies as optional parameters; these tests pass
/// fakes for every one of them. The real tabs are replaced with stand-ins
/// because they fetch through the app-wide client the moment they are built,
/// and there is no server here — each tab has its own test file for that.
void main() {
  const session = SessionTokenResponse(
    token: 'a-token',
    expiresIn: Duration(minutes: 30),
    email: 'jo.researcher@example.org',
    displayName: 'Jo Researcher',
  );

  /// Where sign-in and sign-out navigations went.
  late List<String> navigations;

  setUp(() => navigations = []);

  /// An [AuthController] that bootstraps to the state a test asks for, without a
  /// server: [enabled] is what the server's config says, [user] is the session
  /// the cookie would have yielded.
  Future<AuthController> authFor({
    required bool enabled,
    SessionTokenResponse? user,
  }) async {
    final auth = AuthController(
      navigate: navigations.add,
      fetchConfig: () async =>
          AuthConfigSnapshot(enabled: enabled, buttonLabel: 'Sign in with Uni'),
      fetchSession: () async => user,
    );
    await auth.bootstrap();
    return auth;
  }

  const standIns = [
    Center(child: Text('projects pane')),
    Center(child: Text('genomes pane')),
    Center(child: Text('settings pane')),
  ];

  Future<void> pumpHome(
    WidgetTester tester, {
    required AuthController auth,
    void Function(String url)? openUrl,
    String version = '1.2.3',
  }) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MyApp(
        auth: auth,
        home: MyHomePage(
          title: 'FLUMIP Test',
          version: version,
          auth: auth,
          tabs: standIns,
          openUrl: openUrl ?? (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the sign-in gate', () {
    testWidgets('a spinner until the server has answered', (tester) async {
      // Not bootstrapped, so still `unknown` — the state the app is in for the
      // length of the first request.
      final auth = AuthController(
        navigate: navigations.add,
        fetchConfig: () async =>
            const AuthConfigSnapshot(enabled: false, buttonLabel: 'x'),
        fetchSession: () async => null,
      );

      await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('the app'), findsNothing);

      await auth.bootstrap();
      await tester.pump();

      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets('⚠️ a default install goes straight to the app', (
      tester,
    ) async {
      // The standard case: no sign-in configured, and the gate must not be
      // visible in any way.
      final auth = await authFor(enabled: false);

      await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));

      expect(find.text('the app'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('signed in goes to the app', (tester) async {
      final auth = await authFor(enabled: true, user: session);

      await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));

      expect(find.text('the app'), findsOneWidget);
    });

    testWidgets(
      'signed out shows the sign-in screen, with the server\'s label',
      (tester) async {
        final auth = await authFor(enabled: true);

        await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));

        expect(find.text('the app'), findsNothing);
        expect(
          find.text('This FLUMIP server requires you to sign in.'),
          findsOneWidget,
        );
        expect(find.text('Sign in with Uni'), findsOneWidget);
      },
    );

    testWidgets('the sign-in button navigates to the login route', (
      tester,
    ) async {
      final auth = await authFor(enabled: true);
      await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));

      await tester.tap(find.text('Sign in with Uni'));

      expect(navigations, ['$siteUrl/auth/login']);
    });

    testWidgets('losing the session swaps the app for the sign-in screen', (
      tester,
    ) async {
      var user = session as SessionTokenResponse?;
      final auth = AuthController(
        navigate: navigations.add,
        fetchConfig: () async =>
            const AuthConfigSnapshot(enabled: true, buttonLabel: 'Sign in'),
        fetchSession: () async => user,
      );
      await auth.bootstrap();
      await tester.pumpWidget(MyApp(auth: auth, home: const Text('the app')));
      expect(find.text('the app'), findsOneWidget);

      user = null;
      await auth.revalidate();
      await tester.pump();

      expect(find.text('the app'), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
    });
  });

  group('the home page', () {
    testWidgets('⚠️ the TabBar order matches the indices search sends to', (
      tester,
    ) async {
      // `openSearchHit` moves to `projectsTabIndex` and `genomesTabIndex`;
      // nothing but this test holds those numbers to the tabs actually at those
      // positions. Insert a tab in the middle and every search result lands in
      // the wrong pane.
      await pumpHome(tester, auth: await authFor(enabled: false));

      final tabs = tester.widget<TabBar>(find.byType(TabBar)).tabs.cast<Tab>();
      expect(tabs.map((t) => t.text), [
        'Projects',
        'Genomes & SNP',
        'Settings',
      ]);
      expect(tabs[projectsTabIndex].text, 'Projects');
      expect(tabs[genomesTabIndex].text, 'Genomes & SNP');
    });

    testWidgets('the tabs switch panes', (tester) async {
      await pumpHome(tester, auth: await authFor(enabled: false));

      expect(find.text('projects pane'), findsOneWidget);

      await tester.tap(find.text('Genomes & SNP'));
      await tester.pumpAndSettle();
      expect(find.text('genomes pane'), findsOneWidget);
      expect(find.text('projects pane'), findsNothing);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings pane'), findsOneWidget);
    });

    testWidgets('the title and the version are shown', (tester) async {
      await pumpHome(tester, auth: await authFor(enabled: false));

      expect(find.text('FLUMIP Test'), findsOneWidget);
      expect(find.text('v: 1.2.3'), findsOneWidget);
    });

    testWidgets('no account menu on a default install', (tester) async {
      await pumpHome(tester, auth: await authFor(enabled: false));

      expect(find.byType(SignedInMenu), findsNothing);
    });

    testWidgets('signed in shows the account menu, and it signs out', (
      tester,
    ) async {
      await pumpHome(tester, auth: await authFor(enabled: true, user: session));

      expect(find.byType(SignedInMenu), findsOneWidget);
      expect(find.text('Jo Researcher'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));

      expect(navigations, ['$siteUrl/auth/logout']);
    });

    testWidgets('the GitHub link opens the repository', (tester) async {
      final opened = <String>[];
      await pumpHome(
        tester,
        auth: await authFor(enabled: false),
        openUrl: opened.add,
      );

      await tester.tap(find.textContaining('Github:'));

      expect(opened, ['https://github.com/simonzeilmann/flumip']);
    });

    for (final (name, modifier) in [
      ('Ctrl+K', LogicalKeyboardKey.controlLeft),
      ('Cmd+K', LogicalKeyboardKey.metaLeft),
    ]) {
      testWidgets('⚠️ $name opens search with nothing clicked first', (
        tester,
      ) async {
        // The `Focus(autofocus: true)` in the shell is what makes this work;
        // without it the key event goes to the root scope, above the binding.
        await pumpHome(tester, auth: await authFor(enabled: false));
        expect(find.byType(SearchDialog), findsNothing);

        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();

        expect(find.byType(SearchDialog), findsOneWidget);
      });
    }
  });
}
