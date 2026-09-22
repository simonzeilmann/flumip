import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import '../support/fake_mail_sender.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The two stored secrets must never travel to the browser.
///
/// ⚠️ `smtpPassword` was an ordinary field until now, which meant every
/// `getSettings` call serialised the mail account's password in cleartext to
/// whoever had the settings screen open. `oidcClientSecret` had already been
/// given the write-only treatment; this is the same shape applied to the other
/// one, and these tests are what stop either sliding back.
void main() {
  final mail = FakeMailSender();

  withServerpod('Settings secrets', (sessionBuilder, endpoints) {
    setup(mailSender: mail);
    setUp(mail.reset);
    final session = sessionBuilder.build();

    /// Puts a password in the database the way the endpoint does.
    Future<void> storePassword(String value) async {
      await endpoints.settings.setSmtpPassword(
        sessionBuilder,
        'changeme',
        value,
      );
    }

    group('the SMTP password never reaches the client', () {
      test('getSettings does not carry it, in any form', () async {
        await storePassword('hunter2');

        final settings = await endpoints.settings.getSettings(
          sessionBuilder,
          'changeme',
        );

        // ⚠️ `toJsonForProtocol`, not `toJson`. The latter is the full
        // server-side serialisation and *does* include serverOnly fields — it is
        // what writes the row. The protocol one is what crosses the wire, and
        // asserting on the wrong one would make this test pass while the
        // password still leaked.
        final wire = settings.toJsonForProtocol();

        expect(wire.containsKey('smtpPassword'), isFalse);
        // Belt and braces: not under some other key either.
        expect(wire.toString(), isNot(contains('hunter2')));
      }, tags: ['integration']);

      test('but the server still has it, for sending mail', () async {
        await storePassword('hunter2');
        final stored = await Settings.db.findFirstRow(session);
        expect(stored!.smtpPassword, 'hunter2');
      }, tags: ['integration']);
    });

    group('saving unrelated settings leaves it alone', () {
      test('an ordinary update does not blank the stored password', () async {
        // ⚠️ The failure mode this shape exists to prevent. The client cannot
        // send a serverOnly field, so it arrives as null on every save — and if
        // `updateSettings` merged it, every unrelated settings change would
        // silently wipe the mail password and mail would stop working with no
        // indication why.
        await storePassword('hunter2');

        final current = await endpoints.settings.getSettings(
          sessionBuilder,
          'changeme',
        );
        current.smtpFrom = 'changed@flumip.local';
        await endpoints.settings.updateSettings(
          sessionBuilder,
          'changeme',
          current,
        );

        final stored = await Settings.db.findFirstRow(session);
        expect(stored!.smtpPassword, 'hunter2');
        expect(stored.smtpFrom, 'changed@flumip.local');
      }, tags: ['integration']);
    });

    group('setSmtpPassword', () {
      test('replaces the stored password', () async {
        await storePassword('first');
        await storePassword('second');
        expect(
          (await Settings.db.findFirstRow(session))!.smtpPassword,
          'second',
        );
      }, tags: ['integration']);

      test('an empty value clears it, for an unauthenticated relay', () async {
        await storePassword('hunter2');
        await storePassword('');
        expect((await Settings.db.findFirstRow(session))!.smtpPassword, isNull);
      }, tags: ['integration']);

      test('refuses a wrong settings password', () async {
        await expectLater(
          endpoints.settings.setSmtpPassword(sessionBuilder, 'wrong', 'x'),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);
    });

    group('smtpPasswordConfigured', () {
      test('reports whether one is stored, without revealing it', () async {
        expect(
          await endpoints.settings.smtpPasswordConfigured(
            sessionBuilder,
            'changeme',
          ),
          isFalse,
        );

        await storePassword('hunter2');

        expect(
          await endpoints.settings.smtpPasswordConfigured(
            sessionBuilder,
            'changeme',
          ),
          isTrue,
        );
      }, tags: ['integration']);

      test('an empty stored password counts as not configured', () async {
        await storePassword('');
        expect(
          await endpoints.settings.smtpPasswordConfigured(
            sessionBuilder,
            'changeme',
          ),
          isFalse,
        );
      }, tags: ['integration']);

      test('refuses a wrong settings password', () async {
        await expectLater(
          endpoints.settings.smtpPasswordConfigured(sessionBuilder, 'wrong'),
          throwsA(isA<ArgumentException>()),
        );
      }, tags: ['integration']);
    });

    group('the OIDC client secret, for the same reasons', () {
      test('getSettings does not carry it', () async {
        await endpoints.settings.setOidcClientSecret(
          sessionBuilder,
          'changeme',
          's3cret',
        );

        final settings = await endpoints.settings.getSettings(
          sessionBuilder,
          'changeme',
        );

        final wire = settings.toJsonForProtocol();
        expect(wire.containsKey('oidcClientSecret'), isFalse);
        expect(wire.toString(), isNot(contains('s3cret')));
      }, tags: ['integration']);
    });
  });
}
