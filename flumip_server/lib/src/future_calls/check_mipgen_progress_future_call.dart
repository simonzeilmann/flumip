import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:serverpod/serverpod.dart';

/// Polls the MIP generation process for a project. Registered automatically by
/// the generated future-call scheduler; scheduling lives in
/// [MipgenService.scheduleMipgenProgressCheck].
class CheckMipgenProgressFutureCall extends FutureCall<Project> {
  final processService = sl<ProcessService>();
  final mipgenService = sl<MipgenService>();

  Future<void> run(Session session, Project object) async {
    // ⚠️ Serverpod 4 runs future calls *at least* once, so this can arrive twice
    // for the same project — and the finish path is destructive on a project
    // that has already finished. [MipgenService.mipgenIsFinished] sends a second
    // completion email (`MailService.notifyProjectFinished` has no
    // already-notified flag, and it is called *after* the `finally` that marks
    // the project inactive), recomputes `completedIn` from the wall clock so the
    // reported duration inflates, rebuilds the UCSC track, and
    // deletes byproducts again.
    //
    // A redelivery would reach all of that, too. Once the first pass has set
    // `pid = 0`, `checkIfMipgenProcessIsRunning` shells out `ps -p 0`, which
    // exits 1 — so the second delivery goes straight down the "finished" branch.
    //
    // `active` is the flag to test, and *only* `active`. It is persisted before
    // the first check is ever scheduled and cleared in `mipgenIsFinished`'s
    // `finally`, so it means exactly "this run is still the one being polled".
    //
    // ⚠️ Do **not** also gate on `pid == 0`. `getProcessPID` legitimately returns
    // 0 when mipgen has not yet appeared in the process table, and today that
    // case is *rescued* by the finished branch: the poll finds nothing running
    // and `mipgenIsFinished` records the failure and clears `active`. Refusing
    // pid 0 here would leave the project active forever with nothing polling it
    // — stuck in the UI, and only ever on runs that had already gone wrong.
    final project = await Project.db.findById(session, object.id!);
    if (project == null) {
      session.log(
        'MIP progress check for project ${object.id} abandoned: the row is gone.',
        level: LogLevel.info,
      );
      return;
    }
    if (!project.active) {
      session.log(
        'MIP progress check for project ${project.id} skipped: the run has '
        'already finished.',
        level: LogLevel.info,
      );
      return;
    }

    // The reloaded row, never `object`. The serialised copy is a snapshot from
    // scheduling time, and the finish path writes the project back wholesale —
    // so passing it would revert anything edited while mipgen was running.
    session.log(
      "Checking MIP generation progress for project ID: ${project.id}",
      level: LogLevel.info,
    );
    if (await processService.checkIfMipgenProcessIsRunning(session, project)) {
      session.log(
        "MIP generation process is still running for project ID: ${project.id}",
        level: LogLevel.info,
      );
      await mipgenService.scheduleMipgenProgressCheck(session, project);
    } else {
      session.log(
        "MIP generation process has finished for project ID: ${project.id}",
        level: LogLevel.info,
      );
      await mipgenService.mipgenIsFinished(session, project);
    }
  }
}
