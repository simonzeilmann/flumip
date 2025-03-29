import 'package:flumip_client/flumip_client.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _errorMessage;
  Settings? settings;

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _baseDirController = TextEditingController();
  final TextEditingController _projectDirController = TextEditingController();
  final TextEditingController _genomeDirController = TextEditingController();
  final TextEditingController _customSnpDirController = TextEditingController();
  final TextEditingController _toolsDirController = TextEditingController();
  final TextEditingController _mipgenExecutableController =
  TextEditingController();
  final TextEditingController _exonExtractScriptController =
  TextEditingController();
  final TextEditingController _ucscTrackGeneratorController =
  TextEditingController();
  final TextEditingController _bigGenePredToGenePredExecutable = TextEditingController();
  final TextEditingController _binCreationScript = TextEditingController();
  final TextEditingController _smtpServerController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUserController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();
  final TextEditingController _smtpFromController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  final ValueNotifier<bool> _mailActiveNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _startTLSNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _loginRequiredNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _baseDirController.dispose();
    _projectDirController.dispose();
    _genomeDirController.dispose();
    _customSnpDirController.dispose();
    _toolsDirController.dispose();
    _mipgenExecutableController.dispose();
    _exonExtractScriptController.dispose();
    _ucscTrackGeneratorController.dispose();
    _bigGenePredToGenePredExecutable.dispose();
    _binCreationScript.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPasswordController.dispose();
    _smtpFromController.dispose();
    _mailActiveNotifier.dispose();
    _startTLSNotifier.dispose();
    _loginRequiredNotifier.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings =
      await client.settings.getSettings(_passwordController.text);
      setState(() {
        _errorMessage = null;
        this.settings = settings;
        _baseDirController.text = settings.baseDir;
        _projectDirController.text = settings.projectDir;
        _genomeDirController.text = settings.genomeDir;
        _customSnpDirController.text = settings.customSnpDir;
        _toolsDirController.text = settings.toolsDir;
        _mipgenExecutableController.text = settings.mipgenExecutable;
        _exonExtractScriptController.text = settings.exonExtractScript;
        _ucscTrackGeneratorController.text = settings.ucscTrackGenerator;
        _bigGenePredToGenePredExecutable.text = settings.bigGenePredToGenePredExecutable;
        _binCreationScript.text = settings.binCreationScript;
        _smtpServerController.text = settings.smtpServer;
        _smtpPortController.text = settings.smtpPort.toString();
        _smtpUserController.text = settings.smtpUser;
        _smtpPasswordController.text = settings.smtpPassword;
        _smtpFromController.text = settings.smtpFrom;
        _mailActiveNotifier.value = settings.mailActive;
        _startTLSNotifier.value = settings.startTLS;
        _loginRequiredNotifier.value = settings.loginRequired;
        _newPasswordController.text = settings.settingsPassword;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  Future<void> updateSettings() async {
    try {
      var settings = Settings(
        id: this.settings!.id,
        baseDir: _baseDirController.text,
        projectDir: _projectDirController.text,
        genomeDir: _genomeDirController.text,
        customSnpDir: _customSnpDirController.text,
        toolsDir: _toolsDirController.text,
        mipgenExecutable: _mipgenExecutableController.text,
        exonExtractScript: _exonExtractScriptController.text,
        ucscTrackGenerator: _ucscTrackGeneratorController.text,
        bigGenePredToGenePredExecutable: _bigGenePredToGenePredExecutable.text,
        binCreationScript: _binCreationScript.text,
        mailActive: _mailActiveNotifier.value,
        smtpServer: _smtpServerController.text,
        smtpPort: int.parse(_smtpPortController.text),
        smtpUser: _smtpUserController.text,
        smtpPassword: _smtpPasswordController.text,
        smtpFrom: _smtpFromController.text,
        startTLS: _startTLSNotifier.value,
        loginRequired: _loginRequiredNotifier.value,
        settingsPassword: _newPasswordController.text,
      );

      await client.settings.updateSettings(settings);
      setState(() {
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 30),
          if (_errorMessage != null)
            Container(
              color: Colors.red[300],
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(_errorMessage!),
                ],
              ),
            ),
          SizedBox(height: 20),
          if (settings == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: 'Password'),
                    onSubmitted: (_) => _loadSettings(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                    onPressed: _loadSettings, child: Text('Load settings')),
              ],
            ),
          ] else ...[
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  TextField(
                    controller: _baseDirController,
                    decoration: InputDecoration(labelText: 'Base directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _projectDirController,
                    decoration: InputDecoration(labelText: 'Project directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _genomeDirController,
                    decoration: InputDecoration(labelText: 'Genome directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _customSnpDirController,
                    decoration:
                    InputDecoration(labelText: 'Custom SNP directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _toolsDirController,
                    decoration: InputDecoration(labelText: 'Tools directory'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _mipgenExecutableController,
                    decoration: InputDecoration(labelText: 'MIPGEN executable'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _exonExtractScriptController,
                    decoration: InputDecoration(labelText: 'Exon extract script'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _ucscTrackGeneratorController,
                    decoration:
                    InputDecoration(labelText: 'UCSC track generator'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _bigGenePredToGenePredExecutable,
                    decoration:
                    InputDecoration(labelText: 'BigGenePred to GenePred executable'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _binCreationScript,
                    decoration: InputDecoration(labelText: 'Bin creation script'),
                    keyboardType: TextInputType.text,
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _mailActiveNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged: (value) {
                              setState(() {
                                _mailActiveNotifier.value = value!;
                              });
                            },
                          );
                        },
                      ),
                      Text('Mail active'),
                    ],
                  ),
                  if (_mailActiveNotifier.value) ...[
                    TextField(
                      controller: _smtpServerController,
                      decoration: InputDecoration(labelText: 'SMTP server'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpPortController,
                      decoration: InputDecoration(labelText: 'SMTP port'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _smtpUserController,
                      decoration: InputDecoration(labelText: 'SMTP user'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpPasswordController,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(labelText: 'SMTP password'),
                      keyboardType: TextInputType.text,
                    ),
                    TextField(
                      controller: _smtpFromController,
                      decoration: InputDecoration(labelText: 'SMTP from'),
                      keyboardType: TextInputType.text,
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _startTLSNotifier,
                          builder: (context, value, child) {
                            return Checkbox(
                              value: value,
                              onChanged: (value) {
                                _startTLSNotifier.value = value!;
                              },
                            );
                          },
                        ),
                        Text('Start TLS'),
                      ],
                    ),
                  ],
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _loginRequiredNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged: (value) {
                              _loginRequiredNotifier.value = value!;
                            },
                          );
                        },
                      ),
                      Text('Login required'),
                    ],
                  ),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: 'New password'),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: updateSettings,
                child: Text('Update settings'),
              ),
            ),
            SizedBox(height: 50),
          ],
        ],
      ),
    );
  }
}