import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../error_text.dart';
import '../ui/error_banner.dart';
import '../ui/form_section.dart';
import '../ui/layout.dart';
import '../ui/responsive_row.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _minCaptureSizeController =
      TextEditingController();
  final TextEditingController _maxCaptureSizeController =
      TextEditingController();
  final TextEditingController _armLengthsController = TextEditingController();
  final TextEditingController _armLengthSumsController =
      TextEditingController();
  final TextEditingController _extMinLengthController = TextEditingController();
  final TextEditingController _extMaxLengthController = TextEditingController();
  final TextEditingController _ligMinLengthController = TextEditingController();
  final TextEditingController _tagSizesController = TextEditingController();
  final TextEditingController _maskedArmThresholdController =
      TextEditingController();
  final TextEditingController _targetArmCopyController =
      TextEditingController();
  final TextEditingController _maxArmCopyProductController =
      TextEditingController();
  bool _trf = false;
  final TextEditingController _featureFlankController = TextEditingController();
  final TextEditingController _captureIncrementController =
      TextEditingController();
  bool _logisticHeuristic = false;
  final TextEditingController _maxMipOverlapController =
      TextEditingController();
  final TextEditingController _startingMipOverlapController =
      TextEditingController();
  bool _checkCopyNumber = true;
  bool _sealBothStrands = false;
  bool _halfSealBothStrands = false;
  bool _doubleTileStrandUnaware = false;
  bool _doubleTileStrandsSeparately = false;
  ScoreMethod _scoreMethod = ScoreMethod.logistic;
  final TextEditingController _logisticOptimalScoreController =
      TextEditingController();
  final TextEditingController _svrOptimalScoreController =
      TextEditingController();
  final TextEditingController _logisticPriorityScoreController =
      TextEditingController();
  final TextEditingController _svrPriorityScoreController =
      TextEditingController();

  String? _errorMessage;
  ProjectOptions? _projectOptions;
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultOptions();
  }

  void _initializeDefaultOptions() async {
    try {
      _projectOptions = await client.options.createProjectOptions();
      setState(() {
        _minCaptureSizeController.text =
            _projectOptions?.minCaptureSize.toString() ?? '';
        _maxCaptureSizeController.text =
            _projectOptions?.maxCaptureSize.toString() ?? '';
        _armLengthsController.text = '';
        _armLengthSumsController.text =
            _projectOptions?.armLengthSums.toString() ?? '';
        _extMinLengthController.text =
            _projectOptions?.extMinLength.toString() ?? '';
        _extMaxLengthController.text =
            _projectOptions?.extMaxLength.toString() ?? '';
        _ligMinLengthController.text =
            _projectOptions?.ligMinLength.toString() ?? '';
        _tagSizesController.text = _projectOptions?.tagSizes.toString() ?? '';
        _maskedArmThresholdController.text =
            _projectOptions?.maskedArmThreshold.toString() ?? '';
        _targetArmCopyController.text =
            _projectOptions?.targetArmCopy.toString() ?? '';
        _maxArmCopyProductController.text =
            _projectOptions?.maxArmCopyProduct.toString() ?? '';
        _trf = _projectOptions?.trf ?? false;
        _featureFlankController.text =
            _projectOptions?.featureFlank.toString() ?? '';
        _captureIncrementController.text =
            _projectOptions?.captureIncrement.toString() ?? '';
        _logisticHeuristic = _projectOptions?.logisticHeuristic ?? false;
        _maxMipOverlapController.text =
            _projectOptions?.maxMipOverlap.toString() ?? '';
        _startingMipOverlapController.text =
            _projectOptions?.startingMipOverlap.toString() ?? '';
        _checkCopyNumber = _projectOptions?.checkCopyNumber ?? true;
        _sealBothStrands = _projectOptions?.sealBothStrands ?? false;
        _halfSealBothStrands = _projectOptions?.halfSealBothStrands ?? false;
        _doubleTileStrandUnaware =
            _projectOptions?.doubleTileStrandUnaware ?? false;
        _doubleTileStrandsSeparately =
            _projectOptions?.doubleTileStrandsSeparately ?? false;
        _scoreMethod = _projectOptions?.scoreMethod ?? ScoreMethod.logistic;
        _logisticOptimalScoreController.text =
            _projectOptions?.logisticOptimalScore.toString() ?? '';
        _svrOptimalScoreController.text =
            _projectOptions?.svrOptimalScore.toString() ?? '';
        _logisticPriorityScoreController.text =
            _projectOptions?.logisticPriorityScore.toString() ?? '';
        _svrPriorityScoreController.text =
            _projectOptions?.svrPriorityScore.toString() ?? '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load default options: ${describeError(e)}';
      });
    }
  }

  void _createProject() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Project name is required';
      });
      return;
    }
    try {
      var options = ProjectOptions(
        minCaptureSize: int.tryParse(_minCaptureSizeController.text) ?? 162,
        maxCaptureSize: int.tryParse(_maxCaptureSizeController.text) ?? 162,
        armLengths: _armLengthsController.text,
        armLengthSums: _armLengthSumsController.text,
        extMinLength: int.tryParse(_extMinLengthController.text) ?? 16,
        extMaxLength: int.tryParse(_extMinLengthController.text) ?? 18,
        ligMinLength: int.tryParse(_ligMinLengthController.text) ?? 18,
        tagSizes: _tagSizesController.text,
        maskedArmThreshold:
            double.tryParse(_maskedArmThresholdController.text) ?? 0.5,
        targetArmCopy: int.tryParse(_targetArmCopyController.text) ?? 20,
        maxArmCopyProduct:
            int.tryParse(_maxArmCopyProductController.text) ?? 75,
        trf: _trf,
        featureFlank: int.tryParse(_featureFlankController.text) ?? 0,
        captureIncrement: int.tryParse(_captureIncrementController.text) ?? 5,
        logisticHeuristic: _logisticHeuristic,
        maxMipOverlap: int.tryParse(_maxMipOverlapController.text) ?? 30,
        startingMipOverlap:
            int.tryParse(_startingMipOverlapController.text) ?? 0,
        checkCopyNumber: _checkCopyNumber,
        sealBothStrands: _sealBothStrands,
        halfSealBothStrands: _halfSealBothStrands,
        doubleTileStrandUnaware: _doubleTileStrandUnaware,
        doubleTileStrandsSeparately: _doubleTileStrandsSeparately,
        scoreMethod: _scoreMethod,
        logisticOptimalScore:
            double.tryParse(_logisticOptimalScoreController.text) ?? 0.98,
        svrOptimalScore:
            double.tryParse(_svrOptimalScoreController.text) ?? 2.2,
        logisticPriorityScore:
            double.tryParse(_logisticPriorityScoreController.text) ?? 0.9,
        svrPriorityScore:
            double.tryParse(_svrPriorityScoreController.text) ?? 1.5,
      );
      final ProjectOptions optionsInDB = await client.options
          .insertProjectOptions(options);
      final created = await client.project.createProject(
        _nameController.text,
        optionsInDB,
        _descriptionController.text,
      );
      _nameController.clear();
      _descriptionController.clear();
      widget.onProjectCreated(created);
    } catch (e) {
      setState(() {
        _errorMessage = describeError(e);
      });
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
                  _optionsToggle(context),
                  if (_showOptions) ..._optionSections(),
                ],
              ),
            ),
          ),
        ),
        _actions(context),
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
        // The name is short and the description is not, so an even split
        // would waste the room the description actually needs.
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
            // A description is prose, so it gets a box that grows rather
            // than a one-line field that scrolls sideways.
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

  Widget _optionsToggle(BuildContext context) => FormSection(
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

  /// The options, grouped by what they do rather than by which column they fell
  /// into.
  ///
  /// ⚠️ The three columns this replaces were the source of the unevenness: they
  /// were `spacing: 5` runs mixing `TextField`s with bare `Row(Text + Switch)`,
  /// and a switch row is about 8px shorter than a field, so nothing lined up
  /// across the columns. Switches are now `SwitchListTile`s in their own
  /// section, away from the number fields.
  List<Widget> _optionSections() => [
    FormSection(
      title: 'Capture and arms',
      children: [
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _number(
              _minCaptureSizeController,
              'Min capture size',
              helper: 'Above 120.',
            ),
            _number(
              _maxCaptureSizeController,
              'Max capture size',
              helper: 'Below 250.',
            ),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _text(
              _armLengthsController,
              'Arm lengths',
              helper: 'Optional, e.g. 16:24,16:25,16:26.',
            ),
            _text(_armLengthSumsController, 'Arm length sums'),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _number(_extMinLengthController, 'Ext min length'),
            _number(_extMaxLengthController, 'Ext max length'),
            _number(_ligMinLengthController, 'Lig min length'),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _text(_tagSizesController, 'Tag sizes'),
            _decimal(_maskedArmThresholdController, 'Masked arm threshold'),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _number(_targetArmCopyController, 'Target arm copy'),
            _number(_maxArmCopyProductController, 'Max arm copy product'),
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
            _number(_featureFlankController, 'Feature flank'),
            _number(_captureIncrementController, 'Capture increment'),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _number(_maxMipOverlapController, 'Max MIP overlap'),
            _number(_startingMipOverlapController, 'Starting MIP overlap'),
          ],
        ),
        _switch('Tandem Repeats Finder', _trf, (v) => _trf = v),
        _switch(
          'Seal both strands',
          _sealBothStrands,
          (v) => _sealBothStrands = v,
        ),
        _switch(
          'Half seal both strands',
          _halfSealBothStrands,
          (v) => _halfSealBothStrands = v,
        ),
        _switch(
          'Double tile, strand unaware',
          _doubleTileStrandUnaware,
          (v) => _doubleTileStrandUnaware = v,
        ),
        _switch(
          'Double tile, strands separately',
          _doubleTileStrandsSeparately,
          (v) => _doubleTileStrandsSeparately = v,
        ),
      ],
    ),
    FormSection(
      title: 'Scoring',
      children: [
        DropdownButtonFormField<ScoreMethod>(
          initialValue: _scoreMethod,
          decoration: const InputDecoration(labelText: 'Score method'),
          onChanged: (value) =>
              setState(() => _scoreMethod = value ?? _scoreMethod),
          items: ScoreMethod.values
              .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
              .toList(),
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _decimal(_logisticOptimalScoreController, 'Logistic optimal score'),
            _decimal(_svrOptimalScoreController, 'SVR optimal score'),
          ],
        ),
        ResponsiveRow(
          minChildWidth: 220,
          children: [
            _decimal(
              _logisticPriorityScoreController,
              'Logistic priority score',
            ),
            _decimal(_svrPriorityScoreController, 'SVR priority score'),
          ],
        ),
        _switch(
          'Logistic heuristic',
          _logisticHeuristic,
          (v) => _logisticHeuristic = v,
        ),
        _switch(
          'Check copy number',
          _checkCopyNumber,
          (v) => _checkCopyNumber = v,
        ),
      ],
    ),
  ];

  Widget _actions(BuildContext context) => FormSaveBar.custom(
    maxWidth: ContentWidth.form,
    children: [
      TextButton(onPressed: widget.onAbort, child: const Text('Cancel')),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _createProject,
        child: const Text('Create project'),
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
        onChanged: (v) => setState(() => assign(v)),
      );
}
