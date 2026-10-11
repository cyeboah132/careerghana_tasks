import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';

/// Country flag drawn in code (flag emoji don't show on Windows).
/// en = UK, fr = France, es = Spain, zh = China, tw = Ghana.
class Flag extends StatelessWidget {
  final String code;
  final double size; // height
  final bool round;
  const Flag(this.code, {super.key, this.size = 20, this.round = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(round ? size / 2 : 3),
      child: SizedBox(
        width: round ? size : size * 1.5,
        height: size,
        child: CustomPaint(painter: _FlagPainter(code)),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String code;
  _FlagPainter(this.code);

  static const _white = Colors.white;
  static const _ukBlue = Color(0xFF00247D);
  static const _ukRed = Color(0xFFCF142B);
  static const _frBlue = Color(0xFF0055A4);
  static const _frRed = Color(0xFFEF4135);
  static const _esRed = Color(0xFFC60B1E);
  static const _esYellow = Color(0xFFFFC400);
  static const _cnRed = Color(0xFFDE2910);
  static const _cnYellow = Color(0xFFFFDE00);
  static const _ghRed = Color(0xFFCE1126);
  static const _ghGold = Color(0xFFFCD116);
  static const _ghGreen = Color(0xFF006B3F);

  Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.382;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt =
          Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Paint();
    void box(Color col, double x, double y, double bw, double bh) {
      p.color = col;
      canvas.drawRect(Rect.fromLTWH(x, y, bw, bh), p);
    }

    canvas.clipRect(Offset.zero & s);

    switch (code) {
      case 'fr':
        box(_frBlue, 0, 0, w / 3, h);
        box(_white, w / 3, 0, w / 3, h);
        box(_frRed, 2 * w / 3, 0, w / 3 + 1, h);
        break;
      case 'es':
        box(_esRed, 0, 0, w, h);
        box(_esYellow, 0, h * 0.25, w, h * 0.5);
        break;
      case 'zh':
        box(_cnRed, 0, 0, w, h);
        p.color = _cnYellow;
        canvas.drawPath(_star(Offset(w * 0.25, h * 0.32), h * 0.22), p);
        for (final o in [
          Offset(w * 0.5, h * 0.12),
          Offset(w * 0.58, h * 0.25),
          Offset(w * 0.58, h * 0.42),
          Offset(w * 0.5, h * 0.55),
        ]) {
          canvas.drawPath(_star(o, h * 0.07), p);
        }
        break;
      case 'tw': // Ghana
        box(_ghRed, 0, 0, w, h / 3);
        box(_ghGold, 0, h / 3, w, h / 3);
        box(_ghGreen, 0, 2 * h / 3, w, h / 3 + 1);
        p.color = Colors.black;
        canvas.drawPath(_star(Offset(w / 2, h / 2), h * 0.17), p);
        break;
      default: // en = UK
        box(_ukBlue, 0, 0, w, h);
        final d = Paint()
          ..style = PaintingStyle.stroke
          ..color = _white
          ..strokeWidth = h * 0.2;
        canvas.drawLine(Offset.zero, Offset(w, h), d);
        canvas.drawLine(Offset(w, 0), Offset(0, h), d);
        d
          ..color = _ukRed
          ..strokeWidth = h * 0.07;
        canvas.drawLine(Offset.zero, Offset(w, h), d);
        canvas.drawLine(Offset(w, 0), Offset(0, h), d);
        box(_white, 0, h / 2 - h * 0.17, w, h * 0.34);
        box(_white, w / 2 - h * 0.17, 0, h * 0.34, h);
        box(_ukRed, 0, h / 2 - h * 0.1, w, h * 0.2);
        box(_ukRed, w / 2 - h * 0.1, 0, h * 0.2, h);
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.code != code;
}

/// Language dropdown with flags. Used by Text, File and Speak screens.
class LangPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool allowAuto;
  final Set<String> exclude;
  const LangPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAuto = false,
    this.exclude = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: kSurface,
        items: [
          if (allowAuto)
            const DropdownMenuItem(
              value: 'auto',
              child: Row(children: [
                Icon(Icons.language, size: 18, color: kMuted),
                SizedBox(width: 10),
                Text('Detect'),
              ]),
            ),
          for (final l in langs.where((l) => !exclude.contains(l.code)))
            DropdownMenuItem(
              value: l.code,
              child: Row(children: [
                Flag(l.code, size: 16),
                const SizedBox(width: 10),
                Text(l.name),
              ]),
            ),
        ],
        onChanged: (v) => onChanged(v!),
      ),
    );
  }
}
