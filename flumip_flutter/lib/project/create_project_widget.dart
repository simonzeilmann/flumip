import 'package:flutter/material.dart';
import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class CreateProjectWidget extends StatefulWidget {
  final VoidCallback onProjectCreated;
  final VoidCallback onAbort;

  const CreateProjectWidget(
      {super.key, required this.onProjectCreated, required this.onAbort});

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
        _errorMessage = 'Failed to load default options: $e';
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
              double.tryParse(_svrPriorityScoreController.text) ?? 1.5);
      final ProjectOptions optionsInDB =
          await client.options.insertProjectOptions(options);
      await client.project.createProject(
        _nameController.text,
        optionsInDB,
        _descriptionController.text,
      );
      _nameController.clear();
      _descriptionController.clear();
      widget.onProjectCreated();
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isScreenWide = MediaQuery.sizeOf(context).width >= 1020;
    return Flexible(
        fit: FlexFit.tight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  color: Colors.red[300],
                  padding: const EdgeInsets.all(8),
                  child: Text(_errorMessage!),
                ),
              SizedBox(height: 5),
              TextField(
                controller: _nameController,
                decoration:
                    InputDecoration(labelText: 'Project Name (required)'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText: 'Project Description (optional)'),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Text('Show Options'),
                  SizedBox(width: 10),
                  Switch(
                    value: _showOptions,
                    onChanged: (value) {
                      setState(() {
                        _showOptions = value;
                      });
                    },
                  ),
                ],
              ),
              if (_showOptions) ...[
                if (isScreenWide) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      spacing: 10,
                      children: [
                        Expanded(child: buildFirstOptionsColumn()),
                        Expanded(child: buildSecondOptionsColumn()),
                        Expanded(child: buildThirdOptionsColumn()),
                      ],
                    ),
                  )
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      spacing: 10,
                      children: [
                        buildFirstOptionsColumn(),
                        buildSecondOptionsColumn(),
                        buildThirdOptionsColumn(),
                      ],
                    ),
                  )
                ],
              ],
              SizedBox(height: 35),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: widget.onAbort,
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _createProject,
                    child: Text('Create Project'),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget buildFirstOptionsColumn() {
    return Column(
      spacing: 5,
      children: [
        TextField(
          controller: _minCaptureSizeController,
          decoration: InputDecoration(labelText: 'Min Capture Size [>120]'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _maxCaptureSizeController,
          decoration: InputDecoration(labelText: 'Max Capture Size [<250]'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _armLengthsController,
          decoration: InputDecoration(
              labelText: 'Arm Lengths (optional) [16:24,16:25,16:26]'),
          keyboardType: TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        ),
        TextField(
          controller: _armLengthSumsController,
          decoration: InputDecoration(labelText: 'Arm Length Sums'),
          keyboardType: TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        ),
        TextField(
          controller: _extMinLengthController,
          decoration: InputDecoration(labelText: 'Ext Min Length'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _extMaxLengthController,
          decoration: InputDecoration(labelText: 'Ext Max Length'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _ligMinLengthController,
          decoration: InputDecoration(labelText: 'Lig Min Length'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _tagSizesController,
          decoration: InputDecoration(labelText: 'Tag Sizes'),
          keyboardType: TextInputType.text,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        ),
        TextField(
          controller: _maskedArmThresholdController,
          decoration: InputDecoration(labelText: 'Masked Arm Threshold'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
          ],
        ),
      ],
    );
  }

  Widget buildSecondOptionsColumn() {
    return Column(
      spacing: 5,
      children: [
        TextField(
          controller: _targetArmCopyController,
          decoration: InputDecoration(labelText: 'Target Arm Copy'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _maxArmCopyProductController,
          decoration: InputDecoration(labelText: 'Max Arm Copy Product'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Row(
          children: [
            Text('Tandem Repeat Finder'),
            SizedBox(width: 10),
            Switch(
              value: _trf,
              onChanged: (value) {
                setState(() {
                  _trf = value;
                });
              },
            ),
          ],
        ),
        TextField(
          controller: _featureFlankController,
          decoration: InputDecoration(labelText: 'Feature Flank'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _captureIncrementController,
          decoration: InputDecoration(labelText: 'Capture Increment'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Row(
          children: [
            Text('Logistic Heuristic'),
            SizedBox(width: 10),
            Switch(
              value: _logisticHeuristic,
              onChanged: (value) {
                setState(() {
                  _logisticHeuristic = value;
                });
              },
            ),
          ],
        ),
        TextField(
          controller: _maxMipOverlapController,
          decoration: InputDecoration(labelText: 'Max Mip Overlap'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        TextField(
          controller: _startingMipOverlapController,
          decoration: InputDecoration(labelText: 'Starting Mip Overlap'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        Row(
          children: [
            Text('Check Copy Number'),
            SizedBox(width: 10),
            Switch(
              value: _checkCopyNumber,
              onChanged: (value) {
                setState(() {
                  _checkCopyNumber = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildThirdOptionsColumn() {
    return Column(
      spacing: 5,
      children: [
        Row(
          children: [
            Text('Seal Both Strands'),
            SizedBox(width: 10),
            Switch(
              value: _sealBothStrands,
              onChanged: (value) {
                setState(() {
                  _sealBothStrands = value;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Half Seal Both Strands'),
            SizedBox(width: 10),
            Switch(
              value: _halfSealBothStrands,
              onChanged: (value) {
                setState(() {
                  _halfSealBothStrands = value;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Double Tile Strand Unaware'),
            SizedBox(width: 10),
            Switch(
              value: _doubleTileStrandUnaware,
              onChanged: (value) {
                setState(() {
                  _doubleTileStrandUnaware = value;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Double Tile Strands Separately'),
            SizedBox(width: 10),
            Switch(
              value: _doubleTileStrandsSeparately,
              onChanged: (value) {
                setState(() {
                  _doubleTileStrandsSeparately = value;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Score Method: '),
            DropdownButton<ScoreMethod>(
              value: _scoreMethod,
              onChanged: (value) {
                setState(() {
                  _scoreMethod = value!;
                });
              },
              items: ScoreMethod.values
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.toString().split('.').last),
                      ))
                  .toList(),
            ),
          ],
        ),
        TextField(
          controller: _logisticOptimalScoreController,
          decoration: InputDecoration(labelText: 'Logistic Optimal Score'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
          ],
        ),
        TextField(
          controller: _svrOptimalScoreController,
          decoration: InputDecoration(labelText: 'SVR Optimal Score'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
          ],
        ),
        TextField(
          controller: _logisticPriorityScoreController,
          decoration: InputDecoration(labelText: 'Logistic Priority Score'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
          ],
        ),
        TextField(
          controller: _svrPriorityScoreController,
          decoration: InputDecoration(labelText: 'SVR Priority Score'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}'))
          ],
        ),
      ],
    );
  }
}
