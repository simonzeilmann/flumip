import 'package:serverpod/serverpod.dart';

import '../generated/project.dart';
import '../services/mipgen_service.dart';
import '../services/process_service.dart';

class CheckMipgenProgressFutureCall extends FutureCall {
  final processService = ProcessService();
  final mipgenService = MipgenService();

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    if (await processService.checkIfProcessIsRunning(session, object as Project)) {
      await session.serverpod.futureCallWithDelay(
          'checkMipgenProgress', object, const Duration(seconds:  10));
    }
    else {
      await mipgenService.mipgenIsFinished(session, object);
    }
  }
}
