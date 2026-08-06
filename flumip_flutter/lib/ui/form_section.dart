import 'package:flutter/material.dart';

import 'theme.dart';

/// One titled group of fields, as a card.
///
/// Written for the settings tab, where the form was about thirty controls in a
/// single 400px column with 3px between them and no headings at all — so the
/// SMTP password, the settings password and "Demo mode" sat in one
/// undifferentiated run, and finding anything meant reading all of it. The
/// create-project form had the same disease and now shares the cure, which is
/// why this lives in `lib/ui/` rather than in `lib/settings/`.
///
/// Fields inside a section are laid out one per row by default. Where two
/// belong together they are wrapped in a `ResponsiveRow` explicitly, written as
/// a pair rather than produced by a chunking helper — which is what lets a field
/// with a four-line helper simply not be in a row, and lets a hostname and its
/// port share a line at `flex: [3, 1]` instead of splitting it down the middle.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.description,
  });

  final String title;

  /// One sentence on what the section is for, where that is not obvious.
  final String? description;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleMedium),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: context.text.bodySmall?.copyWith(
                  color: context.colours.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children
                .expand((child) => [child, const SizedBox(height: 16)])
                .toList()
              ..removeLast(),
          ],
        ),
      ),
    );
  }
}

/// The action bar, pinned below a scrolling form.
///
/// ⚠️ It replaces a `Center > ElevatedButton` that sat **outside** the form's
/// width constraint, so on a wide window the fields were centred in one band and
/// the button in another — near each other, but never aligned. It was also
/// inside the scroll view, so on a long form it was off screen while editing,
/// and a save error rendered at the top where nobody was looking.
class FormSaveBar extends StatelessWidget {
  /// A single "Update settings" button, for the settings tab.
  FormSaveBar({super.key, required VoidCallback onSave, required this.maxWidth})
    : children = [
        FilledButton(onPressed: onSave, child: const Text('Update settings')),
      ];

  /// Any set of actions, right-aligned. The create-project form needs two.
  const FormSaveBar.custom({
    super.key,
    required this.maxWidth,
    required this.children,
  });

  /// Matched to the form's own cap so the buttons line up with the right edge of
  /// the fields.
  final double maxWidth;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: context.colours.surface,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
