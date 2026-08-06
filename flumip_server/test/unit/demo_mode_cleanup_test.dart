import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/future_calls/demo_mode_cleanup.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/project_service.dart';
import 'package:flumip_server/src/services/settings_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import '../support/temp_dir.dart';

/// Demo mode had **no test at all**, which meant nothing established that a
/// demo install actually cleans up after itself — only that the future call was
/// being scheduled.
///
/// The scheduling half is easy to confirm by hand (`serverpod_future_call` gets
/// a row per project); the half that matters is what `invoke` does when the
/// scheduled time arrives, and that is what these cover.
void main() {
  withServerpod('DemoModeCleanup', (sessionBuilder, endpoints) {
    final fake = FakeProcessRunner();
    setup(processRunner: fake);
    setUp(fake.reset);

    final session = sessionBuilder.build();
    final projectService = sl<ProjectService>();
    final cleanup = DemoModeCleanup();

    late Directory base;

    setUp(() async {
      base = createTempDir('democleanup');
      await overrideSettingsDirs(session, projectDir: base.path);
      await _setDemoMode(session, false);
    });

    Future<Project> makeProject(String name) async {
      final options = await seedOptions(session);
      return projectService.createProject(session, name, options);
    }

    test('deletes the project when demo mode is on', () async {
      await _setDemoMode(session, true);
      final project = await makeProject('demo-project');

      await cleanup.invoke(session, project);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('takes the project files with it', () async {
      await _setDemoMode(session, true);
      final project = await makeProject('demo-project');
      final folder = Directory('${base.path}/${project.folderName}');
      await File('${folder.path}/result.txt').writeAsString('mips');

      await cleanup.invoke(session, project);

      expect(await folder.exists(), isFalse);
    }, tags: ['unit']);

    test('leaves the project alone when demo mode is off', () async {
      // ⚠️ The flag is read when the call *fires*, not when it was scheduled —
      // which is what makes switching demo mode off actually stop the deletions,
      // including for projects created while it was on.
      final project = await makeProject('keep-me');

      await cleanup.invoke(session, project);

      final remaining = await projectService.getProjects(session);
      expect(remaining.map((p) => p.name), ['keep-me']);
      expect(project.id, isNotNull);
    }, tags: ['unit']);

    test('switching demo mode on catches projects made before it', () async {
      // The call is scheduled unconditionally at creation, so turning the flag
      // on later still sweeps everything already queued.
      final project = await makeProject('made-earlier');
      await _setDemoMode(session, true);

      await cleanup.invoke(session, project);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('a project already deleted is not an error', () async {
      // Deleting a project cancels its cleanup, but the two can race: a call
      // already picked up for execution still runs.
      await _setDemoMode(session, true);
      final project = await makeProject('gone-already');
      await projectService.deleteProject(session, project.id!);

      await expectLater(cleanup.invoke(session, project), completes);
    }, tags: ['unit']);

    test('a null payload does not take the future call down', () async {
      await _setDemoMode(session, true);
      // Serverpod's signature allows it, so it has to be survivable.
      await expectLater(cleanup.invoke(session, null), completes);
    }, tags: ['unit']);
  });
}

Future<void> _setDemoMode(Session session, bool value) async {
  final settings = await SettingsService().getSettings(session);
  settings.demoMode = value;
  await SettingsService().updateSettings(session, settings);
}
