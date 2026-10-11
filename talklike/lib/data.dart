import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Where your server runs. Change this when you deploy it.
/// Android emulator: use http://10.0.2.2:8080
/// Real phone: use your computer's IP, e.g. http://192.168.1.5:8080
const apiBase = 'http://localhost:8080';

class Lang {
  final String code;
  final String name;
  const Lang(this.code, this.name);
}

const langs = <Lang>[
  Lang('en', 'English'),
  Lang('fr', 'French'),
  Lang('es', 'Spanish'),
  Lang('zh', 'Chinese'),
  Lang('tw', 'Twi'),
];

String langName(String code) =>
    langs.firstWhere((l) => l.code == code, orElse: () => langs.first).name;

// ---------- Profile (stored on the device, no login) ----------
class Profile {
  String name;
  int age;
  String country;
  String native; // native language code
  String? other; // language they love / want to learn
  String gender;
  String defaultLang;

  Profile({
    required this.name,
    required this.age,
    required this.country,
    required this.native,
    this.other,
    required this.gender,
    String? defaultLang,
  }) : defaultLang = defaultLang ?? native;

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'country': country,
        'native': native,
        'other': other,
        'gender': gender,
        'defaultLang': defaultLang,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'],
        age: j['age'],
        country: j['country'],
        native: j['native'],
        other: j['other'],
        gender: j['gender'],
        defaultLang: j['defaultLang'],
      );

  static const _key = 'profile';

  static Future<Profile?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    return raw == null ? null : Profile.fromJson(jsonDecode(raw));
  }

  Future<void> save() async => (await SharedPreferences.getInstance())
      .setString(_key, jsonEncode(toJson()));

  static Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

// ---------- API ----------
class Quote {
  final String text;
  final String author;
  Quote(this.text, this.author);
}

class Api {
  static Future<String> translate(
      String text, String source, String target) async {
    final res = await http
        .post(
          Uri.parse('$apiBase/translate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'source': source, 'target': target}),
        )
        .timeout(const Duration(seconds: 40));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Translation failed');
    }
    return data['translation'];
  }

  static Future<String> translateFile({
    required String name,
    required Uint8List bytes,
    required String source,
    required String target,
  }) async {
    final res = await http
        .post(
          Uri.parse('$apiBase/translate-file'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'data': base64Encode(bytes),
            'source': source,
            'target': target,
          }),
        )
        .timeout(const Duration(seconds: 120));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Translation failed');
    }
    return data['translation'];
  }

  static Future<Quote> quote(String lang) async {
    final res = await http
        .get(Uri.parse('$apiBase/quote?lang=$lang'))
        .timeout(const Duration(seconds: 40));
    if (res.statusCode != 200) throw Exception('Quote failed');
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return Quote(data['quote'], data['author']);
  }
}
