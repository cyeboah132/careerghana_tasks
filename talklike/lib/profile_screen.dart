import 'package:flutter/material.dart';
import 'data.dart';
import 'flags.dart';
import 'streak.dart';
import 'theme.dart';

class ProfileScreen extends StatelessWidget {
  final Profile profile;
  final Future<void> Function() onReset;
  const ProfileScreen(
      {super.key, required this.profile, required this.onReset});

  static const _border = Color(0xFF2A2A2A);
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  Widget _langValue(String code) => Row(children: [
        Flag(code, size: 16),
        const SizedBox(width: 8),
        Text(langName(code), style: const TextStyle(fontSize: 16)),
      ]);

  Widget _tile(String label, Widget value) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            value,
          ],
        ),
      );

  Widget _text(String t) => Text(t, style: const TextStyle(fontSize: 16));

  String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _calendar(Set<String> days) {
    final now = DateTime.now();
    final offset = DateTime(now.year, now.month, 1).weekday - 1; // Monday first
    final total = DateTime(now.year, now.month + 1, 0).day;
    final cells = <Widget>[
      for (var i = 0; i < offset; i++) const SizedBox(),
      for (var d = 1; d <= total; d++)
        Builder(builder: (_) {
          final done =
              days.contains(Streak.fmt(DateTime(now.year, now.month, d)));
          final isToday = d == now.day;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? kAccent : null,
              border: (isToday && !done) ? Border.all(color: kMuted) : null,
            ),
            child: Text('$d',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                  color: done
                      ? Colors.black
                      : (d > now.day ? const Color(0xFF555555) : Colors.white),
                )),
          );
        }),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_months[now.month - 1]} ${now.year}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                    child: Text(d,
                        style: const TextStyle(color: kMuted, fontSize: 12))),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: cells,
        ),
      ],
    );
  }

  Widget _streakCard() {
    return AnimatedBuilder(
      animation: Streak.instance,
      builder: (context, _) {
        final s = Streak.instance;
        final secs = s.sessionSeconds.clamp(0, Streak.goalSeconds);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${s.current}',
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          height: 1)),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('day streak',
                        style: TextStyle(color: kMuted, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (s.doneToday)
                const Row(children: [
                  Icon(Icons.check_circle, color: kAccent, size: 18),
                  SizedBox(width: 8),
                  Text("Today is counted"),
                ])
              else ...[
                const Text('Stay in the app for 5 minutes to count today.',
                    style: TextStyle(color: kMuted, fontSize: 13)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: secs / Streak.goalSeconds,
                  minHeight: 4,
                  color: kAccent,
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
                const SizedBox(height: 6),
                Text('${_mmss(secs)} / 5:00',
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              _calendar(s.days),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: kSurface,
                  child: Text(profile.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${profile.age} years old',
                          style: const TextStyle(color: kMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _streakCard(),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2,
              children: [
                _tile('Language', _langValue(profile.native)),
                _tile(
                    'Loves',
                    profile.other == null
                        ? _text('—')
                        : _langValue(profile.other!)),
                _tile('Country', _text(profile.country)),
                _tile('Gender', _text(profile.gender)),
              ],
            ),
            const SizedBox(height: 28),
            // Donate: visible only, no function yet.
            ElevatedButton(onPressed: () {}, child: const Text('Donate')),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onReset();
              },
              style: TextButton.styleFrom(foregroundColor: kMuted),
              child: const Text('Reset profile'),
            ),
          ],
        ),
      ),
    );
  }
}
