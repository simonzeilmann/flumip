import 'package:flutter/material.dart';

import 'theme.dart';

/// Something the user should know that is neither a problem nor a warning —
/// a run waiting in the queue, how long this server keeps projects.
///
/// The blue sibling of `WarningBanner` and `ErrorBanner`, with the same shape,
/// so the three read as one family.
class InfoBanner extends StatelessWidget {
  const InfoBanner(this.message, {super.key, this.icon = Icons.info_outline});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status.infoContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: status.info),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message,
              style: context.text.bodySmall?.copyWith(color: status.info),
            ),
          ),
        ],
      ),
    );
  }
}
