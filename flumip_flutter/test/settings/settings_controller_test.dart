import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/settings/settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'settings_form_test.dart' show settingsFixture;

/// The settings tab's logic, with the server replaced by closures.
///
/// ⚠️ This is the tab that carries the SMTP password, the OIDC client secret and
/// the settings password itself, and three of its invariants fail *silently* —
/// no error, no log, just a value that quietly stops being replaced. Those three
/// are the reason this file exists.
UserSettingsDto accessFixture({
  bool isAdmin = false,
  bool passwordAccepted = false,
}) => UserSettingsDto(isAdmin: isAdmin, passwordAccepted: passwordAccepted);

AuthAdminStatusDto statusFixture() => AuthAdminStatusDto(
  redirectUri: 'https://flumip.example/auth/callback',
  secretConfigured: true,
  envOverrides: const [],
  discoveryOk: true,
);

class Harness {
  Harness({this.access, this.settings, this.smtpConfigured = true}) {
    _build();
  }

  UserSettingsDto? access;
  Settings? settings;
  bool smtpConfigured;

  Object? accessThrows;
  Object? loadThrows;
  Object? saveThrows;
  Object? smtpSecretThrows;
  Object? oidcSecretThrows;
  Object? testMailThrows;
  Object? authStatusThrows;

  final calls = <String>[];
  final messages = <String>[];
  final auth = ChangeNotifier();
  var signedOut = false;

  late final SettingsController controller;

  void _build() {
    controller = SettingsController(
      loadAccess: () async {
        calls.add('access');
        if (accessThrows != null) throw accessThrows!;
        return access ?? accessFixture();
      },
      loadSettings: (password) async {
        calls.add('load "$password"');
        if (loadThrows != null) throw loadThrows!;
        return settings ?? settingsFixture();
      },
      saveSettings: (password, s) async {
        calls.add('save "$password" loginRequired=${s.loginRequired}');
        if (saveThrows != null) throw saveThrows!;
      },
      setSmtpPassword: (password, smtpPassword) async {
        calls.add('smtpPassword "$smtpPassword"');
        if (smtpSecretThrows != null) throw smtpSecretThrows!;
      },
      setOidcClientSecret: (password, secret) async {
        calls.add('oidcSecret "$secret"');
        if (oidcSecretThrows != null) throw oidcSecretThrows!;
      },
      smtpPasswordConfigured: (password) async {
        calls.add('smtpConfigured?');
        return smtpConfigured;
      },
      loadAuthStatus: (password) async {
        calls.add('authStatus');
        if (authStatusThrows != null) throw authStatusThrows!;
        return statusFixture();
      },
      sendTestMail: (password, to) async {
        calls.add('testMail $to');
        if (testMailThrows != null) throw testMailThrows!;
      },
      signOut: () {
        calls.add('signOut');
        signedOut = true;
      },
      auth: auth,
    );
    controller.messages.listen(messages.add);
  }
}

void main() {
  group('which view is shown', () {
    test('nothing answered yet is loading', () {
      final h = Harness();
      addTearDown(h.controller.dispose);
      expect(h.controller.view, SettingsView.loading);
    });

    test(
      '⚠️ a failed access question offers a retry, never a password box',
      () async {
        // Falling back to the password form turns every transient failure into
        // "type a password" — indistinguishable from a real prompt, and the reason
        // the earlier bug was so hard to read.
        final h = Harness()..accessThrows = Exception('down');
        addTearDown(h.controller.dispose);

        await h.controller.load();

        expect(h.controller.view, SettingsView.retry);
        expect(h.controller.errorMessage, contains('Could not determine'));
      },
    );

    test(
      'an administrator goes straight to the form, with no password',
      () async {
        final h = Harness(access: accessFixture(isAdmin: true));
        addTearDown(h.controller.dispose);

        await h.controller.load();

        expect(h.controller.view, SettingsView.adminForm);
        expect(h.calls, contains('load ""'), reason: 'no password needed');
      },
    );

    test('an install without sign-in offers the password gate', () async {
      final h = Harness(access: accessFixture(passwordAccepted: true));
      addTearDown(h.controller.dispose);

      await h.controller.load();

      expect(h.controller.view, SettingsView.passwordGate);
    });

    test(
      '⚠️ a signed-in non-administrator gets nothing to type into',
      () async {
        // Once sign-in is enforced the server stops accepting the password, so
        // offering the box would be offering something that cannot work.
        final h = Harness(access: accessFixture());
        addTearDown(h.controller.dispose);

        await h.controller.load();

        expect(h.controller.view, SettingsView.noSettings);
      },
    );

    test('the gate opens the form once the password is accepted', () async {
      final h = Harness(access: accessFixture(passwordAccepted: true));
      addTearDown(h.controller.dispose);
      await h.controller.load();

      h.controller.form.password.text = 'hunter2';
      await h.controller.loadSettings();

      expect(h.controller.view, SettingsView.adminForm);
      expect(h.calls, contains('load "hunter2"'));
    });

    test('a wrong password stays on the gate and says why', () async {
      final h = Harness(access: accessFixture(passwordAccepted: true))
        ..loadThrows = ArgumentException(message: 'Wrong password');
      addTearDown(h.controller.dispose);
      await h.controller.load();

      await h.controller.loadSettings();

      expect(h.controller.view, SettingsView.passwordGate);
      expect(h.controller.errorMessage, 'Wrong password');
    });
  });

  group('⚠️ the write-only secrets', () {
    Future<Harness> loaded() async {
      final h = Harness(access: accessFixture(isAdmin: true));
      await h.controller.load();
      h.calls.clear();
      return h;
    }

    test('an empty box keeps what is stored', () async {
      // The invariant that fails silently: degrade this and an unrelated save
      // blanks the SMTP password, with nothing anywhere reporting it.
      final h = await loaded();
      addTearDown(h.controller.dispose);

      await h.controller.save();

      expect(h.calls, isNot(contains(startsWith('smtpPassword'))));
      expect(h.calls, isNot(contains(startsWith('oidcSecret'))));
    });

    test('typing one replaces it, and the box is cleared', () async {
      final h = await loaded();
      addTearDown(h.controller.dispose);
      h.controller.form.smtpPassword.text = 'new-smtp';
      h.controller.form.oidcClientSecret.text = 'new-secret';

      await h.controller.save();

      expect(h.calls, contains('smtpPassword "new-smtp"'));
      expect(h.calls, contains('oidcSecret "new-secret"'));
      expect(h.controller.form.smtpPassword.text, isEmpty);
      expect(h.controller.form.oidcClientSecret.text, isEmpty);
    });

    test('⚠️ both go before the settings, not after', () async {
      // Switching SSO on in the same save has to find the secret already in
      // place, or the server refuses the configuration as incomplete.
      final h = await loaded();
      addTearDown(h.controller.dispose);
      h.controller.form.oidcClientSecret.text = 'new-secret';

      await h.controller.save();

      expect(
        h.calls.indexOf('oidcSecret "new-secret"'),
        lessThan(h.calls.indexWhere((c) => c.startsWith('save '))),
      );
    });

    test('storing one flips the "a password is stored" helper at once', () async {
      final h = await loaded();
      addTearDown(h.controller.dispose);
      h.smtpConfigured = false;
      h.controller.form.smtpPassword.text = 'new-smtp';

      await h.controller.save();

      // The server is asked again afterwards and says false here, but the point
      // is that the flag was set the moment the secret was accepted.
      expect(h.calls, contains('smtpPassword "new-smtp"'));
    });
  });

  group('⚠️ turning sign-in off', () {
    test('signs out, and does nothing after', () async {
      // The server has just ended every session, this one included. Everything
      // below that point assumes a session that no longer exists.
      final h = Harness(
        access: accessFixture(isAdmin: true),
        settings: settingsFixture(loginRequired: true),
      );
      addTearDown(h.controller.dispose);
      await h.controller.load();
      h.calls.clear();

      h.controller.form.loginRequired = false;
      await h.controller.save();

      expect(h.signedOut, isTrue);
      expect(
        h.calls.where((c) => c == 'authStatus' || c == 'smtpConfigured?'),
        isEmpty,
        reason: 'nothing is re-read against a session that has ended',
      );
    });

    test('turning it on does not sign anybody out', () async {
      final h = Harness(
        access: accessFixture(isAdmin: true),
        settings: settingsFixture(loginRequired: false),
      );
      addTearDown(h.controller.dispose);
      await h.controller.load();

      h.controller.form.loginRequired = true;
      await h.controller.save();

      expect(h.signedOut, isFalse);
    });

    test(
      '⚠️ the transition is measured against the last save, not the load',
      () async {
        // `settings` used to keep whatever was loaded at open, so turning sign-in
        // on and then off again in one sitting skipped the forced sign-out.
        final h = Harness(
          access: accessFixture(isAdmin: true),
          settings: settingsFixture(loginRequired: false),
        );
        addTearDown(h.controller.dispose);
        await h.controller.load();

        h.controller.form.loginRequired = true;
        await h.controller.save();
        expect(h.signedOut, isFalse);

        h.controller.form.loginRequired = false;
        await h.controller.save();

        expect(h.signedOut, isTrue);
      },
    );
  });

  group('saving', () {
    test('reports success and keeps the credential in step', () async {
      // The password may have just been changed; the one we authenticate with
      // has to follow, or every later save and test mail is refused.
      final h = Harness(
        access: accessFixture(isAdmin: true),
        settings: settingsFixture(settingsPassword: 'old'),
      );
      addTearDown(h.controller.dispose);
      await h.controller.load();
      h.controller.form.newPassword.text = 'brand-new';

      await h.controller.save();
      await pumpEventQueue();

      expect(h.controller.form.password.text, 'brand-new');
      expect(h.messages, contains('Settings updated successfully'));
    });

    test('a refusal is shown and nothing is claimed', () async {
      final h = Harness(access: accessFixture(isAdmin: true))
        ..saveThrows = Exception('read only');
      addTearDown(h.controller.dispose);
      await h.controller.load();

      await h.controller.save();
      await pumpEventQueue();

      expect(h.controller.errorMessage, contains('read only'));
      expect(h.messages, isEmpty);
    });
  });

  group('the test email', () {
    test('sends to the address in the box', () async {
      final h = Harness(access: accessFixture(isAdmin: true));
      addTearDown(h.controller.dispose);
      await h.controller.load();
      h.controller.form.testMail.text = '  you@example.com ';

      await h.controller.sendTestMail();
      await pumpEventQueue();

      expect(h.calls, contains('testMail you@example.com'));
      expect(h.messages, contains('Test email sent to you@example.com'));
    });

    test('an empty box asks for an address rather than sending', () async {
      final h = Harness(access: accessFixture(isAdmin: true));
      addTearDown(h.controller.dispose);
      await h.controller.load();
      h.calls.clear();

      await h.controller.sendTestMail();

      expect(h.calls, isEmpty);
      expect(h.controller.errorMessage, contains('Enter a recipient'));
    });
  });

  group('the SSO status panel', () {
    test('is loaded with the settings', () async {
      final h = Harness(access: accessFixture(isAdmin: true));
      addTearDown(h.controller.dispose);

      await h.controller.load();

      expect(h.controller.authStatus, isNotNull);
    });

    test('⚠️ a failure clears the panel rather than failing the tab', () async {
      final h = Harness(access: accessFixture(isAdmin: true))
        ..authStatusThrows = Exception('discovery timed out');
      addTearDown(h.controller.dispose);

      await h.controller.load();

      expect(h.controller.authStatus, isNull);
      expect(h.controller.view, SettingsView.adminForm);
      expect(h.controller.errorMessage, isNull);
    });
  });

  test('⚠️ signing out clears the administrator\'s configuration', () async {
    // Whatever was decided for the previous identity no longer applies, and
    // their settings must not stay on screen.
    final h = Harness(access: accessFixture(isAdmin: true));
    addTearDown(h.controller.dispose);
    await h.controller.load();
    expect(h.controller.view, SettingsView.adminForm);

    h.access = accessFixture();
    h.auth.notifyListeners();
    await pumpEventQueue();

    expect(h.controller.view, SettingsView.noSettings);
    expect(h.controller.settings, isNull);
  });

  test('the error can be dismissed', () async {
    final h = Harness()..accessThrows = Exception('down');
    addTearDown(h.controller.dispose);
    await h.controller.load();

    h.controller.dismissError();

    expect(h.controller.errorMessage, isNull);
  });
}
