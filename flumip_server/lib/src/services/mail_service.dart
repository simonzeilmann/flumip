import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/mail_sender.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/protocol.dart';
import 'package:serverpod/server.dart';

/// Sends the application's email notifications.
///
/// Delivery itself is delegated to [MailSender] (resolved from the service
/// locator) so tests can substitute a fake.
class MailService {
  MailService();

  /// Sends a test message to [to] so an administrator can validate the SMTP
  /// configuration without running a job.
  ///
  /// Unlike the notification path this deliberately does **not** swallow
  /// errors: the caller wants to see why delivery failed. It also ignores
  /// [Settings.mailActive] so the configuration can be verified before mail is
  /// switched on.
  Future<void> sendTestMail(Session session, String to) async {
    final settingsService = sl<SettingsService>();
    final mailSender = sl<MailSender>();

    if (to.isEmpty) {
      session.log('No recipient supplied for test mail', level: LogLevel.error);
      throw ArgumentException(message: 'No recipient supplied');
    }

    final settings = await settingsService.getSettings(session);
    if (settings.smtpServer.isEmpty) {
      session.log('No SMTP server configured', level: LogLevel.error);
      throw ArgumentException(message: 'No SMTP server configured');
    }

    session.log('Sending test mail to $to', level: LogLevel.info);
    await mailSender.send(
      settings: settings,
      to: to,
      subject: 'FLUMIP test email',
      body:
          'This is a test email from FLUMIP.\n\n'
          'If you received it, the SMTP configuration works.',
    );
    session.log('Test mail sent to $to', level: LogLevel.info);
  }

  /// Notifies the owner of [project] that MIP generation has finished.
  ///
  /// [failed] selects the failure wording. Sending is skipped (with a log
  /// entry) when mail is disabled globally, when the project opted out, or when
  /// no recipient can be resolved. Delivery errors are logged but never
  /// rethrown — a notification must not fail the job it reports on.
  Future<void> notifyProjectFinished(
    Session session,
    Project project, {
    required bool failed,
  }) async {
    final settingsService = sl<SettingsService>();
    final mailSender = sl<MailSender>();

    final settings = await settingsService.getSettings(session);
    if (!settings.mailActive) {
      session.log(
        'Mail is disabled, skipping notification for project ${project.id}',
        level: LogLevel.info,
      );
      return;
    }
    if (!project.emailNotification) {
      session.log(
        'Project ${project.id} has notifications disabled, skipping',
        level: LogLevel.info,
      );
      return;
    }

    final recipient = await resolveRecipient(session, project);
    if (recipient == null || recipient.isEmpty) {
      session.log(
        'No recipient available for project ${project.id}, skipping '
        'notification (pending a user system that stores email addresses)',
        level: LogLevel.warning,
      );
      return;
    }

    final subject = failed
        ? 'FLUMIP: MIP generation failed for "${project.name}"'
        : 'FLUMIP: MIP generation finished for "${project.name}"';
    final body = failed
        ? 'MIP generation for project "${project.name}" failed.\n\n'
              'Error: ${project.error}\n'
        : 'MIP generation for project "${project.name}" finished '
              'successfully.\n\n'
              'Duration: ${project.completedIn ?? "unknown"}\n'
              'Output size: ${project.size} bytes\n';

    try {
      await mailSender.send(
        settings: settings,
        to: recipient,
        subject: subject,
        body: body,
      );
      session.log(
        'Notification sent for project ${project.id} to $recipient',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      // Never let a mail failure surface into the job that triggered it.
      session.log(
        'Failed to send notification for project ${project.id}: $e',
        level: LogLevel.error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Resolves the email address to notify for [project].
  ///
  /// **Extension point.** There is currently no user/auth system and no email
  /// address stored anywhere (`Project.owner` is an unused `int?`), so this
  /// returns null and notifications are skipped. When users exist — or a
  /// fallback address is added to [Settings] — this is the only method that
  /// needs to change.
  ///
  /// Overridable (rather than private) so tests can supply a recipient and
  /// exercise the delivery path that goes live once that source exists.
  Future<String?> resolveRecipient(Session session, Project project) async {
    return null;
  }
}
