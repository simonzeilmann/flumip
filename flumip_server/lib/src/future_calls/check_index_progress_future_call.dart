import 'package:serverpod/serverpod.dart';

import '../../service_locator.dart';
import '../generated/protocol.dart';
import '../services/genome_service.dart';
import '../services/process_service.dart';

class CheckIndexProgressFutureCall extends FutureCall<Genome> {
  final processService = sl<ProcessService>();
  final geneService = sl<GenomeService>();

  @override
  Future<void> invoke(Session session, Genome? object) async {
    session.log(
        "Checking BWA index progress for gene ID: ${object?.id}",
        level: LogLevel.info);
    if (await processService.checkIfIndexProcessIsRunning(session, object!)) {
      session.log(
          "BWA index process is still running for gene ID: ${object.id}",
          level: LogLevel.info);
      await session.serverpod.futureCallWithDelay(
          'checkIndexProgress', object, const Duration(seconds: 30));
    } else {
      session.log(
          "BWA index process has finished for project ID: ${object.id}",
          level: LogLevel.info);
      await geneService.indexIsFinished(session, object);
    }
  }
}
