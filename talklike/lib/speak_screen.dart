import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'data.dart';
import 'flags.dart';
import 'theme.dart';

class SpeakScreen extends StatefulWidget {
  final Profile profile;
  const SpeakScreen({super.key, required this.profile});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  final _speech = stt.SpeechToText();
  List<stt.LocaleName> _locales = [];
  bool _ready = false;
  bool _listening = false;
  bool _loading = false;
  late String _from; // language you speak (Twi not supported by speech engines)
  late String _to;
  String _heard = '';
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _from = widget.profile.native == 'tw' ? 'en' : widget.profile.native;
    final d = widget.profile.defaultLang;
    _to = d != _from ? d : langs.firstWhere((l) => l.code != _from).code;
    _init();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final ok = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _listening = false;
          _error = 'Microphone problem: ${e.errorMsg}';
        });
      },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && _listening) _finish();
      },
    );
    if (ok) _locales = await _speech.locales();
    if (!mounted) return;
    setState(() => _ready = ok);
  }

  String? _localeFor(String code) {
    for (final l in _locales) {
      final id = l.localeId.replaceAll('-', '_').toLowerCase();
      if (id == code || id.startsWith('${code}_')) return l.localeId;
    }
    return null; // fall back to the device default
  }

  Future<void> _toggle() async {
    if (!_ready) {
      setState(() => _error =
          "Speech recognition isn't available. Use Chrome or Edge, and allow the microphone.");
      return;
    }
    if (_listening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      _finish();
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _result = null;
      _error = null;
    });
    await _speech.listen(
      localeId: _localeFor(_from),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      onResult: (r) {
        if (mounted) setState(() => _heard = r.recognizedWords);
      },
    );
  }

  void _finish() {
    if (!_listening || !mounted) return;
    setState(() => _listening = false);
    if (_heard.trim().isNotEmpty) _translate();
  }

  Future<void> _translate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final out = await Api.translate(_heard, _from, _to);
      if (!mounted) return;
      setState(() => _result = out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _card(String label, String text, {bool copy = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 8),
          SelectableText(text,
              style: const TextStyle(fontSize: 18, height: 1.4)),
          if (copy) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copied')));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
              style: TextButton.styleFrom(foregroundColor: kAccent),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speak')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: LangPicker(
                    value: _from,
                    exclude: const {'tw'},
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
                    onChanged: (v) {
                      setState(() => _to = v);
                      if (_heard.trim().isNotEmpty && !_listening) _translate();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                "Phones can't recognise spoken Twi yet, but you can translate into Twi.",
                style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? kAccent : kSurface,
                    border: Border.all(color: kAccent, width: 2),
                  ),
                  child: Icon(_listening ? Icons.stop : Icons.mic,
                      size: 40, color: _listening ? Colors.black : kAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _listening ? 'Listening… tap to stop' : 'Tap to speak',
                style: const TextStyle(color: kMuted),
              ),
            ),
            if (_heard.isNotEmpty) _card('You said', _heard),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                    child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            if (_result != null) _card('Translation', _result!, copy: true),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}
