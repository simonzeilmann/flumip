import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'dart:io';

import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';

void main() {
  withServerpod('ProcessService', (sessionBuilder, endpoints) {
    final fake = FakeProcessRunner();
    setup(processRunner: fake);
    // ⚠️ The fake is shared across the group and accumulates every invocation,
    // so a test that asserts on `runCalls` rather than `lastFor` would otherwise
    // see the previous tests' calls too.
    setUp(fake.reset);
    var session = sessionBuilder.build();
    final processService = sl<ProcessService>();

    test('checkIfMipgenProcessIsRunning is true when ps shows mipgen', () async {
      final project = await seedProject(session, options: 1, pid: 1234);
      fake.stubRun('ps',
          exitCode: 0, stdout: 'PID TTY CMD\n1234 pts/0 00:00 mipgen -x\n');
      expect(
        await processService.checkIfMipgenProcessIsRunning(session, project),
        isTrue,
      );
      expect(fake.lastFor('ps')!.arguments, ['-p', '1234']);
    }, tags: ['unit']);

    test('checkIfMipgenProcessIsRunning is false when process is gone',
        () async {
      final project = await seedProject(session, options: 1, pid: 1234);
      fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');
      expect(
        await processService.checkIfMipgenProcessIsRunning(session, project),
        isFalse,
      );
    }, tags: ['unit']);

    test('checkIfMipgenProcessIsRunning throws when ps errors (exit > 1)',
        () async {
      final project = await seedProject(session, options: 1, pid: 1234);
      fake.stubRun('ps', exitCode: 2, stderr: 'ps: boom');
      expect(
        () => processService.checkIfMipgenProcessIsRunning(session, project),
        throwsA(isA<Exception>()),
      );
    }, tags: ['unit']);

    test('checkIfIndexProcessIsRunning is true when ps shows bwa', () async {
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun('ps',
          exitCode: 0, stdout: 'PID TTY CMD\n555 pts/0 00:00 bwa index\n');
      expect(
        await processService.checkIfIndexProcessIsRunning(session, genome),
        isTrue,
      );
      expect(fake.lastFor('ps')!.arguments, ['-p', '555']);
    }, tags: ['unit']);

    test('checkIfIndexProcessIsRunning is false when process is gone',
        () async {
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');
      expect(
        await processService.checkIfIndexProcessIsRunning(session, genome),
        isFalse,
      );
    }, tags: ['unit']);

    test('checkIfIndexProcessIsRunning throws when ps errors (exit > 1)',
        () async {
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun('ps', exitCode: 3);
      expect(
        () => processService.checkIfIndexProcessIsRunning(session, genome),
        throwsA(isA<Exception>()),
      );
    }, tags: ['unit']);

    test('getProcessPID parses the matching pgrep line', () async {
      fake.stubRun('pgrep',
          exitCode: 0, stdout: '4242 mipgen -project_name demo\n99 other\n');
      final pid =
          await processService.getProcessPID(session, 'mipgen', '-project_name');
      expect(pid, 4242);
      expect(fake.lastFor('pgrep')!.arguments, ['--list-full', 'mipgen']);
    }, tags: ['unit']);

    test('getProcessPID returns 0 when nothing matches (pgrep exit 1)',
        () async {
      fake.stubRun('pgrep', exitCode: 1, stdout: '');
      expect(await processService.getProcessPID(session, 'mipgen', 'x'), 0);
    }, tags: ['unit']);

    test('getProcessPID throws when pgrep errors (exit > 1)', () async {
      fake.stubRun('pgrep', exitCode: 2, stderr: 'pgrep: boom');
      expect(
        () => processService.getProcessPID(session, 'mipgen', 'x'),
        throwsA(isA<Exception>()),
      );
    }, tags: ['unit']);

    test('terminateProcess issues kill -9 and does not throw on failure',
        () async {
      fake.stubRun('kill', exitCode: 2, stderr: 'kill: boom');
      await processService.terminateProcess(session, 4242);
      expect(fake.lastFor('kill')!.arguments, ['-9', '4242']);
    }, tags: ['unit']);

    test('terminateProcess kills the children too, leaves first', () async {
      // ⚠️ The whole point. mipgen spawns bwa; killing only mipgen leaves those
      // children running, reparented to init, still pinned to every core and
      // still writing into a directory that is about to be deleted.
      //   100 -> 101, 102
      //   101 -> 103
      fake.runHandler = (executable, arguments) {
        if (executable != 'pgrep') return null;
        final parent = arguments.last;
        return switch (parent) {
          '100' => ProcessResult(0, 0, '101\n102\n', ''),
          '101' => ProcessResult(0, 0, '103\n', ''),
          _ => ProcessResult(0, 1, '', ''),
        };
      };

      await processService.terminateProcess(session, 100);

      final killed = fake.runCalls
          .where((c) => c.executable == 'kill')
          .map((c) => c.arguments.last)
          .toList();
      expect(killed.toSet(), {'100', '101', '102', '103'});
      // The parent goes last, so it cannot fork again mid-teardown.
      expect(killed.last, '100');
      expect(killed.indexOf('103'), lessThan(killed.indexOf('101')));
    }, tags: ['unit']);

    test('terminateProcess survives a process that has no children', () async {
      fake.stubRun('pgrep', exitCode: 1);
      await processService.terminateProcess(session, 7);
      final killed = fake.runCalls.where((c) => c.executable == 'kill');
      expect(killed.length, 1);
      expect(killed.single.arguments, ['-9', '7']);
    }, tags: ['unit']);

    test('terminateProcess does not loop forever on a cyclic tree', () async {
      // Cannot happen with real pids, but a bounded walk is the difference
      // between a bug and a hung delete request.
      fake.runHandler = (executable, arguments) => executable == 'pgrep'
          ? ProcessResult(0, 0, '999\n', '')
          : null;

      await processService.terminateProcess(session, 5).timeout(
            const Duration(seconds: 5),
          );

      // 999 is collected once and never revisited.
      final killed = fake.runCalls
          .where((c) => c.executable == 'kill')
          .map((c) => c.arguments.last)
          .toList();
      expect(killed, ['999', '5']);
    }, tags: ['unit']);
  });
}
