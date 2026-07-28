import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/future_calls/check_index_progress_future_call.dart';
import 'package:flumip_server/src/future_calls/check_mipgen_progress_future_call.dart';
import 'package:flumip_server/src/generated/protocol.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_process_runner.dart';
import '../support/seed.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Records whether the polling future call rescheduled or finalized, without
/// doing the real downstream work.
class RecordingGenomeService extends GenomeService {
  bool scheduled = false;
  bool finished = false;
  @override
  Future<void> scheduleIndexProgressCheck(Session session, Genome genome) async {
    scheduled = true;
  }

  @override
  Future<void> indexIsFinished(Session session, dynamic object) async {
    finished = true;
  }
}

class RecordingMipgenService extends MipgenService {
  bool scheduled = false;
  bool finished = false;
  @override
  Future<void> scheduleMipgenProgressCheck(
    Session session,
    Project project, {
    Duration delay = const Duration(seconds: 10),
  }) async {
    scheduled = true;
  }

  @override
  Future<void> mipgenIsFinished(Session session, Project projectModel) async {
    finished = true;
  }
}

final fake = FakeProcessRunner();

void main() {
  withServerpod('Future calls', (sessionBuilder, endpoints) {
    setup(processRunner: fake);
    setUp(fake.reset);
    var session = sessionBuilder.build();

    test('CheckIndexProgress reschedules while bwa is still running', () async {
      final recording = RecordingGenomeService();
      sl.registerSingleton<GenomeService>(recording);
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun('ps',
          exitCode: 0, stdout: 'PID TTY CMD\n555 pts/0 00:00 bwa index\n');

      await CheckIndexProgressFutureCall().run(session, genome);

      expect(recording.scheduled, isTrue);
      expect(recording.finished, isFalse);
    }, tags: ['integration']);

    test('CheckIndexProgress finalizes when bwa has finished', () async {
      final recording = RecordingGenomeService();
      sl.registerSingleton<GenomeService>(recording);
      final genome = await seedGenome(session, name: 'hg38', indexPID: 555);
      fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');

      await CheckIndexProgressFutureCall().run(session, genome);

      expect(recording.finished, isTrue);
      expect(recording.scheduled, isFalse);
    }, tags: ['integration']);

    test('CheckMipgenProgress reschedules while mipgen is still running',
        () async {
      final recording = RecordingMipgenService();
      sl.registerSingleton<MipgenService>(recording);
      final project = await seedProject(session, options: 1, pid: 1234);
      fake.stubRun('ps',
          exitCode: 0, stdout: 'PID TTY CMD\n1234 pts/0 00:00 mipgen -x\n');

      await CheckMipgenProgressFutureCall().run(session, project);

      expect(recording.scheduled, isTrue);
      expect(recording.finished, isFalse);
    }, tags: ['integration']);

    test('CheckMipgenProgress finalizes when mipgen has finished', () async {
      final recording = RecordingMipgenService();
      sl.registerSingleton<MipgenService>(recording);
      final project = await seedProject(session, options: 1, pid: 1234);
      fake.stubRun('ps', exitCode: 1, stdout: 'PID TTY CMD\n');

      await CheckMipgenProgressFutureCall().run(session, project);

      expect(recording.finished, isTrue);
      expect(recording.scheduled, isFalse);
    }, tags: ['integration']);
  });
}
