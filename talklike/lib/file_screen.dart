import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'flags.dart';
import 'theme.dart';

class FileScreen extends StatefulWidget {
  final Profile profile;
  const FileScreen({super.key, required this.profile});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  static const _maxBytes = 5 * 1024 * 1024; // 5 MB

  String? _name;
  Uint8List? _bytes;
  String _from = 'auto';
  late String _to;
  String? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _to = widget.profile.defaultLang;
  }

  String _size(int b) => b < 1024 * 1024
      ? '${(b / 1024).round()} KB'
      : '${(b / 1024 / 1024).toStringAsFixed(1)} MB';

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );
    if (res == null) return;
    final f = res.files.single;
    if (f.bytes == null) {
      setState(() => _error = 'Could not read that file.');
      return;
    }
    if (f.size > _maxBytes) {
      setState(() => _error = 'That file is too big. Maximum is 5 MB.');
      return;
    }
    setState(() {
      _name = f.name;
      _bytes = f.bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _translate() async {
    if (_bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final out = await Api.translateFile(
          name: _name!, bytes: _bytes!, source: _from, target: _to);
      if (!mounted) return;
      setState(() => _result = out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _caption(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(color: kMuted, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final hasFile = _name != null;
    return Scaffold(
      appBar: AppBar(title: const Text('File')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GestureDetector(
              onTap: _loading ? null : _pick,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: hasFile ? kAccent : const Color(0xFF2E2E2E)),
                ),
                child: Column(
                  children: [
                    Icon(
                        hasFile
                            ? Icons.description_outlined
                            : Icons.upload_file,
                        size: 34,
                        color: kAccent),
                    const SizedBox(height: 10),
                    Text(_name ?? 'Choose a file',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      hasFile
                          ? '${_size(_bytes!.length)} · tap to change'
                          : 'PDF or TXT · one file · up to 5 MB',
                      style: const TextStyle(color: kMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption('File language'),
                      LangPicker(
                        value: _from,
                        allowAuto: true,
                        onChanged: (v) => setState(() => _from = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption('Translate to'),
                      LangPicker(
                        value: _to,
                        onChanged: (v) => setState(() => _to = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'We detect the language automatically. If it gets it wrong, pick the right one above.',
                style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_loading || !hasFile) ? null : _translate,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Translate'),
            ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const Text('Large files can take up to a minute.',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: kMuted)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(_result!,
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _result!));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied')));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(foregroundColor: kAccent),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
