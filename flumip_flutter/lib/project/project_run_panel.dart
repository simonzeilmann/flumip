import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../format.dart';
import '../ui/error_banner.dart';
import '../ui/theme.dart';
import '../ui/warning_banner.dart';
import 'mipgen_progress.dart';
import 'project_state.dart';

/// What can be done with a project, and what it is doing right now.
///
/// ⚠️ Was a centred stack of `ElevatedButton`s with `SizedBox(height: 5)` between
/// them and no statement of state at all — a running design showed a single
/// button called "Show Progress", so "is this still going?" was three clicks away
/// and stale the moment the modal drew.
///
/// Everything arrives as a parameter or a callback, so this whole panel — every
/// state a project can be in, and every button offered in each — can be pumped in
/// a test. That is what the wide constructor buys.
class ProjectRunPanel extends StatelessWidget {
  const ProjectRunPanel({
    super.key,
    required this.project,
    required this.progress,
    required this.notificationsAvailable,
    required this.deleteExcessFiles,
    required this.onDeleteExcessFilesChanged,
    required this.onEmailNotificationChanged,
    required this.onCreateBedFile,
    required this.onGenerateMips,
    required this.onShowMipsResult,
    required this.onShowSnpMipsResult,
    required this.onShowUcscTrack,
    required this.onShowUcscTrackFile,
    required this.onShowDesignLog,
    required this.onShowDownloads,
  });

  final Project project;

  /// The run's progress file, re-read while the design is going.
  final MipgenProgress progress;

  /// Whether an administrator has mail switched on for this install.
  final bool notificationsAvailable;

  final bool deleteExcessFiles;
  final ValueChanged<bool> onDeleteExcessFilesChanged;
  final ValueChanged<bool> onEmailNotificationChanged;

  final VoidCallback onCreateBedFile;
  final VoidCallback onGenerateMips;
  final VoidCallback onShowMipsResult;
  final VoidCallback onShowSnpMipsResult;
  final VoidCallback onShowUcscTrack;
  final VoidCallback onShowUcscTrackFile;
  final VoidCallback onShowDesignLog;
  final VoidCallback onShowDownloads;

  /// How long the current run has been going.
  ///
  /// `Project.started` is stamped when the run begins and is what `completedIn`
  /// is measured against, so it is the right clock here too.
  Duration? get _elapsed {
    final started = project.started;
    if (started == null) return null;
    final elapsed = DateTime.now().toUtc().difference(started.toUtc());
    // Clock skew between server and browser would otherwise read "-3s".
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  @override
  Widget build(BuildContext context) {
    // One derivation, shared with the collapsed row's pill, so the two cannot
    // disagree about what this project is doing.
    final state = ProjectState.of(project);
    final idle = !state.isRunning && !state.isFinished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (idle) _BedFileStep(project: project, onCreate: onCreateBedFile),
        if (project.bedFileCreated && idle) _startSection(context),
        if (state.isRunning)
          MipgenProgressPanel(progress: progress, elapsed: _elapsed),
        if (state.succeeded) _resultSection(context),
        if (state == ProjectState.failed)
          ErrorBanner('The design failed: ${project.error}'),
      ],
    );
  }

  /// The switches that change how the run behaves, and the button that starts it.
  Widget _startSection(BuildContext context) {
    // An unowned project has nobody to notify: the server resolves the address
    // from Project.owner, and nothing sets an owner while single sign-on is off.
    // Offering a live switch there would promise mail that never arrives, so it
    // is shown disabled and says why rather than being hidden — the setting is
    // real, the install just cannot act on it.
    final hasOwner = project.owner != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: deleteExcessFiles,
          title: const Text('Delete intermediate files'),
          subtitle: const Text('Saves a lot of disk space.'),
          contentPadding: EdgeInsets.zero,
          onChanged: onDeleteExcessFilesChanged,
        ),
        if (notificationsAvailable)
          SwitchListTile(
            value: hasOwner && project.emailNotification,
            title: const Text('Email me when it finishes'),
            subtitle: hasOwner
                ? null
                : const Text('This project has no owner to notify.'),
            contentPadding: EdgeInsets.zero,
            onChanged: hasOwner ? onEmailNotificationChanged : null,
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onGenerateMips,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Generate MIPs'),
        ),
      ],
    );
  }

  /// What came out of a finished run.
  ///
  /// The progress column that used to sit between this and the start section is
  /// gone: while a run is going the tile now shows the live panel inline instead
  /// of a button that opened the log in a modal.
  Widget _resultSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, size: 18, color: context.status.success),
            const SizedBox(width: 8),
            Text('Design complete', style: context.text.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        if (project.warning.isNotEmpty) ...[
          const SizedBox(height: 8),
          WarningBanner(project.warning),
        ],
        const SizedBox(height: 8),
        _ResultFact('Took', formatDuration(project.completedIn!)),
        _ResultFact('Output', formatBytes(project.size)),
        const SizedBox(height: 12),
        // Wrap, not a column of full-width buttons: these are four peers, and at
        // this pane's width they sit two-up rather than in a tall stack.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onShowMipsResult,
              child: const Text('MIPs result'),
            ),
            OutlinedButton(
              onPressed: onShowSnpMipsResult,
              child: const Text('SNP MIPs result'),
            ),
            // Split button: the common case is one press, and the raw track file
            // — which the old flow made you read first — is tucked behind the
            // caret for whoever actually wants it.
            OutlinedButton.icon(
              onPressed: onShowUcscTrack,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('UCSC'),
            ),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  onPressed: onShowUcscTrackFile,
                  child: const Text('View track file'),
                ),
                MenuItemButton(
                  onPressed: onShowDesignLog,
                  child: const Text('View design log'),
                ),
              ],
              builder: (context, controller, child) => IconButton(
                icon: const Icon(Icons.more_horiz),
                tooltip: 'More',
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onShowDownloads,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Step one: the target regions mipgen designs against.
class _BedFileStep extends StatelessWidget {
  const _BedFileStep({required this.project, required this.onCreate});

  final Project project;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    if (project.bedFileCreated) {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: context.status.success),
          const SizedBox(width: 8),
          Text('BED file ready', style: context.text.bodyMedium),
        ],
      );
    }

    final ready = project.genes?.isNotEmpty == true && project.genome != null;
    return Tooltip(
      message: ready
          ? 'Builds the target regions mipgen will design against.'
          : 'Choose a genome and add at least one gene first.',
      child: FilledButton.tonal(
        onPressed: ready ? onCreate : null,
        child: const Text('Create BED file'),
      ),
    );
  }
}

class _ResultFact extends StatelessWidget {
  const _ResultFact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.colours.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(flex: 3, child: Text(value, style: context.text.bodySmall)),
      ],
    ),
  );
}
