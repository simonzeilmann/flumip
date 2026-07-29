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
  final TextEditingController _bigGenePredToGenePredExecutable =
      TextEditingController();
  final TextEditingController _binCreationScript = TextEditingController();
  final TextEditingController _smtpServerController = TextEditingController();
  final TextEditingController _smtpPortController = TextEditingController();
  final TextEditingController _smtpUserController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();
  final TextEditingController _smtpFromController = TextEditingController();
  final TextEditingController _testMailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  final ValueNotifier<bool> _mailActiveNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _startTLSNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _loginRequiredNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _demoModeNotifier = ValueNotifier(false);

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
    _testMailController.dispose();
    _mailActiveNotifier.dispose();
    _startTLSNotifier.dispose();
    _loginRequiredNotifier.dispose();
    _demoModeNotifier.dispose();
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
        _bigGenePredToGenePredExecutable.text =
            settings.bigGenePredToGenePredExecutable;
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
        _demoModeNotifier.value = settings.demoMode;
      });
    }
    on ArgumentException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
    catch (e) {
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
        smtpPort: int.tryParse(_smtpPortController.text) ?? 25,
        smtpUser: _smtpUserController.text,
        smtpPassword: _smtpPasswordController.text,
        smtpFrom: _smtpFromController.text,
        startTLS: _startTLSNotifier.value,
        loginRequired: _loginRequiredNotifier.value,
        settingsPassword: _newPasswordController.text,
        demoMode: _demoModeNotifier.value,
      );

      // Authenticated with the password the settings were loaded with; a new
      // password in `settingsPassword` only takes effect after this succeeds.
      await client.settings
          .updateSettings(_passwordController.text, settings);
      setState(() {
        _errorMessage = null;
        // The password may have just been changed; keep the one we authenticate
        // with in sync so subsequent saves / test mails still work.
        _passwordController.text = settings.settingsPassword;
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

  Future<void> sendTestMail() async {
    final to = _testMailController.text.trim();
    if (to.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a recipient address for the test email';
      });
      return;
    }
    try {
      await client.settings.sendTestMail(_passwordController.text, to);
      setState(() {
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test email sent to $to')),
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
        spacing: 30,
        children: [
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
              spacing: 10,
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
                ElevatedButton(
                    onPressed: _loadSettings, child: Text('Load settings')),
              ],
            ),
          ] else ...[
            SizedBox(
              width: 400,
              child: Column(
                spacing: 3,
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
                    decoration:
                        InputDecoration(labelText: 'Exon extract script'),
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
                    decoration: InputDecoration(
                        labelText: 'BigGenePred to GenePred executable'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _binCreationScript,
                    decoration:
                        InputDecoration(labelText: 'Bin creation script'),
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
                    // Validates the SMTP configuration above without having to
                    // run a job. Uses the currently saved settings, so save
                    // first after changing them.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testMailController,
                            decoration: InputDecoration(
                              labelText: 'Send test email to',
                              hintText: 'you@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: sendTestMail,
                          child: Text('Send test email'),
                        ),
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
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: _demoModeNotifier,
                        builder: (context, value, child) {
                          return Checkbox(
                            value: value,
                            onChanged: (value) {
                              setState(() {
                                _demoModeNotifier.value = value!;
                              });
                            },
                          );
                        },
                      ),
                      Text('Demo mode'),
                    ],
                  ),
                ],
              ),
            ),
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
