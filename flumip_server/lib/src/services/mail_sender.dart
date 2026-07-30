import 'package:flumip_server/src/generated/protocol.dart';
// Prefixed because the package's top-level `send` collides with
// [MailSender.send] below.
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Thin abstraction over SMTP delivery.
///
/// [MailService] depends on this instead of talking to the `mailer` package
/// directly so that tests can substitute a fake (see
/// `test/support/fake_mail_sender.dart`) and exercise the notification logic
/// without a real SMTP server.
abstract class MailSender {
  /// Sends a single plain-text message using the SMTP configuration held in
  /// [settings] ([Settings.smtpServer], [Settings.smtpPort],
  /// [Settings.smtpUser], [Settings.smtpPassword], [Settings.smtpFrom] and
  /// [Settings.startTLS]).
  ///
  /// Throws if delivery fails; callers decide whether that is fatal.
  Future<void> send({
    required Settings settings,
    required String to,
    required String subject,
    required String body,
  });
}

/// Default [MailSender] used in production; delegates to the `mailer` package.
class SmtpMailSender implements MailSender {
  const SmtpMailSender();

  @override
  Future<void> send({
    required Settings settings,
    required String to,
    required String subject,
    required String body,
  }) async {
    // An empty user means an unauthenticated relay; mailer expects null rather
    // than an empty string in that case.
    final user = settings.smtpUser.isEmpty ? null : settings.smtpUser;
    final password = settings.smtpPassword.isEmpty
        ? null
        : settings.smtpPassword;

    final server = SmtpServer(
      settings.smtpServer,
      port: settings.smtpPort,
      username: user,
      password: password,
      // With startTLS enabled mailer upgrades the plain connection via
      // STARTTLS (its default). With it disabled we have to explicitly allow
      // an insecure connection, otherwise mailer refuses to send.
      allowInsecure: !settings.startTLS,
    );

    final message = mailer.Message()
      ..from = mailer.Address(settings.smtpFrom)
      ..recipients.add(to)
      ..subject = subject
      ..text = body;

    await mailer.send(message, server);
  }
}
