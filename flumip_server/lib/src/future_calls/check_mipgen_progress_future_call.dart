import 'package:serverpod/serverpod.dart';

import '../generated/project.dart';
import '../services/mipgen_service.dart';
import '../services/process_service.dart';

class CheckMipgenProgressFutureCall extends FutureCall<Project> {
  final processService = ProcessService();
  final mipgenService = MipgenService();

  @override
  Future<void> invoke(Session session, Project? project) async {
    if (await processService.checkIfProcessIsRunning(session, project!)) {
      await session.serverpod.futureCallWithDelay(
          'checkMipgenProgress', project, const Duration(seconds:  10));
    }
    else {
      await mipgenService.mipgenIsFinished(session, project);
    }
  }
}
