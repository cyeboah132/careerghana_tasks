import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'config.dart';
import 'translator.dart';

const _maxChars = 2000;
const _maxFileBase64 = 7 * 1024 * 1024; // about a 5 MB file

Response _json(Object body, {int status = 200}) => Response(status,
    body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

// Lets the Flutter web app call this server.
Middleware _cors() => (inner) => (req) async {
      const h = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };
      if (req.method == 'OPTIONS') return Response.ok('', headers: h);
      return (await inner(req)).change(headers: h);
    };

Future<void> main() async {
  if (geminiApiKey.startsWith('PASTE_')) {
    stderr.writeln('Open lib/config.dart and paste your Gemini API key first.');
    exit(1);
  }

  final t = Translator();

  final router = Router()
    ..get('/health', (Request r) => _json({'ok': true}))
    ..post('/translate', (Request r) async {
      final b = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
      final text = '${b['text'] ?? ''}'.trim();
      final target = '${b['target'] ?? ''}';
      if (text.isEmpty || target.isEmpty) {
        return _json({'error': 'text and target are required'}, status: 400);
      }
      if (text.length > _maxChars) {
        return _json({'error': 'Text too long (max $_maxChars characters)'},
            status: 413);
      }
      try {
        final out = await t.translate(text, '${b['source'] ?? 'auto'}', target);
        return _json({'translation': out});
      } on ArgumentError catch (e) {
        return _json({'error': '${e.message}'}, status: 400);
      }
    })
    ..post('/translate-file', (Request r) async {
      final b = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
      final name = '${b['name'] ?? ''}'.toLowerCase();
      final data = '${b['data'] ?? ''}';
      final target = '${b['target'] ?? ''}';
      if (data.isEmpty || target.isEmpty) {
        return _json({'error': 'file and target are required'}, status: 400);
      }
      if (data.length > _maxFileBase64) {
        return _json({'error': 'File too big (max 5 MB)'}, status: 413);
      }
      final isPdf = name.endsWith('.pdf');
      if (!isPdf && !name.endsWith('.txt')) {
        return _json({'error': 'Only PDF and TXT files are supported'},
            status: 415);
      }
      try {
        final out = await t.translateFile(
          isPdf: isPdf,
          dataBase64: data,
          source: '${b['source'] ?? 'auto'}',
          target: target,
        );
        return _json({'translation': out});
      } on ArgumentError catch (e) {
        return _json({'error': '${e.message}'}, status: 400);
      }
    })
    ..get('/quote', (Request r) async {
      try {
        return _json(await t.quote(r.url.queryParameters['lang'] ?? 'en'));
      } on ArgumentError catch (e) {
        return _json({'error': '${e.message}'}, status: 400);
      }
    });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addMiddleware((inner) => (req) async {
            try {
              return await inner(req);
            } catch (e) {
              stderr.writeln('Error: $e');
              return _json({'error': 'Something went wrong. Try again.'},
                  status: 500);
            }
          })
      .addHandler(router.call);

  await io.serve(handler, InternetAddress.anyIPv4, serverPort);
  print('TalkLike server running on http://localhost:$serverPort');
}
