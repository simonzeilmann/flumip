import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/genome.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:serverpod/serverpod.dart';

/// Polls the BWA index process for a genome. Registered automatically by the
/// generated future-call scheduler; scheduling lives in
/// [GenomeService.scheduleIndexProgressCheck].
class CheckIndexProgressFutureCall extends FutureCall<Genome> {
  final processService = sl<ProcessService>();
  final geneService = sl<GenomeService>();

  Future<void> run(Session session, Genome object) async {
    // ⚠️ Serverpod 4 runs future calls *at least* once, so this can arrive twice
    // for the same genome. What a redelivery costs here is different from the
    // mipgen poll: [GenomeService.indexIsFinished] recomputes `indexed` and
    // `indexResults` from a fresh directory listing, so the *values* are
    // idempotent — but it ends in `Genome.db.updateRow` on whichever object it
    // was handed, so passing the scheduling-time snapshot silently reverts any
    // edit made while bwa was running (a rename, a changed path). And each
    // duplicate delivery that finds bwa still running forks the one-minute poll
    // chain into another self-perpetuating poller.
    //
    // `indexing` is the flag to test, for the same reason `active` is in the
    // mipgen poll: it is persisted before the first check is scheduled and
    // cleared by `indexIsFinished`.
    //
    // ⚠️ Do **not** also gate on `indexPID == 0` — same stranding hazard as the
    // mipgen poll. A genome whose PID never landed would be left `indexing`
    // forever with nothing polling it, instead of being resolved by the
    // finished branch.
    final genome = await Genome.db.findById(session, object.id!);
    if (genome == null) {
      session.log(
        'BWA index check for genome ${object.id} abandoned: the row is gone.',
        level: LogLevel.info,
      );
      return;
    }
    if (!genome.indexing) {
      session.log(
        'BWA index check for genome ${genome.id} skipped: indexing has already '
        'finished.',
        level: LogLevel.info,
      );
      return;
    }

    session.log(
      "Checking BWA index progress for gene ID: ${genome.id}",
      level: LogLevel.info,
    );
    if (await processService.checkIfIndexProcessIsRunning(session, genome)) {
      session.log(
        "BWA index process is still running for gene ID: ${genome.id}",
        level: LogLevel.info,
      );
      await geneService.scheduleIndexProgressCheck(session, genome);
    } else {
      session.log(
        "BWA index process has finished for gene ID: ${genome.id}",
        level: LogLevel.info,
      );
      await geneService.indexIsFinished(session, genome);
    }
  }
}
