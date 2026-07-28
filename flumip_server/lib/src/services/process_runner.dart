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
  Future<void> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
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
  }) async {
    await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
  }
}
