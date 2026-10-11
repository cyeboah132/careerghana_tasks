import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A day counts when the app stays open for 5 minutes in a row.
/// Sending the app to the background resets the 5-minute timer.
class Streak extends ChangeNotifier with WidgetsBindingObserver {
  Streak._();
  static final Streak instance = Streak._();

  static const goalSeconds = 300;
  static const _key = 'streak_days';

  final Set<String> days = {};
  int sessionSeconds = 0;
  Timer? _timer;

  static String fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get doneToday => days.contains(fmt(DateTime.now()));

  /// Consecutive days ending today (or yesterday if today isn't done yet).
  int get current {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!days.contains(fmt(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (days.contains(fmt(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    days.addAll(prefs.getStringList(_key) ?? []);
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _timer?.cancel();
    sessionSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      sessionSeconds++;
      if (sessionSeconds >= goalSeconds && !doneToday) {
        days.add(fmt(DateTime.now()));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_key, days.toList());
      }
      notifyListeners();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _timer?.cancel();
      sessionSeconds = 0;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }
}
