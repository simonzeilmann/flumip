import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../ui/theme.dart';

/// The MIP design parameters a project was created with.
///
/// ⚠️ Was 26 centred `Text('Label: value')` lines with `spacing: 3`, every
/// boolean spelled out twice as an `if/else` pair. Now a left-aligned definition
/// list, which is what it always was.
///
/// Pure — it takes a [ProjectOptions] and renders it, so it can be pumped in a
/// test without a server. Nothing here reads or writes anything.
class ProjectOptionsView extends StatelessWidget {
  const ProjectOptionsView({super.key, required this.options});

  final ProjectOptions options;

  /// Label/value pairs in the order mipgen's own documentation lists them.
  ///
  /// Static and separate from [build] so a test can assert on the content
  /// without going through the widget tree, and so the two optional rows —
  /// arm lengths and genome directory, which are frequently unset — have one
  /// obvious place to be omitted.
  static List<(String, String)> rowsFor(ProjectOptions o) => <(String, String)>[
    ('Min capture size', '${o.minCaptureSize}'),
    ('Max capture size', '${o.maxCaptureSize}'),
    if (o.armLengths != null && o.armLengths!.isNotEmpty)
      ('Arm lengths', o.armLengths!),
    ('Arm length sums', o.armLengthSums),
    ('Ext min length', '${o.extMinLength}'),
    ('Ext max length', '${o.extMaxLength}'),
    ('Lig min length', '${o.ligMinLength}'),
    ('Tag sizes', o.tagSizes),
    ('Masked arm threshold', '${o.maskedArmThreshold}'),
    ('Target arm copy', '${o.targetArmCopy}'),
    ('Max arm copy product', '${o.maxArmCopyProduct}'),
    if (o.genomeDir != null) ('Genome dir', o.genomeDir!),
    ('Feature flank', '${o.featureFlank}'),
    ('Capture increment', '${o.captureIncrement}'),
    ('Max MIP overlap', '${o.maxMipOverlap}'),
    ('Starting MIP overlap', '${o.startingMipOverlap}'),
    ('Tandem Repeats Finder', _onOff(o.trf)),
    ('Logistic heuristic', _onOff(o.logisticHeuristic)),
    ('Check copy number', _onOff(o.checkCopyNumber)),
    ('Seal both strands', _onOff(o.sealBothStrands)),
    ('Half seal both strands', _onOff(o.halfSealBothStrands)),
    ('Double tile, strand unaware', _onOff(o.doubleTileStrandUnaware)),
    ('Double tile, strands separately', _onOff(o.doubleTileStrandsSeparately)),
    // `.name`, not the enum's toString, which would print `ScoreMethod.logistic`.
    ('Score method', o.scoreMethod.name),
    ('Logistic optimal score', '${o.logisticOptimalScore}'),
    ('SVR optimal score', '${o.svrOptimalScore}'),
    ('Logistic priority score', '${o.logisticPriorityScore}'),
    ('SVR priority score', '${o.svrPriorityScore}'),
  ];

  static String _onOff(bool value) => value ? 'on' : 'off';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design options',
          style: context.text.labelLarge?.copyWith(
            color: context.colours.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        // ⚠️ 26 rows two pixels apart read as a wall. The line height does most
        // of the work here — padding alone separates the rows without making an
        // individual one easier to read across.
        for (final (label, value) in rowsFor(options))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    label,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colours.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    value,
                    style: context.text.bodySmall?.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
