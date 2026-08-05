import 'dart:io';

import 'package:flumip_server/src/services/process_runner.dart';

/// A single recorded call to [ProcessRunner.run] or [ProcessRunner.start].
class ProcessInvocation {
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final bool runInShell;

  /// True when the call came through [ProcessRunner.start], false for [run].
  final bool started;

  /// Where the child's output was directed, for a [ProcessRunner.start] call.
  final String? outputPath;

  /// The deadline the caller gave, for a [ProcessRunner.run] call.
  final Duration? timeout;

  ProcessInvocation({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.runInShell,
    required this.started,
    this.outputPath,
    this.timeout,
  });
}

/// In-memory [ProcessRunner] for tests.
///
/// - `run` returns a canned [ProcessResult] configured per executable via
///   [stubRun] (falling back to [defaultRunResult]); set [runError] to make it
///   throw.
/// - `start` is a no-op that only records the invocation (the real callers
///   discard the started process); set [startError] to make it throw.
///
/// Every call is recorded in [invocations] so tests can assert the exact
/// executable, arguments, and working directory that a service built.
class FakeProcessRunner implements ProcessRunner {
  final List<ProcessInvocation> invocations = [];
  final Map<String, ProcessResult> _runStubs = {};

  ProcessResult defaultRunResult;
  Object? runError;
  Object? startError;

  /// Written to a start call's `outputPath`, standing in for the child's own
  /// output so tests can exercise what is done with it.
  String? startOutput;

  FakeProcessRunner({ProcessResult? defaultRunResult})
      : defaultRunResult = defaultRunResult ?? ProcessResult(0, 0, '', '');

  /// Clears all recorded invocations, stubs, and error overrides. Call from a
  /// test `setUp` when the same fake instance is shared across a group.
  void reset() {
    invocations.clear();
    _runStubs.clear();
    runError = null;
    startError = null;
    startOutput = null;
    defaultRunResult = ProcessResult(0, 0, '', '');
  }

  /// Configures the [ProcessResult] returned when [run] is invoked with
  /// [executable].
  void stubRun(
    String executable, {
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    int pid = 0,
  }) {
    _runStubs[executable] = ProcessResult(pid, exitCode, stdout, stderr);
  }

  List<ProcessInvocation> get runCalls =>
      invocations.where((i) => !i.started).toList();

  List<ProcessInvocation> get startCalls =>
      invocations.where((i) => i.started).toList();

  /// The most recent invocation of [executable] (run or start), or null.
  ProcessInvocation? lastFor(String executable) {
    for (var i = invocations.length - 1; i >= 0; i--) {
      if (invocations[i].executable == executable) return invocations[i];
    }
    return null;
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    Duration? timeout,
  }) async {
    invocations.add(ProcessInvocation(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
      started: false,
      timeout: timeout,
    ));
    if (runError != null) throw runError!;
    return _runStubs[executable] ?? defaultRunResult;
  }

  @override
  Future<void> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    String? outputPath,
  }) async {
    invocations.add(ProcessInvocation(
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
      started: true,
      outputPath: outputPath,
    ));
    if (startError != null) throw startError!;
    // Stand in for the child writing something, so tests that assert on the log
    // have a file to read.
    if (outputPath != null && startOutput != null) {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(startOutput!);
    }
  }
}
