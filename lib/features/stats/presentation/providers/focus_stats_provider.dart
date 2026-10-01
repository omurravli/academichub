import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef DayStat = ({DateTime date, int sessions});

/// Returns the last [days] days of session history, oldest first.
final focusStatsProvider =
    FutureProvider.family<List<DayStat>, int>((ref, days) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now();
  return List.generate(days, (i) {
    final date = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1 - i));
    return (date: date, sessions: prefs.getInt(_histKey(date)) ?? 0);
  });
});

/// Consecutive-day streak ending today.
final streakProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now();
  int streak = 0;
  for (int i = 0; i < 365; i++) {
    final date = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: i));
    if ((prefs.getInt(_histKey(date)) ?? 0) > 0) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

String _histKey(DateTime dt) =>
    'pomo_history_${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
