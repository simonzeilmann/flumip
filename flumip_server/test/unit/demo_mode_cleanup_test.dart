import 'dart:io';

import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/future_calls/demo_mode_cleanup_future_call.dart';
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
    final cleanup = DemoModeCleanupFutureCall();

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

    /// A project whose retention window has already elapsed — which is the only
    /// state the cleanup call is ever scheduled to run in. Backdating beats
    /// waiting a week.
    Future<Project> makeExpiredProject(String name) async {
      final project = await makeProject(name);
      project.created = DateTime.now().toUtc().subtract(
        const Duration(days: 400),
      );
      await Project.db.updateRow(session, project);
      return project;
    }

    test('deletes the project when demo mode is on', () async {
      await _setDemoMode(session, true);
      final project = await makeExpiredProject('demo-project');

      await cleanup.run(session, project);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('takes the project files with it', () async {
      await _setDemoMode(session, true);
      final project = await makeExpiredProject('demo-project');
      final folder = Directory('${base.path}/${project.folderName}');
      await File('${folder.path}/result.txt').writeAsString('mips');

      await cleanup.run(session, project);

      expect(await folder.exists(), isFalse);
    }, tags: ['unit']);

    test('leaves the project alone when demo mode is off', () async {
      // ⚠️ The flag is read when the call *fires*, not when it was scheduled —
      // which is what makes switching demo mode off actually stop the deletions,
      // including for projects created while it was on.
      final project = await makeProject('keep-me');

      await cleanup.run(session, project);

      final remaining = await projectService.getProjects(session);
      expect(remaining.map((p) => p.name), ['keep-me']);
      expect(project.id, isNotNull);
    }, tags: ['unit']);

    test('switching demo mode on catches projects made before it', () async {
      // The call is scheduled unconditionally at creation, so turning the flag
      // on later still sweeps everything already queued.
      final project = await makeExpiredProject('made-earlier');
      await _setDemoMode(session, true);

      await cleanup.run(session, project);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('a project already deleted is not an error', () async {
      // Deleting a project cancels its cleanup, but the two can race: a call
      // already picked up for execution still runs.
      await _setDemoMode(session, true);
      final project = await makeExpiredProject('gone-already');
      await projectService.deleteProject(session, project.id!);

      await expectLater(cleanup.run(session, project), completes);
    }, tags: ['unit']);

    test('spares a project younger than the configured window', () async {
      // ⚠️ The retention is re-read when the call fires. Without that, an admin
      // who noticed the window was too short could not rescue anything — every
      // existing project already had its deadline baked in at creation.
      await _setDemoMode(session, true, retentionHours: 24 * 30);
      final project = await makeProject('too-young');

      await cleanup.run(session, project);

      final remaining = await projectService.getProjects(session);
      expect(remaining.map((p) => p.name), ['too-young']);
    }, tags: ['unit']);

    test('deletes once the project is older than the window', () async {
      await _setDemoMode(session, true, retentionHours: 1);
      final project = await makeProject('old-enough');
      // Backdate past the one-hour window rather than waiting an hour.
      project.created = DateTime.now().toUtc().subtract(
        const Duration(hours: 3),
      );
      await Project.db.updateRow(session, project);

      await cleanup.run(session, project);

      expect(await projectService.getProjects(session), isEmpty);
    }, tags: ['unit']);

    test('a nonsense window is clamped rather than obeyed', () async {
      // Zero would delete a project the instant it was created — including the
      // one whose creation scheduled the call.
      final settings = await SettingsService().getSettings(session);
      settings.demoModeRetentionHours = 0;
      expect(demoRetention(settings), const Duration(hours: 1));

      settings.demoModeRetentionHours = -5;
      expect(demoRetention(settings), const Duration(hours: 1));

      settings.demoModeRetentionHours = 99999999;
      expect(demoRetention(settings), const Duration(hours: 24 * 365));
    }, tags: ['unit']);

    test('the default window is a week', () async {
      final settings = await SettingsService().getSettings(session);
      expect(settings.demoModeRetentionHours, 168);
      expect(demoRetention(settings), const Duration(days: 7));
    }, tags: ['unit']);

    test('the payload is non-nullable now the call is generated', () async {
      // ⚠️ The legacy API handed `invoke` a `Project?`, so a null payload had to
      // be survivable. The generated dispatcher types `run` as taking a
      // `Project`, which removes the case rather than handling it.
      await _setDemoMode(session, true);
      await expectLater(
        cleanup.run(session, await makeExpiredProject('typed')),
        completes,
      );
    }, tags: ['unit']);
  });
}

Future<void> _setDemoMode(
  Session session,
  bool value, {
  int? retentionHours,
}) async {
  final settings = await SettingsService().getSettings(session);
  settings.demoMode = value;
  if (retentionHours != null) {
    settings.demoModeRetentionHours = retentionHours;
  }
  await SettingsService().updateSettings(session, settings);
}
