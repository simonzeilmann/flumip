import 'package:flutter/material.dart';

import '../ui/status_pill.dart';
import '../ui/theme.dart';
import 'project_state.dart';

/// What a project is doing, as a badge on its collapsed row.
///
/// Kept out of `project_state.dart` on purpose: that file is deliberately
/// Flutter-free — it imports nothing but the client and is tested as plain Dart —
/// and giving the enum a `Color` would drag `material.dart` into it.
class ProjectStatePill extends StatelessWidget {
  const ProjectStatePill({super.key, required this.state});

  final ProjectState state;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final (colour, icon) = switch (state) {
      ProjectState.draft => (context.colours.outline, Icons.edit_outlined),
      ProjectState.needsBedFile => (status.warning, Icons.pending_outlined),
      ProjectState.readyToRun => (status.info, Icons.play_circle_outline),
      ProjectState.running => (status.info, Icons.autorenew),
      ProjectState.complete => (status.success, Icons.check_circle),
      // Complete, but flagged: amber rather than green, so the row says there is
      // something to read without claiming the run failed.
      ProjectState.completeWithWarning => (status.warning, Icons.check_circle),
      ProjectState.failed => (context.colours.error, Icons.error_outline),
    };
    return StatusPill(label: state.label, icon: icon, colour: colour);
  }
}
