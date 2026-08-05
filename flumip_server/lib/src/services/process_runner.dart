import 'dart:io';

/// Thin abstraction over `dart:io` process invocation.
///
/// Services depend on this instead of calling [Process.run] / [Process.start]
/// directly so that tests can substitute a fake (see
/// `test/support/fake_process_runner.dart`) and exercise process-dependent
/// logic without the real external tools (bwa, mipgen, ps, pgrep, python, ...).
abstract class ProcessRunner {
  /// Runs [executable] to completion and returns its [ProcessResult].
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
  });

  /// Starts [executable] and returns immediately. The started process handle is
  /// intentionally not surfaced: callers fire-and-forget and locate the running
  /// process afterwards via `pgrep` (see [ProcessService.getProcessPID]).
  ///
  /// [outputPath], when given, receives the child's stdout and stderr
  /// interleaved.
  ///
  /// ⚠️ **Pass it for anything whose failure a user has to understand.** Without
  /// it the child's output goes into a pipe nobody reads, so a tool that dies
  /// explaining exactly what was wrong leaves no trace at all — which is how "MIP
  /// generation failed" came to be the entire diagnosis for every kind of
  /// failure. It also removes a hang: a child that writes more than the pipe
  /// buffer holds blocks forever on an undrained pipe.
  Future<void> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    String? outputPath,
  });
}

/// Default [ProcessRunner] used in production; delegates straight to `dart:io`.
class SystemProcessRunner implements ProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
  }

  @override
  Future<void> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    String? outputPath,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );

    if (outputPath == null) {
      // Still drained, just discarded. An undrained pipe stalls the child once
      // it has written more than the buffer holds.
      process.stdout.drain<void>();
      process.stderr.drain<void>();
      return;
    }

    // Both streams into one file, interleaved as they arrive, so the log reads
    // in the order things actually happened. `IOSink.addStream` refuses two
    // concurrent streams, hence listening by hand rather than piping twice.
    final sink = File(outputPath).openWrite();
    var openStreams = 2;
    void closeWhenBothEnd() {
      if (--openStreams == 0) sink.close().catchError((_) {});
    }

    process.stdout.listen(
      sink.add,
      onDone: closeWhenBothEnd,
      onError: (_) => closeWhenBothEnd(),
      cancelOnError: true,
    );
    process.stderr.listen(
      sink.add,
      onDone: closeWhenBothEnd,
      onError: (_) => closeWhenBothEnd(),
      cancelOnError: true,
    );
  }
}
