import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';

class DemoModeCleanup extends FutureCall<Project> {
  final projectService = sl<ProjectService>();
  final settingsService = sl<SettingsService>();

  @override
  Future<void> invoke(Session session, Project? object) async {
    session.log(
      "Deleting project if demo mode is still active: ${object?.id}",
      level: LogLevel.info,
    );
    final settings = await settingsService.getSettings(session);

    if (!settings.demoMode) return;

    try {
      await projectService.getProject(session, object!.id!);
    } catch (e) {
      session.log(
        "Project not found, nothing to delete for project ID: ${object?.id}",
        level: LogLevel.info,
      );
      return;
    }

    await projectService.deleteProject(session, object.id!);
    session.log(
      "Deleted project in demo mode: ${object.id}",
      level: LogLevel.info,
    );
  }
}
