import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'flags.dart';
import 'theme.dart';

class TextScreen extends StatefulWidget {
  final Profile profile;
  const TextScreen({super.key, required this.profile});

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final _input = TextEditingController();
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

  Future<void> _translate() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final out = await Api.translate(text, _from, _to);
      if (!mounted) return;
      setState(() => _result = out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: LangPicker(
                    value: _from,
                    allowAuto: true,
                    onChanged: (v) => setState(() => _from = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: kMuted, size: 18),
                ),
                Expanded(
                  child: LangPicker(
                    value: _to,
                    onChanged: (v) => setState(() => _to = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              minLines: 5,
              maxLines: 8,
              maxLength: 2000,
              decoration: const InputDecoration(hintText: 'Type or paste text'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _translate,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Translate'),
            ),
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
                        style: const TextStyle(fontSize: 18, height: 1.4)),
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
