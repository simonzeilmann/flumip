import 'package:flumip_client/flumip_client.dart';
import 'package:flumip_flutter/format.dart';
import 'package:flumip_flutter/snp/file_picker.dart';
import 'package:flumip_flutter/snp/picked_file.dart';
import 'package:flumip_flutter/snp/snp_validation.dart';
import 'package:flutter/material.dart';
import 'package:flumip_flutter/ui/theme.dart';
import 'package:flumip_flutter/ui/dialog_body.dart';

/// How the bytes are going to arrive.
enum AddSnpMode {
  /// The server fetches them from an address the user pasted.
  url,

  /// The browser sends them. Not built yet — see [AddCustomSnpDialog].
  upload,
}

/// A described-but-not-yet-created custom SNP set.
class CustomSnpDraft {
  const CustomSnpDraft({
    required this.mode,
    required this.name,
    required this.description,
    required this.genomeId,
    required this.shared,
    this.vcfUrl = '',
    this.tbiUrl = '',
    this.vcfFile,
    this.tbiFile,
  });

  final AddSnpMode mode;
  final String name;
  final String description;
  final int genomeId;

  /// True means visible to everyone. Sent as `private: !shared`.
  final bool shared;

  /// Set for [AddSnpMode.url]. Empty `tbiUrl` means the server builds the index.
  final String vcfUrl;
  final String tbiUrl;

  /// Set for [AddSnpMode.upload]. A null [tbiFile] means the server builds it.
  final PickedFile? vcfFile;
  final PickedFile? tbiFile;
}

/// Describes a custom SNP set to add.
///
/// Parameter-in, result-out: it makes no client calls of its own, so the caller
/// owns the network and this stays testable. The file picker is injected for the
/// same reason.
///
/// ⚠️ When [uploadAvailable] is false the upload option is shown **disabled with a
/// reason** rather than hidden, because that state is reachable in normal
/// development — a `flutter run` serves the app on a different origin from the web
/// server, so the cookie the upload needs never travels. Somebody who expects to
/// upload a file should be told why they cannot, not left to conclude the feature
/// is missing.
class AddCustomSnpDialog extends StatefulWidget {
  const AddCustomSnpDialog({
    super.key,
    required this.genome,
    this.uploadAvailable = false,
    this.pickFile = pickFileFromBrowser,
  });

  /// Opens a file dialog. Injected so this widget can be pumped in a test.
  final Future<PickedFile?> Function({required String accept}) pickFile;

  /// The genome the SNP set is called against.
  ///
  /// Fixed, not chosen, because the dialog is opened from a genome that is
  /// already selected. Shown read-only rather than as a dead dropdown so it is
  /// obvious what it applies to.
  final Genome genome;

  final bool uploadAvailable;

  @override
  State<AddCustomSnpDialog> createState() => _AddCustomSnpDialogState();
}

class _AddCustomSnpDialogState extends State<AddCustomSnpDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _vcfUrlController = TextEditingController();
  final _tbiUrlController = TextEditingController();
  final _tbiFocus = FocusNode();

  AddSnpMode _mode = AddSnpMode.url;
  bool _shared = false;
  PickedFile? _vcfFile;
  PickedFile? _tbiFile;

  /// Whether the user has edited the index address themselves.
  ///
  /// Once they have, the convention-based suggestion stops overwriting it.
  bool _tbiTouched = false;

  @override
  void initState() {
    super.initState();
    _vcfUrlController.addListener(_suggestTbi);
    _tbiUrlController.addListener(_noteTbiEdited);
  }

  @override
  void dispose() {
    _vcfUrlController.removeListener(_suggestTbi);
    _tbiUrlController.removeListener(_noteTbiEdited);
    _nameController.dispose();
    _descriptionController.dispose();
    _vcfUrlController.dispose();
    _tbiUrlController.dispose();
    _tbiFocus.dispose();
    super.dispose();
  }

  void _noteTbiEdited() {
    if (_tbiFocus.hasFocus) _tbiTouched = true;
  }

  /// Fills in the index address from the VCF one, by convention.
  void _suggestTbi() {
    if (_tbiTouched) return;
    final suggestion = suggestTbiUrl(_vcfUrlController.text);
    if (suggestion != null && _tbiUrlController.text != suggestion) {
      _tbiUrlController.text = suggestion;
    }
    setState(() {});
  }

  String? get _nameError =>
      _nameController.text.trim().isEmpty ? 'Give it a name.' : null;

  String? get _vcfUrlError => validateVcfUrl(_vcfUrlController.text);
  String? get _tbiUrlError => validateTbiUrl(_tbiUrlController.text);

  String? get _vcfFileError =>
      _vcfFile == null ? null : validateVcfName(_vcfFile!.name);
  String? get _tbiFileError =>
      _tbiFile == null ? null : validateTbiName(_tbiFile!.name);

  bool get _canAdd {
    if (_nameError != null) return false;
    return switch (_mode) {
      AddSnpMode.url => _vcfUrlError == null && _tbiUrlError == null,
      AddSnpMode.upload =>
        _vcfFile != null && _vcfFileError == null && _tbiFileError == null,
    };
  }

  Future<void> _chooseVcf() async {
    final file = await widget.pickFile(accept: vcfAccept);
    if (file != null) setState(() => _vcfFile = file);
  }

  Future<void> _chooseTbi() async {
    final file = await widget.pickFile(accept: tbiAccept);
    if (file != null) setState(() => _tbiFile = file);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a custom SNP set'),
      content: DialogBody(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _genomeRow(),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: _nameController.text.isEmpty ? null : _nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What this SNP set is, and where it came from',
                ),
              ),
              const SizedBox(height: 20),
              _modeSelector(),
              const SizedBox(height: 16),
              if (_mode == AddSnpMode.url)
                ..._urlFields()
              else
                ..._uploadFields(),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _shared,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _shared = v),
                title: const Text('Share with everyone on this server'),
                // Framed as sharing rather than privacy, so that the default —
                // off — reads as the safe choice rather than a restriction.
                subtitle: Text(
                  _shared
                      ? 'Everyone can see and use this SNP set.'
                      : 'Only you can see and use it. You can share it later.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canAdd
              ? () => Navigator.of(context).pop(
                  CustomSnpDraft(
                    mode: _mode,
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                    genomeId: widget.genome.id!,
                    shared: _shared,
                    vcfUrl: _mode == AddSnpMode.url
                        ? _vcfUrlController.text.trim()
                        : '',
                    tbiUrl: _mode == AddSnpMode.url
                        ? _tbiUrlController.text.trim()
                        : '',
                    vcfFile: _mode == AddSnpMode.upload ? _vcfFile : null,
                    tbiFile: _mode == AddSnpMode.upload ? _tbiFile : null,
                  ),
                )
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _genomeRow() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: context.colours.secondaryContainer,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(Icons.dns, size: 18, color: context.colours.onSecondaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'For ${widget.genome.category} / ${widget.genome.name}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  Widget _modeSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SegmentedButton<AddSnpMode>(
        segments: [
          const ButtonSegment(
            value: AddSnpMode.url,
            icon: Icon(Icons.link),
            label: Text('Fetch from a URL'),
          ),
          ButtonSegment(
            value: AddSnpMode.upload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload files'),
            enabled: widget.uploadAvailable,
            tooltip: widget.uploadAvailable
                ? null
                : 'Not available in this configuration — the app and the '
                      'server are on different origins, so the upload cannot '
                      'carry your session. Import from a URL instead.',
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() => _mode = s.first),
      ),
      if (!widget.uploadAvailable)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Uploading is unavailable here: the app is being served from a '
            'different origin than the server, so the browser will not send '
            'your session with the upload. This is the same reason sign-in '
            'does not work under `flutter run`.',
            style: TextStyle(
              color: context.colours.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );

  List<Widget> _urlFields() => [
    TextField(
      controller: _vcfUrlController,
      keyboardType: TextInputType.url,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Address of the .vcf.gz file',
        hintText: 'https://ftp.ncbi.nlm.nih.gov/…/00-common_all.vcf.gz',
        errorText: _vcfUrlController.text.isEmpty ? null : _vcfUrlError,
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _tbiUrlController,
      focusNode: _tbiFocus,
      keyboardType: TextInputType.url,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Address of the .vcf.gz.tbi index (optional)',
        helperText:
            'Leave this out and the server will build the index '
            'itself with tabix.',
        errorText: _tbiUrlError,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      'The server downloads the files itself, so this works for files far '
      'larger than a browser upload. It may take a while; the SNP set '
      'shows its progress in the list.',
      style: TextStyle(color: context.colours.onSurfaceVariant, fontSize: 12),
    ),
  ];

  List<Widget> _uploadFields() => [
    _filePicker(
      label: 'Choose the .vcf.gz file',
      file: _vcfFile,
      error: _vcfFileError,
      onChoose: _chooseVcf,
      onClear: () => setState(() => _vcfFile = null),
    ),
    const SizedBox(height: 12),
    _filePicker(
      label: 'Choose the .vcf.gz.tbi index (optional)',
      file: _tbiFile,
      error: _tbiFileError,
      onChoose: _chooseTbi,
      onClear: () => setState(() => _tbiFile = null),
    ),
    const SizedBox(height: 8),
    Text(
      _tbiFile == null
          ? 'Without an index the server will build one with tabix after '
                'the upload finishes.'
          : 'Both files will be sent, one after the other.',
      style: TextStyle(color: context.colours.onSurfaceVariant, fontSize: 12),
    ),
    if (_vcfFile != null && _vcfFile!.size < 1000000)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'That file looks small for a VCF — did you pick the index by '
          'mistake?',
          style: TextStyle(color: context.status.warning, fontSize: 12),
        ),
      ),
  ];

  Widget _filePicker({
    required String label,
    required PickedFile? file,
    required String? error,
    required VoidCallback onChoose,
    required VoidCallback onClear,
  }) {
    if (file == null) {
      return OutlinedButton.icon(
        onPressed: onChoose,
        icon: const Icon(Icons.attach_file, size: 18),
        label: Text(label),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 18,
              color: context.colours.primary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(file.name)),
            Text(
              formatBytes(file.size),
              style: TextStyle(color: context.colours.onSurfaceVariant),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Choose a different file',
              onPressed: onClear,
            ),
          ],
        ),
        if (error != null)
          Text(
            error,
            style: TextStyle(color: context.colours.error, fontSize: 12),
          ),
      ],
    );
  }
}
