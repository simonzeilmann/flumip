import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../services.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';
import 'new_project_controller.dart';
import 'project_options_fields.dart';

/// The create-project form: a name, a description, and the MIP design options.
///
/// The fields live in [NewProjectController] and `ProjectOptionsFields`; this is
/// the layout and the one decision that needs a widget — what to do once the
/// project exists.
class CreateProjectWidget extends StatefulWidget {
  const CreateProjectWidget({
    super.key,
    required this.onProjectCreated,
    required this.onAbort,
    this.controller,
  });

  /// Called with the project that was just created, so the list can open it.
  final void Function(Project project) onProjectCreated;
  final VoidCallback onAbort;

  /// The controller to use, or null to build one from the app-wide client.
  ///
  /// ⚠️ Owned by this widget when it builds its own, and built fresh every time
  /// the form is opened — a half-filled form from a cancelled attempt should not
  /// come back.
  final NewProjectController? controller;

  @override
  State<CreateProjectWidget> createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  late final bool _ownsController = widget.controller == null;
  late final NewProjectController _controller =
      widget.controller ?? createNewProjectController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.loadDefaults();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final created = await _controller.create();
    if (created != null) widget.onProjectCreated(created);
  }

  @override
  Widget build(BuildContext context) {
    final error = _controller.errorMessage;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ContentWidth(
              maxWidth: ContentWidth.form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: [
                  if (error != null)
                    ErrorBanner(error, onDismiss: _controller.dismissError),
                  _detailsSection(),
                  _optionsToggle(),
                  if (_controller.showOptions)
                    ProjectOptionsFields(
                      form: _controller.options,
                      onChanged: _controller.optionsChanged,
                    ),
                ],
              ),
            ),
          ),
        ),
        FormSaveBar.custom(
          maxWidth: ContentWidth.form,
          children: [
            TextButton(onPressed: widget.onAbort, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _create,
              child: const Text('Create project'),
            ),
          ],
        ),
      ],
    );
  }

  /// Name and description.
  ///
  /// ⚠️ Neither field is full-bleed any more. They used to be direct children of
  /// a `Column` with no spacing at all, so the two boxes touched — and after the
  /// projects list was capped at 1400px they were 1400px wide for a project
  /// called "test33".
  FormSection _detailsSection() => FormSection(
    title: 'Project',
    children: [
      ResponsiveRow(
        minChildWidth: 260,
        // The name is short and the description is not, so an even split would
        // waste the room the description actually needs.
        flex: const [2, 3],
        children: [
          TextField(
            controller: _controller.name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText: 'Required.',
            ),
          ),
          TextField(
            controller: _controller.description,
            // A description is prose, so it gets a box that grows rather than a
            // one-line field that scrolls sideways.
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Description',
              helperText: 'Optional.',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _optionsToggle() => FormSection(
    title: 'MIP design options',
    description:
        'Defaults come from the server and suit most panels. '
        'Change them only if you know which knob you are turning.',
    children: [
      SwitchListTile(
        value: _controller.showOptions,
        title: const Text('Show options'),
        contentPadding: EdgeInsets.zero,
        onChanged: (_) => _controller.toggleOptions(),
      ),
    ],
  );
}
