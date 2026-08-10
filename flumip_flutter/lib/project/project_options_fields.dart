import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/form_section.dart';
import '../ui/responsive_row.dart';
import 'project_options_form.dart';

/// The MIP design parameters, grouped by what they do rather than by which
/// column they happened to fall into.
///
/// ⚠️ The three columns this replaced were the source of the unevenness: they
/// were `spacing: 5` runs mixing `TextField`s with bare `Row(Text + Switch)`, and
/// a switch row is about 8px shorter than a field, so nothing lined up across the
/// columns. Switches are now `SwitchListTile`s in their own section, away from
/// the number fields.
///
/// Writes straight into [form] and calls [onChanged] for the values that are not
/// controllers — the switches and the score method — because those need a
/// rebuild to show their new position and a `TextEditingController` does not.
class ProjectOptionsFields extends StatelessWidget {
  const ProjectOptionsFields({
    super.key,
    required this.form,
    required this.onChanged,
  });

  final ProjectOptionsForm form;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 20,
    children: [
      FormSection(
        title: 'Capture and arms',
        children: [
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _number(
                form.minCaptureSize,
                'Min capture size',
                helper: 'Above 120.',
              ),
              _number(
                form.maxCaptureSize,
                'Max capture size',
                helper: 'Below 250.',
              ),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _text(
                form.armLengths,
                'Arm lengths',
                helper: 'Optional, e.g. 16:24,16:25,16:26.',
              ),
              _text(form.armLengthSums, 'Arm length sums'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _number(form.extMinLength, 'Ext min length'),
              _number(form.extMaxLength, 'Ext max length'),
              _number(form.ligMinLength, 'Lig min length'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _text(form.tagSizes, 'Tag sizes'),
              _decimal(form.maskedArmThreshold, 'Masked arm threshold'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _number(form.targetArmCopy, 'Target arm copy'),
              _number(form.maxArmCopyProduct, 'Max arm copy product'),
            ],
          ),
        ],
      ),
      FormSection(
        title: 'Tiling',
        children: [
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _number(form.featureFlank, 'Feature flank'),
              _number(form.captureIncrement, 'Capture increment'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _number(form.maxMipOverlap, 'Max MIP overlap'),
              _number(form.startingMipOverlap, 'Starting MIP overlap'),
            ],
          ),
          _switch('Tandem Repeats Finder', form.trf, (v) => form.trf = v),
          _switch(
            'Seal both strands',
            form.sealBothStrands,
            (v) => form.sealBothStrands = v,
          ),
          _switch(
            'Half seal both strands',
            form.halfSealBothStrands,
            (v) => form.halfSealBothStrands = v,
          ),
          _switch(
            'Double tile, strand unaware',
            form.doubleTileStrandUnaware,
            (v) => form.doubleTileStrandUnaware = v,
          ),
          _switch(
            'Double tile, strands separately',
            form.doubleTileStrandsSeparately,
            (v) => form.doubleTileStrandsSeparately = v,
          ),
        ],
      ),
      FormSection(
        title: 'Scoring',
        children: [
          DropdownButtonFormField<ScoreMethod>(
            initialValue: form.scoreMethod,
            decoration: const InputDecoration(labelText: 'Score method'),
            onChanged: (value) {
              form.scoreMethod = value ?? form.scoreMethod;
              onChanged();
            },
            items: ScoreMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _decimal(form.logisticOptimalScore, 'Logistic optimal score'),
              _decimal(form.svrOptimalScore, 'SVR optimal score'),
            ],
          ),
          ResponsiveRow(
            minChildWidth: 220,
            children: [
              _decimal(form.logisticPriorityScore, 'Logistic priority score'),
              _decimal(form.svrPriorityScore, 'SVR priority score'),
            ],
          ),
          _switch(
            'Logistic heuristic',
            form.logisticHeuristic,
            (v) => form.logisticHeuristic = v,
          ),
          _switch(
            'Check copy number',
            form.checkCopyNumber,
            (v) => form.checkCopyNumber = v,
          ),
        ],
      ),
    ],
  );

  TextField _text(TextEditingController c, String label, {String? helper}) =>
      TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, helperText: helper),
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
      );

  TextField _number(TextEditingController c, String label, {String? helper}) =>
      TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, helperText: helper),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      );

  TextField _decimal(TextEditingController c, String label) => TextField(
    controller: c,
    decoration: InputDecoration(labelText: label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
    ],
  );

  Widget _switch(String label, bool value, void Function(bool) assign) =>
      SwitchListTile(
        value: value,
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        onChanged: (v) {
          assign(v);
          onChanged();
        },
      );
}
