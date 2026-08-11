import 'dart:io';

import 'package:flumip_server/src/services/process_runner.dart';
import 'package:test/test.dart';

import '../support/temp_dir.dart';

/// [SystemProcessRunner] against real processes.
///
/// Everything else in this suite runs against `FakeProcessRunner`, which is the
/// right default — but the whole point of these behaviours is what happens when a
/// real program hangs, is missing, or writes to stderr, and a fake cannot show
/// that. Uses `sh`, which is present anywhere this server runs.
void main() {
  const runner = SystemProcessRunner();

  group('run', () {
    test('returns stdout, stderr and the exit code', () async {
      final result = await runner.run('sh', [
        '-c',
        'echo out; echo err >&2; exit 3',
      ]);
      expect(result.exitCode, 3);
      expect(result.stdout.toString().trim(), 'out');
      expect(result.stderr.toString().trim(), 'err');
    }, tags: ['unit']);

    test('a program that outruns its deadline is killed', () async {
      // ⚠️ Without this a wedged tool holds its caller open for the life of the
      // server process: `Process.run` cannot be cancelled, and nothing else was
      // going to give up.
      final stopwatch = Stopwatch()..start();
      await expectLater(
        runner.run('sh', [
          '-c',
          'sleep 30',
        ], timeout: const Duration(milliseconds: 300)),
        throwsA(isA<ProcessTimeoutException>()),
      );
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 10)),
        reason: 'it must not wait for the program to finish on its own',
      );
    }, tags: ['unit']);

    test(
      'a timeout carries whatever the program had complained about',
      () async {
        // A hang is far easier to diagnose when you can see how far it got.
        try {
          await runner.run('sh', [
            '-c',
            'echo "opening the reference" >&2; sleep 30',
          ], timeout: const Duration(milliseconds: 400));
          fail('expected a timeout');
        } on ProcessTimeoutException catch (e) {
          expect(e.executable, 'sh');
          expect(e.toString(), contains('opening the reference'));
          expect(e.toString(), contains('did not finish'));
        }
      },
      tags: ['unit'],
    );

    test('a program that finishes inside its deadline is unaffected', () async {
      final result = await runner.run('sh', [
        '-c',
        'echo quick',
      ], timeout: const Duration(seconds: 30));
      expect(result.exitCode, 0);
      expect(result.stdout.toString().trim(), 'quick');
    }, tags: ['unit']);

    test('a missing program is reported in words, not as errno 2', () async {
      // The raw ProcessException says "No such file or directory, errno = 2",
      // which nobody reads as "that tool is not installed".
      try {
        await runner.run('flumip-definitely-not-installed', const []);
        fail('expected a failure');
      } on ToolUnavailableException catch (e) {
        expect(e.executable, 'flumip-definitely-not-installed');
        expect(e.toString(), contains('not installed'));
      }
    }, tags: ['unit']);

    test('a chatty program does not deadlock', () async {
      // An undrained pipe stalls the child once it has written more than the
      // buffer holds, which is about 64 kB — so this hangs forever if either
      // stream is left uncollected.
      final result = await runner.run('sh', [
        '-c',
        'for i in \$(seq 1 5000); do echo "line \$i of output"; done',
      ], timeout: const Duration(seconds: 30));
      expect(result.exitCode, 0);
      expect(result.stdout.toString().length, greaterThan(64 * 1024));
    }, tags: ['unit']);

    test('a working directory is honoured', () async {
      final dir = createTempDir('flumip_pr');
      File('${dir.path}/marker.txt').writeAsStringSync('x');
      final result = await runner.run('sh', [
        '-c',
        'ls',
      ], workingDirectory: dir.path);
      expect(result.stdout.toString(), contains('marker.txt'));
    }, tags: ['unit']);
  });

  group('start', () {
    test('captures stdout and stderr into one file, in order', () async {
      final dir = createTempDir('flumip_pr');
      final log = '${dir.path}/tool.log';

      await runner.start('sh', [
        '-c',
        'echo first; echo "second, on stderr" >&2',
      ], outputPath: log);

      // The child is fire-and-forget, so wait for it to have written.
      for (var i = 0; i < 50; i++) {
        if (File(log).existsSync() &&
            File(log).readAsStringSync().contains('second')) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final captured = File(log).readAsStringSync();
      expect(captured, contains('first'));
      expect(captured, contains('second, on stderr'));
    }, tags: ['unit']);

    test('a missing program is reported in words', () async {
      await expectLater(
        runner.start('flumip-definitely-not-installed', const []),
        throwsA(isA<ToolUnavailableException>()),
      );
    }, tags: ['unit']);

    test('without an output path it still returns promptly', () async {
      // The streams are drained rather than left to fill, so a chatty child
      // cannot stall. Nothing to assert but that this completes.
      await expectLater(
        runner.start('sh', ['-c', 'for i in \$(seq 1 2000); do echo x; done']),
        completes,
      );
    }, tags: ['unit']);
  });

  group('firstLineOf', () {
    test('takes the first non-empty line', () {
      expect(firstLineOf('\n\n  boom  \nmore\n'), 'boom');
    });

    test('is empty for empty output', () {
      expect(firstLineOf('   \n  '), isEmpty);
    });

    test('is bounded, because it lands in a column and on a screen', () {
      final long = firstLineOf('y' * 500);
      expect(long.length, lessThanOrEqualTo(201));
      expect(long, endsWith('…'));
    });
  });
}
