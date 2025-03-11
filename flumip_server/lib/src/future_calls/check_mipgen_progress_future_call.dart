import 'package:serverpod/serverpod.dart';

import '../generated/project.dart';
import '../services/mipgen_service.dart';
import '../services/process_service.dart';

class CheckMipgenProgressFutureCall extends FutureCall<Project> {
  final processService = ProcessService();
  final mipgenService = MipgenService();

  @override
  Future<void> invoke(Session session, Project? object) async {
    session.log(
        "Checking MIP generation progress for project ID: ${object?.id}",
        level: LogLevel.info);
    if (await processService.checkIfProcessIsRunning(session, object!)) {
      session.log(
          "MIP generation process is still running for project ID: ${object.id}",
          level: LogLevel.info);
      await session.serverpod.futureCallWithDelay(
          'checkMipgenProgress', object, const Duration(seconds: 10));
    } else {
      session.log(
          "MIP generation process has finished for project ID: ${object.id}",
          level: LogLevel.info);
      await mipgenService.mipgenIsFinished(session, object);
    }
  }
}
