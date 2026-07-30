import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:test/test.dart';

import '../integration/test_tools/serverpod_test_tools.dart';
import '../support/fake_process_runner.dart';
import '../support/seed.dart';

void main() {
  withServerpod('ProcessService', (sessionBuilder, endpoints) {
    final fake = FakeProcessRunner();
    setup(processRunner: fake);
    var session = sessionBuilder.build();
    final processService = sl<ProcessService>();

    test(
      'checkIfMipgenProcessIsRunning is true when ps shows mipgen',
      () async {
        final project = await seedProject(session, options: 1, pid: 1234);
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout: 'PID TTY CMD\n1234 pts/0 00:00 mipgen -x\n',
        );
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isTrue,
        );
        expect(fake.lastFor('ps')!.arguments, ['-p', '1234']);
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false when process is gone',
      () async {
        final project = await seedProject(session, options: 1, pid: 1234);
        fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning throws when ps errors (exit > 1)',
      () async {
        final project = await seedProject(session, options: 1, pid: 1234);
        fake.stubRun('ps', exitCode: 2, stderr: 'ps: boom');
        expect(
          () => processService.checkIfMipgenProcessIsRunning(session, project),
          throwsA(isA<Exception>()),
        );
      },
      tags: ['unit'],
    );

    test('checkIfIndexProcessIsRunning is true when ps shows bwa', () async {
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun(
        'ps',
        exitCode: 0,
        stdout: 'PID TTY CMD\n555 pts/0 00:00 bwa index\n',
      );
      expect(
        await processService.checkIfIndexProcessIsRunning(session, genome),
        isTrue,
      );
      expect(fake.lastFor('ps')!.arguments, ['-p', '555']);
    }, tags: ['unit']);

    test(
      'checkIfIndexProcessIsRunning is false when process is gone',
      () async {
        final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
        fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');
        expect(
          await processService.checkIfIndexProcessIsRunning(session, genome),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfIndexProcessIsRunning throws when ps errors (exit > 1)',
      () async {
        final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
        fake.stubRun('ps', exitCode: 3);
        expect(
          () => processService.checkIfIndexProcessIsRunning(session, genome),
          throwsA(isA<Exception>()),
        );
      },
      tags: ['unit'],
    );

    test('getProcessPID parses the matching pgrep line', () async {
      fake.stubRun(
        'pgrep',
        exitCode: 0,
        stdout: '4242 mipgen -project_name demo\n99 other\n',
      );
      final pid = await processService.getProcessPID(
        session,
        'mipgen',
        '-project_name',
      );
      expect(pid, 4242);
      expect(fake.lastFor('pgrep')!.arguments, ['--list-full', 'mipgen']);
    }, tags: ['unit']);

    test(
      'getProcessPID returns 0 when nothing matches (pgrep exit 1)',
      () async {
        fake.stubRun('pgrep', exitCode: 1, stdout: '');
        expect(await processService.getProcessPID(session, 'mipgen', 'x'), 0);
      },
      tags: ['unit'],
    );

    test('getProcessPID throws when pgrep errors (exit > 1)', () async {
      fake.stubRun('pgrep', exitCode: 2, stderr: 'pgrep: boom');
      expect(
        () => processService.getProcessPID(session, 'mipgen', 'x'),
        throwsA(isA<Exception>()),
      );
    }, tags: ['unit']);

    test(
      'terminateProcess issues kill -9 and does not throw on failure',
      () async {
        fake.stubRun('kill', exitCode: 2, stderr: 'kill: boom');
        await processService.terminateProcess(session, 4242);
        expect(fake.lastFor('kill')!.arguments, ['-9', '4242']);
      },
      tags: ['unit'],
    );
  });
}
