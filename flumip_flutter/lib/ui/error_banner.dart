import 'package:flutter/material.dart';

import 'theme.dart';

/// Says what went wrong, in the app's own colours.
///
/// Replaces three separately hand-rolled `Container(color: Colors.red[300])`
/// blocks — in the projects tab, the settings tab and the create-project form —
/// which were the same idea written three times, in a red that belonged to no
/// scheme and was never checked for contrast against the text laid over it.
///
/// [onDismiss] is optional because not every banner should be dismissible: one
/// that explains why a screen is empty has to stay, or the screen is just empty.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colours = context.colours;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 10, onDismiss == null ? 12 : 4, 10),
      decoration: BoxDecoration(
        color: colours.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: colours.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              message,
              style: context.text.bodySmall?.copyWith(
                color: colours.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: colours.onErrorContainer,
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
