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

    // What `ps -o comm= -o args=` prints for a running mipgen: the executable
    // name, padded, then the full command line. `uuid` stands in for the
    // project's folder, which is what identifies the run.
    String mipgenPs(String folder) =>
        'mipgen          /opt/flumip/MIPGEN/mipgen -regions_to_scan '
        '/opt/flumip/projects/$folder/genes.bed -project_name test '
        '-bwa_genome_index /g/hg38.fa\n';
    const folder = '0199c3a0-0000-7000-8000-000000000001';
    const otherFolder = '0199c3a0-0000-7000-8000-000000000002';

    test(
      'checkIfMipgenProcessIsRunning is true when the pid is this project\'s mipgen',
      () async {
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        fake.stubRun('ps', exitCode: 0, stdout: mipgenPs(folder));
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isTrue,
        );
        expect(fake.lastFor('ps')!.arguments, [
          '-o',
          'comm=',
          '-o',
          'args=',
          '-p',
          '1234',
        ]);
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false when the pid is another project\'s mipgen',
      () async {
        // ⚠️ The case this check exists for. After a restart — every restart,
        // in a container — pids are handed out again, and the stored one can
        // belong to a different design. It used to count as "running".
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        fake.stubRun('ps', exitCode: 0, stdout: mipgenPs(otherFolder));
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false when the pid is some other program',
      () async {
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        // Not even fooled by the folder turning up in someone else's arguments.
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout:
              'less            less /opt/flumip/projects/$folder/genes.bed\n',
        );
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false for an unreaped mipgen',
      () async {
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout: 'mipgen          [mipgen] <defunct>\n',
        );
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false when process is gone',
      () async {
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        fake.stubRun('ps', exitCode: 1);
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning is false without asking ps for pid 0',
      () async {
        // getProcessPID returns 0 when mipgen never showed up; the progress
        // check relies on that reading as "finished".
        final project = await seedProject(
          session,
          options: 1,
          pid: 0,
          folderName: folder,
        );
        expect(
          await processService.checkIfMipgenProcessIsRunning(session, project),
          isFalse,
        );
        expect(fake.lastFor('ps'), isNull);
      },
      tags: ['unit'],
    );

    test(
      'checkIfMipgenProcessIsRunning throws when ps errors (exit > 1)',
      () async {
        final project = await seedProject(
          session,
          options: 1,
          pid: 1234,
          folderName: folder,
        );
        fake.stubRun('ps', exitCode: 2, stderr: 'ps: boom');
        expect(
          () => processService.checkIfMipgenProcessIsRunning(session, project),
          throwsA(isA<Exception>()),
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfIndexProcessIsRunning is true when the pid is bwa index on this FASTA',
      () async {
        final genome = await seedGenome(
          session,
          name: 'hg38',
          indexPID: 555,
          fastaPath: '/g/hg38/fa/hg38.fa',
        );
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout: 'bwa             bwa index /g/hg38/fa/hg38.fa\n',
        );
        expect(
          await processService.checkIfIndexProcessIsRunning(session, genome),
          isTrue,
        );
        expect(fake.lastFor('ps')!.arguments.last, '555');
        expect(fake.lastFor('ps')!.timeout, isNotNull);
      },
      tags: ['unit'],
    );

    test(
      'checkIfIndexProcessIsRunning is false when the pid indexes another genome',
      () async {
        final genome = await seedGenome(
          session,
          name: 'hg38',
          indexPID: 555,
          fastaPath: '/g/hg38/fa/hg38.fa',
        );
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout: 'bwa             bwa index /g/hg19/fa/hg19.fa\n',
        );
        expect(
          await processService.checkIfIndexProcessIsRunning(session, genome),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfIndexProcessIsRunning is false when the pid is a mipgen\'s bwa aln',
      () async {
        final genome = await seedGenome(
          session,
          name: 'hg38',
          indexPID: 555,
          fastaPath: '/g/hg38/fa/hg38.fa',
        );
        fake.stubRun(
          'ps',
          exitCode: 0,
          stdout: 'bwa             bwa aln -t 1 /g/hg38/fa/hg38.fa x.fq\n',
        );
        expect(
          await processService.checkIfIndexProcessIsRunning(session, genome),
          isFalse,
        );
      },
      tags: ['unit'],
    );

    test(
      'checkIfIndexProcessIsRunning is false when process is gone',
      () async {
        final genome = await seedGenome(
          session,
          name: 'hg38',
          indexPID: 555,
          fastaPath: '/g/hg38/fa/hg38.fa',
        );
        fake.stubRun('ps', exitCode: 1);
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

    test('terminateMipgenRun kills the run when the pid is still it', () async {
      final project = await seedProject(
        session,
        options: 1,
        pid: 1234,
        folderName: folder,
      );
      fake.stubRun('ps', exitCode: 0, stdout: mipgenPs(folder));
      fake.stubRun('pgrep', exitCode: 1);

      expect(await processService.terminateMipgenRun(session, project), isTrue);
      expect(fake.lastFor('kill')!.arguments, ['-9', '1234']);
    }, tags: ['unit']);

    test('terminateMipgenRun leaves a reused pid alone', () async {
      // ⚠️ kill -9 on a pid that now belongs to another design — or, after a
      // container restart, to the server itself — is the failure this stops.
      final project = await seedProject(
        session,
        options: 1,
        pid: 1234,
        folderName: folder,
      );
      fake.stubRun('ps', exitCode: 0, stdout: mipgenPs(otherFolder));

      expect(
        await processService.terminateMipgenRun(session, project),
        isFalse,
      );
      expect(fake.lastFor('kill'), isNull);
      expect(fake.lastFor('pgrep'), isNull);
    }, tags: ['unit']);

    test('terminateMipgenRun does nothing when the run is gone', () async {
      final project = await seedProject(
        session,
        options: 1,
        pid: 1234,
        folderName: folder,
      );
      fake.stubRun('ps', exitCode: 1);

      expect(
        await processService.terminateMipgenRun(session, project),
        isFalse,
      );
      expect(fake.lastFor('kill'), isNull);
    }, tags: ['unit']);

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
      fake.runHandler = (executable, arguments) =>
          executable == 'pgrep' ? ProcessResult(0, 0, '999\n', '') : null;

      await processService
          .terminateProcess(session, 5)
          .timeout(const Duration(seconds: 5));

      // 999 is collected once and never revisited.
      final killed = fake.runCalls
          .where((c) => c.executable == 'kill')
          .map((c) => c.arguments.last)
          .toList();
      expect(killed, ['999', '5']);
    }, tags: ['unit']);
  });
}
