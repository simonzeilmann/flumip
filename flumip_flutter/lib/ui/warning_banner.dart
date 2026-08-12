import 'package:flutter/material.dart';

import 'theme.dart';

/// Something worth reading about an operation that nonetheless worked.
///
/// ⚠️ Deliberately not an `ErrorBanner`, and the distinction is the whole reason
/// this exists. When a design run finishes but its UCSC track could not be built,
/// the MIPs are there and downloadable — dressing that as a failure sends people
/// looking for results they already have. Amber says "read this", red says
/// "nothing came out".
///
/// Lives beside `error_banner.dart` rather than in `project/` because the
/// distinction is not specific to projects; it takes its colours from
/// `StatusColors`, which is where the roles Material 3 does not define live.
class WarningBanner extends StatelessWidget {
  const WarningBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status.warningContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, size: 18, color: status.onWarningContainer),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: context.text.bodySmall?.copyWith(
                color: status.onWarningContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
