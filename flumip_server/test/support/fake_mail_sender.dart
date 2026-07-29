import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mail_sender.dart';

/// A single recorded call to [MailSender.send].
class SentMail {
  final String to;
  final String subject;
  final String body;

  /// SMTP configuration the send was performed with, captured so tests can
  /// assert the settings were threaded through correctly.
  final String host;
  final int port;
  final String from;
  final bool startTLS;

  SentMail({
    required this.to,
    required this.subject,
    required this.body,
    required this.host,
    required this.port,
    required this.from,
    required this.startTLS,
  });
}

/// In-memory [MailSender] for tests: records every message instead of talking
/// to an SMTP server. Set [error] to make sending fail.
class FakeMailSender implements MailSender {
  final List<SentMail> sent = [];
  Object? error;

  /// Clears recorded messages and the error override. Call from a test `setUp`
  /// when the same fake instance is shared across a group.
  void reset() {
    sent.clear();
    error = null;
  }

  SentMail? get lastSent => sent.isEmpty ? null : sent.last;

  @override
  Future<void> send({
    required Settings settings,
    required String to,
    required String subject,
    required String body,
  }) async {
    sent.add(SentMail(
      to: to,
      subject: subject,
      body: body,
      host: settings.smtpServer,
      port: settings.smtpPort,
      from: settings.smtpFrom,
      startTLS: settings.startTLS,
    ));
    if (error != null) throw error!;
  }
}
