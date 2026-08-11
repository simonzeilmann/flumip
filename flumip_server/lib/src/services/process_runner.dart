import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The first meaningful line of a tool's output, bounded.
///
/// External tools front-load configuration echo and back-load the actual
/// complaint, so the first line of *stderr* is nearly always the useful one.
/// Bounded because it ends up in a database column and on a screen.
String firstLineOf(String text, {int maxLength = 200}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '';
  final line = trimmed.split('\n').first.trim();
  return line.length > maxLength ? '${line.substring(0, maxLength)}…' : line;
}

/// The executable is not installed, or not where the settings say it is.
///
/// A separate type because it is the one process failure with an obvious remedy,
/// and because the raw [ProcessException] for it — "No such file or directory,
/// errno = 2" — names the problem in a way nobody outside this file would
/// recognise as "bwa is not installed".
class ToolUnavailableException implements Exception {
  ToolUnavailableException(this.executable, this.cause);

  final String executable;
  final Object cause;

  @override
  String toString() =>
      'The program "$executable" could not be run. It is either not installed '
      'or not at the path configured in the settings.';
}

/// The program was still running when its deadline passed, and was killed.
class ProcessTimeoutException implements Exception {
  ProcessTimeoutException(this.executable, this.timeout, this.partialStderr);

  final String executable;
  final Duration timeout;

  /// Whatever it had complained about before it was killed, which is usually
  /// the most useful thing about a hang.
  final String partialStderr;

  @override
  String toString() {
    final tail = partialStderr.trim();
    final because = tail.isEmpty ? '' : ' Its last output was: $tail';
    return '"$executable" did not finish within '
        '${timeout.inSeconds} seconds and was stopped.$because';
  }
}

/// Thin abstraction over `dart:io` process invocation.
///
/// Services depend on this instead of calling [Process.run] / [Process.start]
/// directly so that tests can substitute a fake (see
/// `test/support/fake_process_runner.dart`) and exercise process-dependent
/// logic without the real external tools (bwa, mipgen, ps, pgrep, python, ...).
abstract class ProcessRunner {
  /// Runs [executable] to completion and returns its [ProcessResult].
  ///
  /// [timeout], when given, kills the program if it outruns it and throws
  /// [ProcessTimeoutException].
  ///
  /// ⚠️ **Give a timeout to anything invoked from a request or a future call.**
  /// Without one a wedged program holds its caller open for the life of the
  /// process — there is no cancellation, and the row it was working on stays in
  /// whatever state it was left in.
  ///
  /// Throws [ToolUnavailableException] when the program is not installed.
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    Duration? timeout,
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
  ///
  /// Throws [ToolUnavailableException] when the program is not installed.
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
    Duration? timeout,
  }) async {
    // `Process.run` cannot be cancelled, so anything with a deadline has to be
    // started and waited on by hand.
    final process = await _start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );

    // ⚠️ Accumulated into buffers rather than awaited with `join()`, and the
    // difference is the whole timeout.
    //
    // Killing a process does not close pipes its *own* children inherited. A
    // tool that shells out — which several here do — leaves a grandchild holding
    // the write end, so `join()` would not complete until that grandchild
    // exited. Waiting on it after a kill reproduces exactly the hang the
    // deadline exists to prevent, which is how the first version of this
    // silently did nothing.
    //
    // Draining is still mandatory: an undrained pipe stalls the child once it
    // has written more than the buffer holds.
    final out = StringBuffer();
    final err = StringBuffer();
    final outClosed = Completer<void>();
    final errClosed = Completer<void>();
    void complete(Completer<void> c) {
      if (!c.isCompleted) c.complete();
    }

    process.stdout
        .transform(utf8.decoder)
        .listen(
          out.write,
          onDone: () => complete(outClosed),
          onError: (_) => complete(outClosed),
        );
    process.stderr
        .transform(utf8.decoder)
        .listen(
          err.write,
          onDone: () => complete(errClosed),
          onError: (_) => complete(errClosed),
        );

    var timedOut = false;
    Timer? timer;
    if (timeout != null) {
      timer = Timer(timeout, () {
        timedOut = true;
        process.kill(ProcessSignal.sigkill);
      });
    }

    final exitCode = await process.exitCode;
    timer?.cancel();

    // Let anything already in flight land, but never wait on it indefinitely —
    // see above. On a normal exit both close at once and this costs nothing.
    await Future.wait([
      outClosed.future,
      errClosed.future,
    ]).timeout(streamCloseGrace, onTimeout: () => const []);

    if (timedOut) {
      throw ProcessTimeoutException(executable, timeout!, err.toString());
    }
    return ProcessResult(process.pid, exitCode, out.toString(), err.toString());
  }

  /// How long to wait for output still in flight once the program has exited.
  ///
  /// Bounded because a grandchild can hold the pipe open after its parent is
  /// gone; the collected output is used either way.
  static const streamCloseGrace = Duration(seconds: 2);

  @override
  Future<void> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
    String? outputPath,
  }) async {
    final process = await _start(
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

  /// [Process.start], with a missing program reported in words.
  Future<Process> _start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool runInShell = false,
  }) async {
    try {
      return await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: runInShell,
      );
    } on ProcessException catch (e) {
      throw ToolUnavailableException(executable, e);
    }
  }
}
