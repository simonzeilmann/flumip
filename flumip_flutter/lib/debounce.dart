/// Waiting for somebody to stop typing, for anything that asks the server as
/// they type.
///
/// The counterpart of `poll.dart`: that file answers "something might be changing
/// on the server, how often do I look?", this one answers "the user is changing
/// something here, when do I act on it?". Same shape, same reason for living at
/// the root — pure Dart, no Flutter import, so it is testable on the VM.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// How long to wait after the last keystroke before asking the server.
///
/// Below about 150 ms the round trip *is* the debounce and nothing is saved;
/// above about 400 ms typing starts to feel like it is being ignored. 250 ms
/// collapses a typed word into a single request, which is the whole point — the
/// search controller's per-query cache then removes most of what is left.
const Duration searchDebounce = Duration(milliseconds: 250);

/// Runs the last action handed to it, once the calls stop coming.
///
/// Deliberately holds the *action* rather than being constructed with one: the
/// caller wants the closure that captures the query as it was on the last
/// keystroke, not the one from whenever the debouncer was built.
class Debouncer {
  Debouncer(this.delay);

  /// How long a quiet spell has to be before [run]'s action fires.
  final Duration delay;

  Timer? _timer;

  /// Schedules [action], cancelling whatever was scheduled before it.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Drops a pending action. Called when the answer arrives from somewhere else
  /// — a cache hit — or when the query gets too short to be worth asking about.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether an action is actually still waiting to fire.
  ///
  /// ⚠️ `isActive`, not `_timer != null`: a one-shot [Timer] stays referenced
  /// after it has fired, so the field alone would claim a debounce is pending
  /// forever. The same trap `GenomeController.polling` documents.
  @visibleForTesting
  bool get pending => _timer?.isActive ?? false;
}
