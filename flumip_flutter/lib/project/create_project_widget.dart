import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../error_text.dart';
import '../main.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';
import 'project_options_fields.dart';
import 'project_options_form.dart';

/// The create-project form: a name, a description, and the MIP design options.
///
/// The options themselves live in [ProjectOptionsForm] and
/// [ProjectOptionsFields] — this file is the two fields that are actually about
/// the project, plus the two endpoint calls that turn the form into a row.
class CreateProjectWidget extends StatefulWidget {
  /// Called with the project that was just created, so the list can open it.
  final void Function(Project project) onProjectCreated;
  final VoidCallback onAbort;

  const CreateProjectWidget({
    super.key,
    required this.onProjectCreated,
    required this.onAbort,
  });

  @override
  CreateProjectWidgetState createState() => CreateProjectWidgetState();
}

class CreateProjectWidgetState extends State<CreateProjectWidget> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _options = ProjectOptionsForm();

  String? _errorMessage;
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultOptions();
  }

  @override
  void dispose() {
    // ⚠️ There was no `dispose` here at all, and 24 controllers to lose. Two of
    // them are still declared in this file; the other 22 are one call now.
    _nameController.dispose();
    _descriptionController.dispose();
    _options.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultOptions() async {
    try {
      final defaults = await client.options.createProjectOptions();
      if (!mounted) return;
      setState(() => _options.load(defaults));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load default options: ${describeError(e)}';
      });
    }
  }

  Future<void> _createProject() async {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Project name is required');
      return;
    }
    try {
      final stored = await client.options.insertProjectOptions(
        _options.toOptions(),
      );
      final created = await client.project.createProject(
        _nameController.text,
        stored,
        _descriptionController.text,
      );
      _nameController.clear();
      _descriptionController.clear();
      widget.onProjectCreated(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_errorMessage != null) ErrorBanner(_errorMessage!),
                  _detailsSection(),
                  _optionsToggle(),
                  if (_showOptions)
                    ProjectOptionsFields(
                      form: _options,
                      onChanged: () => setState(() {}),
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
              onPressed: _createProject,
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
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Name',
              helperText: 'Required.',
            ),
          ),
          TextField(
            controller: _descriptionController,
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
        value: _showOptions,
        title: const Text('Show options'),
        contentPadding: EdgeInsets.zero,
        onChanged: (value) => setState(() => _showOptions = value),
      ),
    ],
  );
}
