import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../snp/snp_status.dart';
import '../ui/error_banner.dart';
import '../ui/theme.dart';
import 'gene_editor.dart';

/// What a project is going to be designed against: a genome, an optional SNP set
/// and a list of genes.
///
/// Takes its data and its callbacks as parameters and never touches `client`, so
/// it is testable — unlike the tile that hosts it, which imports `main.dart` and
/// therefore builds a Serverpod client at import time.
class ProjectInputsColumn extends StatelessWidget {
  const ProjectInputsColumn({
    super.key,
    required this.project,
    required this.genome,
    required this.snp,
    required this.snpsForGenome,
    required this.onPickGenome,
    required this.onSnpChanged,
    required this.onAddGene,
    required this.onRemoveGene,
    this.errorMessage,
    this.onDismissError,
  });

  final Project project;

  /// The loaded genome, or null while it is still being fetched.
  ///
  /// Null and "the project has no genome" are different states and read
  /// differently — `Loading…` against `None chosen` — which is why this is a
  /// nullable rather than the `Genome(name: 'default')` sentinel it used to be.
  final Genome? genome;

  /// The project's chosen SNP set, or null when it has none or it is still being
  /// fetched.
  final Snp? snp;

  /// The SNP sets available for [genome].
  ///
  /// ⚠️ Nullable, and null means "not yet knowable". The caller cannot start this
  /// query until the genome has loaded and has an id, and the previous version
  /// reached for `genome.id!` during the frame between expanding a tile and its
  /// genome arriving — which throws, and Flutter paints a thrown build as the red
  /// screen over the whole tab.
  final Future<List<Snp>>? snpsForGenome;

  final VoidCallback onPickGenome;

  /// Called with the new SNP set's id, or null to clear the choice.
  final void Function(int? snpId) onSnpChanged;

  final void Function(String gene) onAddGene;
  final void Function(String gene) onRemoveGene;

  final String? errorMessage;
  final VoidCallback? onDismissError;

  /// Whether a project can still be changed: once a run has started or finished,
  /// its inputs describe what was actually designed.
  ///
  /// Public and static because the tile needs the same answer to decide whether
  /// listing the available SNP sets is worth a round trip, and two copies of this
  /// rule would eventually disagree.
  static bool isEditable(Project project) =>
      !project.active && project.completedIn == null;

  bool get _editable => isEditable(project);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        if (errorMessage != null)
          ErrorBanner(errorMessage!, onDismiss: onDismissError),
        _InputRow(label: 'Genome', child: _genomeValue(context)),
        _InputRow(label: 'SNP set', child: _snpValue(context)),
        _InputRow(
          label: 'Genes',
          child: GeneEditor(
            genes: project.genes ?? const <String>[],
            editable: !project.bedFileCreated,
            onAdd: onAddGene,
            onRemove: onRemoveGene,
          ),
        ),
      ],
    );
  }

  /// What genome is chosen, and the way to change it.
  ///
  /// ⚠️ The picker used to disappear the moment a genome was set, replaced by
  /// plain text — so a genome chosen by mistake could not be corrected without
  /// deleting the project.
  Widget _genomeValue(BuildContext context) {
    final chosen = project.genome != null;
    final loading = chosen && genome == null;
    final name = loading
        ? 'Loading…'
        : chosen
        ? genome!.name
        : (_editable ? 'None chosen' : 'None');

    if (!_editable) return Text(name);

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: chosen
                ? null
                : TextStyle(color: context.colours.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onPickGenome,
          child: Text(chosen ? 'Change' : 'Choose'),
        ),
      ],
    );
  }

  Widget _snpValue(BuildContext context) {
    if (project.genome == null) {
      return Text(
        'Choose a genome first.',
        style: TextStyle(color: context.colours.onSurfaceVariant),
      );
    }
    if (!_editable) return Text(snp?.name ?? 'None');
    if (snpsForGenome == null) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return _SnpSelector(
      snps: snpsForGenome!,
      selectedId: project.snp,
      onChanged: onSnpChanged,
    );
  }
}

/// A label above its control, so the three inputs read as one form.
class _InputRow extends StatelessWidget {
  const _InputRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.text.labelLarge?.copyWith(
          color: context.colours.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// The SNP picker.
///
/// Two-way, unlike the first version, which vanished the moment a selection was
/// made. That was tolerable when an SNP set was an immortal scan result. Custom
/// ones can fail to import or be deleted out from under a project, so being able
/// to change or clear the choice is now the difference between fixing a project
/// and abandoning it.
class _SnpSelector extends StatelessWidget {
  const _SnpSelector({
    required this.snps,
    required this.selectedId,
    required this.onChanged,
  });

  final Future<List<Snp>> snps;
  final int? selectedId;
  final void Function(int? snpId) onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Snp>>(
      future: snps,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Failed to load SNP sets: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final snps = snapshot.data!;
        if (snps.isEmpty) {
          return Text(
            'No SNP sets for this genome.',
            style: TextStyle(color: context.colours.onSurfaceVariant),
          );
        }

        // ⚠️ A DropdownButton whose value matches no item throws. Now that an SNP
        // can be deleted, or stop being visible to us, the project's SNP can
        // point at something no longer in this list. Same guard, and same reason,
        // as the owner picker.
        final selected = snps.where((s) => s.id == selectedId).firstOrNull;
        final dangling = selectedId != null && selected == null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A form field rather than a bare DropdownButton, so it carries the
            // same outline and density as every other input.
            DropdownButtonFormField<Snp?>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(helperText: 'Optional.'),
              onChanged: (chosen) => onChanged(chosen?.id),
              items: [
                const DropdownMenuItem<Snp?>(
                  value: null,
                  child: Text('No SNP set'),
                ),
                ...snps.map(
                  (s) => DropdownMenuItem<Snp?>(
                    value: s,
                    enabled: s.status == SnpImportStatus.ready,
                    child: Text(
                      s.status == SnpImportStatus.ready
                          ? s.name
                          : '${s.name} (${statusLabel(s.status)})',
                      style: TextStyle(
                        color: s.status == SnpImportStatus.ready
                            ? null
                            : context.colours.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (dangling)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'The SNP set this project was using is no longer '
                  'available. Pick another, or none.',
                  style: TextStyle(color: context.status.warning, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
