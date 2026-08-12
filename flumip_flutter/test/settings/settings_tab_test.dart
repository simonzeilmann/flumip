import 'package:flumip_flutter/settings/settings_tab.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'settings_controller_test.dart' show Harness, accessFixture;
import 'settings_form_test.dart' show settingsFixture;

/// The settings tab, pumped whole.
///
/// ⚠️ The five branches are the point. Getting the order wrong is what produced
/// the two bugs this replaced — an administrator shown a password box for a
/// password they did not need, and an ordinary user shown one that worked — and
/// until now nothing could check them.
Future<Harness> pumpTab(WidgetTester tester, Harness harness) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: SettingsTab(controller: harness.controller)),
    ),
  );
  return harness;
}

void main() {
  testWidgets('a spinner while the access question is out', (tester) async {
    final h = Harness(access: accessFixture(isAdmin: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
  });

  testWidgets('⚠️ a failed access question shows the retry AND the reason', (
    tester,
  ) async {
    // The banner comes from the shell, not the branch. Move it into the admin
    // form and this becomes an unexplained button on a blank screen.
    final h = Harness()..accessThrows = Exception('no route to host');
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not determine your access'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an install without sign-in asks for the password', (
    tester,
  ) async {
    final h = Harness(access: accessFixture(passwordAccepted: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Storage'), findsNothing);
  });

  testWidgets('a signed-in non-administrator is told there is nothing here', (
    tester,
  ) async {
    final h = Harness(access: accessFixture());
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('No settings available'), findsOneWidget);
  });

  testWidgets('an administrator gets the form and the save bar', (
    tester,
  ) async {
    final h = Harness(access: accessFixture(isAdmin: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    for (final section in [
      'Storage',
      'External tools',
      'Mail',
      'Sign-in',
      'Security',
    ]) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
    expect(find.text('Update settings'), findsOneWidget);
  });

  testWidgets('⚠️ only the admin form gets a save bar', (tester) async {
    // A Save button on the password gate would submit nothing.
    final h = Harness(access: accessFixture(passwordAccepted: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    expect(find.text('Update settings'), findsNothing);
  });

  testWidgets('saving reaches the controller and reports back', (tester) async {
    final h = Harness(access: accessFixture(isAdmin: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();
    h.calls.clear();

    await tester.tap(find.text('Update settings'));
    await tester.pumpAndSettle();

    expect(h.calls, contains(startsWith('save ')));
    expect(find.text('Settings updated successfully'), findsOneWidget);
  });

  testWidgets('a failed save says so above the form', (tester) async {
    // It used to be the first child of the scroll view, so a failure saving from
    // the bottom of a long form showed the user nothing at all.
    final h = Harness(access: accessFixture(isAdmin: true))
      ..saveThrows = Exception('read only');
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update settings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('read only'), findsOneWidget);
  });

  testWidgets('⚠️ the password survives the gate closing', (tester) async {
    // It is the credential every later call authenticates with. A controller
    // rebuilt per view would lose it the moment the form opened.
    final h = Harness(access: accessFixture(passwordAccepted: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hunter2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget, reason: 'gate accepted');
    expect(h.controller.form.password.text, 'hunter2');
    expect(h.calls, contains('load "hunter2"'));
  });

  testWidgets('signing out takes the configuration off the screen', (
    tester,
  ) async {
    final h = Harness(
      access: accessFixture(isAdmin: true),
      settings: settingsFixture(),
    );
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();
    expect(find.text('Storage'), findsOneWidget);

    h.access = accessFixture();
    h.auth.notifyListeners();
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsNothing);
    expect(find.text('No settings available'), findsOneWidget);
  });

  testWidgets('⚠️ a controller passed in is not disposed by the tab', (
    tester,
  ) async {
    // The app-wide one outlives the tab, and disposing it would take the form's
    // controllers with it — the settings password included.
    final h = Harness(access: accessFixture(isAdmin: true));
    addTearDown(h.controller.dispose);
    await pumpTab(tester, h);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(h.controller.form.password.text, isNotNull);
    await expectLater(h.controller.loadAccess(), completes);
  });
}
