import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/genome.dart';
import 'package:flumip_server/src/services/genome_service.dart';
import 'package:flumip_server/src/services/process_service.dart';
import 'package:serverpod/serverpod.dart';

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
          'checkIndexProgress', object, const Duration(minutes: 1));
    } else {
      session.log(
          "BWA index process has finished for project ID: ${object.id}",
          level: LogLevel.info);
      await geneService.indexIsFinished(session, object);
    }
  }
}
