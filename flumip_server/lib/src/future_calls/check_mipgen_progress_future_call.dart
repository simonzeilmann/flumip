import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:serverpod/serverpod.dart';

/// Polls the MIP generation process for a project. Registered automatically by
/// the Serverpod 3.2+ generated future-call scheduler; scheduling lives in
/// [MipgenService.scheduleMipgenProgressCheck].
class CheckMipgenProgressFutureCall extends FutureCall<Project> {
  final processService = sl<ProcessService>();
  final mipgenService = sl<MipgenService>();

  Future<void> run(Session session, Project object) async {
    session.log(
      "Checking MIP generation progress for project ID: ${object.id}",
      level: LogLevel.info,
    );
    if (await processService.checkIfMipgenProcessIsRunning(session, object)) {
      session.log(
        "MIP generation process is still running for project ID: ${object.id}",
        level: LogLevel.info,
      );
      await mipgenService.scheduleMipgenProgressCheck(session, object);
    } else {
      session.log(
        "MIP generation process has finished for project ID: ${object.id}",
        level: LogLevel.info,
      );
      await mipgenService.mipgenIsFinished(session, object);
    }
  }
}
