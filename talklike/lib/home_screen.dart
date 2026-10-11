import 'package:flutter/material.dart';
import 'data.dart';
import 'flags.dart';
import 'theme.dart';
import 'file_screen.dart';
import 'profile_screen.dart';
import 'speak_screen.dart';
import 'text_screen.dart';

class HomeScreen extends StatefulWidget {
  final Profile profile;
  final Future<void> Function() onReset;
  const HomeScreen({super.key, required this.profile, required this.onReset});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Quote> _quote;
  Profile get p => widget.profile;

  @override
  void initState() {
    super.initState();
    _quote = Api.quote(p.defaultLang);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Lang> get _ordered => [
        ...langs.where((l) => l.code == p.native),
        ...langs.where((l) => l.code != p.native),
      ];

  Future<void> _pick(String code) async {
    setState(() {
      p.defaultLang = code;
      _quote = Api.quote(code);
    });
    await p.save();
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: app name left, profile right (like YouTube)
              Row(
                children: [
                  const Icon(Icons.translate, color: kAccent, size: 26),
                  const SizedBox(width: 8),
                  const Text('TalkLike',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _open(
                        ProfileScreen(profile: p, onReset: widget.onReset)),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: kSurface,
                      child: Text(p.name[0].toUpperCase()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('$_greeting,',
                  style: const TextStyle(color: kMuted, fontSize: 16)),
              const SizedBox(height: 2),
              Text(p.name,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),

              // Language circles (flags)
              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [for (final l in _ordered) _langCircle(l)],
                ),
              ),
              const SizedBox(height: 24),

              // Quote of the day
              _quoteCard(),
              const SizedBox(height: 32),

              const Text('What do you want to translate?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _action(Icons.insert_drive_file_outlined, 'File', 'PDF, TXT',
                      () => _open(FileScreen(profile: p))),
                  const SizedBox(width: 12),
                  _action(Icons.mic_none, 'Speak', 'Say it',
                      () => _open(SpeakScreen(profile: p))),
                  const SizedBox(width: 12),
                  _action(Icons.keyboard_outlined, 'Text', 'Type it',
                      () => _open(TextScreen(profile: p))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langCircle(Lang l) {
    final selected = l.code == p.defaultLang;
    return GestureDetector(
      onTap: () => _pick(l.code),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? kAccent : Colors.transparent, width: 2),
              ),
              child: Flag(l.code, size: 50, round: true),
            ),
            const SizedBox(height: 6),
            Text(l.name,
                style: TextStyle(
                    fontSize: 12, color: selected ? Colors.white : kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _quoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quote of the day · ${langName(p.defaultLang)}',
              style: const TextStyle(color: kMuted, fontSize: 12)),
          const SizedBox(height: 12),
          FutureBuilder<Quote>(
            future: _quote,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snap.hasError) {
                return const Text("Couldn't load today's quote.",
                    style: TextStyle(color: kMuted));
              }
              final q = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.text,
                      style: const TextStyle(fontSize: 18, height: 1.4)),
                  const SizedBox(height: 8),
                  Text('— ${q.author}', style: const TextStyle(color: kMuted)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, String sub, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kAccent, size: 28),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: kMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
