import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'languages.dart';

/// Translation + quote logic. Everything runs through Gemini.
class Translator {
  // ---------- Gemini ----------
  Future<String> _ai(
    String system,
    String user, {
    bool json = false,
    double temperature = 0.2,
    List<Map<String, dynamic>> extra = const [], // e.g. a PDF
    int seconds = 30,
  }) async {
    final res = await http
        .post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent'),
          headers: {
            'x-goog-api-key': geminiApiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': system}
              ]
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  ...extra,
                  {'text': user}
                ]
              }
            ],
            'generationConfig': {
              'temperature': temperature,
              if (json) 'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(Duration(seconds: seconds));

    if (res.statusCode != 200) {
      throw Exception('Gemini ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final parts = data['candidates'][0]['content']['parts'] as List;
    return parts.map((p) => p['text'] ?? '').join().trim();
  }

  // ---------- Translate text ----------
  /// [source] may be 'auto'.
  Future<String> translate(String text, String source, String target) async {
    final tgt = langByCode(target);
    if (tgt == null) throw ArgumentError('Unsupported target language');
    final src = langByCode(source); // null means auto-detect
    if (src != null && src.code == tgt.code) return text;

    final from = src == null ? 'the detected source language' : src.name;
    return _ai(
      'You are a translator. Translate from $from to ${tgt.name}. '
      'Keep meaning and tone. Output ONLY the translation.',
      text,
    );
  }

  // ---------- Translate a PDF or TXT file ----------
  Future<String> translateFile({
    required bool isPdf,
    required String dataBase64,
    required String source,
    required String target,
  }) async {
    final tgt = langByCode(target);
    if (tgt == null) throw ArgumentError('Unsupported target language');
    final src = langByCode(source);
    final from = src == null ? 'the detected source language' : src.name;
    final system =
        'You are a translator. Translate the document from $from to ${tgt.name}. '
        'Keep the structure (headings, paragraphs, lists). Output ONLY the translation.';

    if (isPdf) {
      return _ai(
        system,
        'Translate this document.',
        extra: [
          {
            'inlineData': {'mimeType': 'application/pdf', 'data': dataBase64}
          }
        ],
        seconds: 100,
      );
    }
    final text = utf8.decode(base64Decode(dataBase64), allowMalformed: true);
    if (text.trim().isEmpty) throw ArgumentError('The file is empty');
    return _ai(system, text, seconds: 100);
  }

  // ---------- Quote of the day ----------
  String? _day;
  Map<String, String>? _base;
  final Map<String, Map<String, String>> _cache = {};

  Future<Map<String, String>> quote(String lang) async {
    if (langByCode(lang) == null) throw ArgumentError('Unsupported language');
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);

    if (_day != today || _base == null) {
      _day = today;
      _cache.clear();
      final raw = await _ai(
        'Give one short, uplifting quote about language, learning or '
            'understanding others. Prefer a real quote with correct '
            'attribution; if unsure, write an original and set author to '
            '"TalkLike". Reply JSON only: {"quote":"...","author":"..."}',
        'Quote for $today',
        json: true,
        temperature: 0.7,
      );
      final j = jsonDecode(raw);
      _base = {'quote': '${j['quote']}', 'author': '${j['author']}'};
    }

    final cached = _cache[lang];
    if (cached != null) return cached;

    final text = lang == 'en'
        ? _base!['quote']!
        : await translate(_base!['quote']!, 'en', lang);
    return _cache[lang] = {'quote': text, 'author': _base!['author']!};
  }
}
