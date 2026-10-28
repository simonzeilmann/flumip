import 'package:flumip_client/flumip_client.dart';

/// Where a project is in its life, as one value.
///
/// The tile worked this out inline in four places from three fields — `active`,
/// `completedIn` and `error` — with slightly different combinations each time.
/// One derivation, so the collapsed row and the expanded pane cannot disagree
/// about what a project is doing.
enum ProjectState {
  /// No genome, or no genes: nothing to design against yet.
  draft,

  /// Has a genome and genes, but no BED file.
  needsBedFile,

  /// Everything is in place; the design has not been started.
  readyToRun,

  /// Started, but waiting for a free slot: the server limits how many designs
  /// run at once.
  queued,

  /// mipgen is working.
  running,

  /// Finished, with results.
  complete,

  /// Finished, with results, and something worth reading about them.
  completeWithWarning,

  /// Finished, badly.
  failed;

  static ProjectState of(Project project) {
    // ⚠️ Order matters. A finished run has `active == false` *and* a
    // `completedIn`, but a project that has never run has neither — and one that
    // failed has both plus an error. Checking `error` before `completedIn` would
    // report a project as failed on the strength of an error left over from a
    // previous run.
    if (project.active && project.completedIn == null) return running;
    // Before `completedIn`. The server clears the last run's verdict when it
    // queues a re-run, but a list fetched a moment earlier may still carry it,
    // and "waiting to run" is the truer answer either way.
    if (project.queuedAt != null) return queued;
    if (project.completedIn != null) {
      if (project.error.isNotEmpty) return failed;
      // ⚠️ Still complete. A warning means the MIPs are there and something
      // about the run is worth reading — a UCSC track that could not be built,
      // say. Reporting that as a failure is what this distinction exists to
      // stop.
      return project.warning.isEmpty ? complete : completeWithWarning;
    }
    if (project.bedFileCreated) return readyToRun;
    final hasGenes = project.genes?.isNotEmpty == true;
    if (hasGenes && project.genome != null) return needsBedFile;
    return draft;
  }

  String get label => switch (this) {
    draft => 'Draft',
    needsBedFile => 'Needs BED file',
    readyToRun => 'Ready to run',
    queued => 'Queued',
    running => 'Designing',
    complete => 'Complete',
    completeWithWarning => 'Complete',
    failed => 'Failed',
  };

  /// Whether the design is going — or waiting to — which is what drives the
  /// faster poll. A queued project has to be watched so that the tile notices
  /// the moment its run starts.
  bool get isRunning => this == running || this == queued;

  bool get isFinished =>
      this == complete || this == completeWithWarning || this == failed;

  /// Whether the run produced usable results, warning or not.
  bool get succeeded => this == complete || this == completeWithWarning;
}
