import 'package:flumip_flutter/auth/session_auth_key_provider.dart';
import 'package:flumip_flutter/auth/signed_in_menu.dart';
import 'package:flumip_flutter/ui/layout.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who is signed in, and whether saying so fits in the app bar.
///
/// ⚠️ These tests could not exist while this widget lived in `main.dart`, which
/// imports `dart:js_interop` and therefore cannot be compiled for the VM. The
/// unconstrained label that overflowed the bar survived precisely because nothing
/// could pump it. That is the argument `platform_boundary_test.dart` makes, and
/// this is a worked example of it.
SessionTokenResponse userFixture({
  String email = 'jo.researcher@example.org',
  String displayName = '',
  bool isAdmin = false,
}) => SessionTokenResponse(
  token: 'token',
  expiresIn: const Duration(hours: 1),
  email: email,
  displayName: displayName,
  isAdmin: isAdmin,
);

void main() {
  /// The menu on its own, for the behaviour tests.
  Future<List<String>> pumpMenu(
    WidgetTester tester, {
    SessionTokenResponse? user,
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SignedInMenu(
                user: user ?? userFixture(),
                onSignOut: () => calls.add('signOut'),
              ),
            ],
          ),
        ),
      ),
    );
    return calls;
  }

  /// `main.dart`'s app bar, reproduced — a centred title, a scrollable `TabBar`
  /// and this menu. The arrangement the overflow actually happened in.
  Future<void> pumpAppBar(
    WidgetTester tester,
    double width, {
    SessionTokenResponse? user,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Flumip'),
              centerTitle: true,
              actions: [
                SignedInMenu(user: user ?? userFixture(), onSignOut: () {}),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [
                  Tab(text: 'Projects', icon: Icon(Icons.folder)),
                  Tab(text: 'Genomes & SNP', icon: Icon(Icons.dns)),
                  Tab(text: 'Settings', icon: Icon(Icons.settings)),
                ],
              ),
            ),
            body: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('⚠️ it fits in the app bar', () {
    // The reported bug: at 375px this arrangement overflowed by 29 pixels, which
    // is a thrown exception in a test and a yellow-and-black stripe across the app
    // bar in the browser. A long address is the normal case, not the edge one.
    testWidgets('at a phone width', (tester) async {
      await pumpAppBar(tester, 375);

      expect(tester.takeException(), isNull);
    });

    testWidgets('at a phone width, with a very long address', (tester) async {
      await pumpAppBar(
        tester,
        375,
        user: userFixture(
          email: 'a.very.long.name.indeed@some-long-domain.example',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('just below the breakpoint', (tester) async {
      await pumpAppBar(tester, kSplitWidth - 1);

      expect(tester.takeException(), isNull);
    });

    testWidgets('at the breakpoint', (tester) async {
      await pumpAppBar(tester, kSplitWidth);

      expect(tester.takeException(), isNull);
    });

    testWidgets('⚠️ at the breakpoint, with an address past the cap', (
      tester,
    ) async {
      // The label has a hard ceiling, so an address of any length is a ceiling's
      // worth of pixels and an ellipsis. Without it the bar grows to fit the text.
      await pumpAppBar(
        tester,
        kSplitWidth,
        user: userFixture(
          email:
              'this.is.a.deliberately.enormous.address@an.equally.long.example.org',
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('on a wide monitor', (tester) async {
      await pumpAppBar(tester, 2560);

      expect(tester.takeException(), isNull);
    });
  });

  group('what it shows', () {
    testWidgets('the address, when the provider sent no display name', (
      tester,
    ) async {
      await pumpMenu(tester);

      expect(find.text('jo.researcher@example.org'), findsOneWidget);
    });

    testWidgets('the display name in preference to the address', (
      tester,
    ) async {
      await pumpMenu(tester, user: userFixture(displayName: 'Simon Zeilmann'));

      expect(find.text('Simon Zeilmann'), findsOneWidget);
      // The address is still reachable, in the tooltip.
      expect(find.text('jo.researcher@example.org'), findsNothing);
    });

    testWidgets('⚠️ a narrow window drops the label, not just shortens it', (
      tester,
    ) async {
      // An ellipsised fragment of an address costs the width of a word and says
      // nothing the tooltip does not.
      await pumpMenu(tester, width: 500);

      expect(find.text('jo.researcher@example.org'), findsNothing);
      // …so the identity moves into the one control that is left.
      expect(
        find.byTooltip('Sign out — jo.researcher@example.org'),
        findsOneWidget,
      );
    });

    testWidgets('an administrator is marked as one', (tester) async {
      await pumpMenu(tester, user: userFixture(isAdmin: true));

      expect(
        find.byTooltip('jo.researcher@example.org (administrator)'),
        findsOneWidget,
      );
    });

    testWidgets('signing out calls back', (tester) async {
      final calls = await pumpMenu(tester);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(calls, ['signOut']);
    });

    testWidgets('signing out works on a narrow window too', (tester) async {
      final calls = await pumpMenu(tester, width: 500);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(calls, ['signOut']);
    });
  });
}
