import 'package:flumip_server/service_locator.dart';
import 'package:flumip_server/src/generated/snp.dart';
import 'package:flumip_server/src/services/snp_service.dart';
import 'package:serverpod/serverpod.dart';

/// Fetches a custom SNP's files from the URLs its row records, then indexes it.
///
/// Registered automatically by the Serverpod 3.2+ generated future-call
/// scheduler; scheduling lives in [SnpService.scheduleSnpImport].
///
/// ## Why there is no poll loop
///
/// Unlike `CheckIndexProgressFutureCall` and `CheckMipgenProgressFutureCall`,
/// which watch an external process by its pid, this call *is* the work. The
/// download happens in-process, so it can write its own progress as bytes arrive
/// and there is nothing to poll. Socket and file I/O are off-thread in `dart:io`,
/// so a straight byte pipe does not block the server while it runs.
///
/// The server-side equivalent of the poll loop is
/// `SnpService.collectCustomSnps`' reconcile pass, which is the only thing that
/// can notice an import whose process died mid-flight — it has no way to write a
/// terminal state for itself.
class ImportSnpFutureCall extends FutureCall<Snp> {
  Future<void> run(Session session, Snp object) async {
    await sl<SnpService>().runImport(session, object.id!);
  }
}
