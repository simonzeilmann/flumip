import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/project.dart';
import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:serverpod/serverpod.dart';

class CheckMipgenProgressFutureCall extends FutureCall<Project> {
  final processService = sl<ProcessService>();
  final mipgenService = sl<MipgenService>();

  @override
  Future<void> invoke(Session session, Project? object) async {
    session.log(
      "Checking MIP generation progress for project ID: ${object?.id}",
      level: LogLevel.info,
    );
    if (await processService.checkIfMipgenProcessIsRunning(session, object!)) {
      session.log(
        "MIP generation process is still running for project ID: ${object.id}",
        level: LogLevel.info,
      );
      await session.serverpod.futureCallWithDelay(
        'checkMipgenProgress',
        object,
        const Duration(seconds: 10),
      );
    } else {
      session.log(
        "MIP generation process has finished for project ID: ${object.id}",
        level: LogLevel.info,
      );
      await mipgenService.mipgenIsFinished(session, object);
    }
  }
}
