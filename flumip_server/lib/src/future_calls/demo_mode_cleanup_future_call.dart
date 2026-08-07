import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:flumip_server/src/generated/future_calls.dart';
import 'package:serverpod/serverpod.dart';

/// Deletes a project once its demo window has elapsed.
///
/// ⚠️ Registered by the **generated** scheduler, like every other future call
/// here. It used to be the one holdout on Serverpod's legacy identifier-based
/// API — `registerFutureCall` in `server.dart` plus `futureCallWithDelay` and
/// `cancelFutureCall` — all three of which are deprecated. The generated API
/// covers what the legacy one was kept for: `callWithDelay` takes an
/// `identifier`, and `futureCalls.cancel(identifier)` removes it again, which is
/// what stops a deleted project's cleanup from firing against a row that is
/// already gone.
class DemoModeCleanupFutureCall extends FutureCall<Project> {
  final projectService = sl<ProjectService>();
  final settingsService = sl<SettingsService>();

  Future<void> run(Session session, Project object) async {
    session.log(
      "Deleting project if demo mode is still active: ${object.id}",
      level: LogLevel.info,
    );
    final settings = await settingsService.getSettings(session);

    if (!settings.demoMode) return;

    final Project project;
    try {
      project = await projectService.getProject(session, object.id!);
    } catch (e) {
      session.log(
        "Project not found, nothing to delete for project ID: ${object.id}",
        level: LogLevel.info,
      );
      return;
    }

    // ⚠️ The retention is re-read here, not just when the call was scheduled.
    // Without this, raising the setting would not spare projects already queued
    // for deletion — an admin who noticed the window was too short could not
    // rescue anything, because every existing project already had its deadline
    // baked in.
    //
    // The reverse does not hold: *lowering* the setting cannot pull a scheduled
    // deletion earlier, because nothing wakes up before the time it was given.
    // Those projects keep the window they were created with.
    final retention = demoRetention(settings);
    final age = DateTime.now().toUtc().difference(project.created.toUtc());
    if (age < retention) {
      final remaining = retention - age;
      session.log(
        "Project ${project.id} is ${age.inHours}h old and the demo window is "
        "now ${retention.inHours}h; re-checking in ${remaining.inHours}h.",
        level: LogLevel.info,
      );
      await _reschedule(session, project, remaining);
      return;
    }

    await projectService.deleteProject(session, object.id!);
    session.log(
      "Deleted project in demo mode: ${object.id}",
      level: LogLevel.info,
    );
  }

  /// Puts the call back for the remaining window.
  Future<void> _reschedule(
    Session session,
    Project project,
    Duration remaining,
  ) async {
    await session.serverpod.futureCalls
        .callWithDelay(remaining, identifier: project.folderName)
        .demoModeCleanup
        .run(project);
  }
}