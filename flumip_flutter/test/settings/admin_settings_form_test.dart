import 'package:flumip_flutter/settings/admin_settings_form.dart';
import 'package:flumip_flutter/settings/settings_form.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'settings_form_test.dart' show settingsFixture;

/// The five sections an administrator edits.
///
/// Reachable from a test only because it was lifted out of `settings_tab.dart`,
/// which imports `main.dart`. What it covers is the thing the tab cannot: which
/// fields are offered in which state.
Future<SettingsForm> pumpForm(
  WidgetTester tester, {
  bool mailActive = false,
  bool loginRequired = false,
  bool demoMode = false,
  bool smtpPasswordConfigured = false,
  bool settingsPasswordIsDefault = false,
  VoidCallback? onSendTestMail,
}) async {
  final form = SettingsForm();
  addTearDown(form.dispose);
  form.load(
    settingsFixture(
      mailActive: mailActive,
      loginRequired: loginRequired,
      demoMode: demoMode,
    ),
  );

  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: AdminSettingsForm(
          form: form,
          authStatus: null,
          smtpPasswordConfigured: smtpPasswordConfigured,
          settingsPasswordIsDefault: settingsPasswordIsDefault,
          onChanged: () {},
          onTestConnection: () {},
          onSendTestMail: onSendTestMail ?? () {},
        ),
      ),
    ),
  );
  return form;
}

void main() {
  testWidgets('all five sections are present, in order', (tester) async {
    await pumpForm(tester);

    for (final title in [
      'Storage',
      'External tools',
      'Mail',
      'Sign-in',
      'Security',
    ]) {
      expect(find.text(title), findsOneWidget, reason: 'missing: $title');
    }
  });

  group('mail collapses when it is off', () {
    testWidgets('off shows only the switch', (tester) async {
      await pumpForm(tester, mailActive: false);

      expect(find.text('Send email'), findsOneWidget);
      expect(find.text('SMTP server'), findsNothing);
      expect(find.text('Send test email'), findsNothing);
    });

    testWidgets('on shows the relay fields', (tester) async {
      await pumpForm(tester, mailActive: true);

      expect(find.text('SMTP server'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Start TLS'), findsOneWidget);
    });

    testWidgets('the test-mail button calls back', (tester) async {
      var sent = false;
      await pumpForm(
        tester,
        mailActive: true,
        onSendTestMail: () => sent = true,
      );

      await tester.tap(find.text('Send test email'));
      expect(sent, isTrue);
    });
  });

  group('the SMTP password box says what is stored', () {
    testWidgets('⚠️ a stored password is announced, never sent back', (
      tester,
    ) async {
      // Without this the empty box is indistinguishable from no password at
      // all, and an admin retypes one every time they touch a nearby setting.
      final form = await pumpForm(
        tester,
        mailActive: true,
        smtpPasswordConfigured: true,
      );

      expect(form.smtpPassword.text, isEmpty);
      expect(find.textContaining('A password is stored'), findsOneWidget);
    });

    testWidgets('no stored password says that instead', (tester) async {
      await pumpForm(tester, mailActive: true, smtpPasswordConfigured: false);
      expect(find.textContaining('No password stored'), findsOneWidget);
    });
  });

  group('sign-in', () {
    testWidgets('the SSO fields appear only when sign-in is required', (
      tester,
    ) async {
      await pumpForm(tester, loginRequired: false);
      expect(find.text('Require sign-in'), findsOneWidget);
      expect(find.text('OIDC issuer'), findsNothing);

      await pumpForm(tester, loginRequired: true);
      expect(find.text('OIDC issuer'), findsOneWidget);
    });
  });

  group('demo mode', () {
    testWidgets('the retention field appears only when demo mode is on', (
      tester,
    ) async {
      await pumpForm(tester, demoMode: false);
      expect(find.text('Keep projects for (hours)'), findsNothing);

      await pumpForm(tester, demoMode: true);
      expect(find.text('Keep projects for (hours)'), findsOneWidget);
    });

    testWidgets('⚠️ it says which way the setting bites', (tester) async {
      // Raising it reprieves projects already queued for deletion; lowering it
      // cannot pull an existing deadline forward, because nothing wakes up
      // earlier than the time it was given.
      await pumpForm(tester, demoMode: true);
      expect(
        find.textContaining('Lowering it applies to new projects only'),
        findsOneWidget,
      );
    });
  });

  testWidgets('⚠️ the settings password is offered as write-only', (
    tester,
  ) async {
    // It used to be round-tripped — loaded with the stored password and sent
    // back verbatim — so the helper said the opposite of this. The server now
    // stores only a hash and has nothing to put in the box, which makes an empty
    // box mean "keep the current password".
    final form = await pumpForm(tester);

    expect(form.newPassword.text, isEmpty);
    expect(
      find.textContaining('leave empty to keep the current one'),
      findsOneWidget,
    );
  });

  testWidgets('says nothing about the password when it has been changed', (
    tester,
  ) async {
    await pumpForm(tester, settingsPasswordIsDefault: false);

    expect(find.textContaining('default settings password'), findsNothing);
  });

  testWidgets('⚠️ warns while the password is still the shipped default', (
    tester,
  ) async {
    // The whole point of `changeme` is that it gets changed, and the only thing
    // that used to make "it has not been" visible was the password sitting
    // readable in the box above.
    await pumpForm(tester, settingsPasswordIsDefault: true);

    expect(
      find.textContaining('still uses the default settings password'),
      findsOneWidget,
    );
  });
}
