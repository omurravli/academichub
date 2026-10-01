import 'package:studiq/features/planner/domain/entities/planner_item.dart';

/// Generates future occurrences for recurring planner items.
/// Foundation only — expand per RRule RFC 5545 spec as needed.
class RecurrenceService {
  RecurrenceService._();
  static final instance = RecurrenceService._();

  /// Returns the next N occurrences of [item] starting from [after].
  List<DateTime> nextOccurrences(
    PlannerItem item, {
    required DateTime after,
    int count = 10,
  }) {
    final rule = item.recurrence;
    if (rule == null) return [];

    final base = item.startDateTime ?? item.dueDate;
    if (base == null) return [];

    final results = <DateTime>[];
    var cursor = base;

    while (results.length < count) {
      cursor = _advance(cursor, rule);

      if (rule.until != null && cursor.isAfter(rule.until!)) break;
      if (rule.count != null && results.length >= rule.count!) break;

      if (cursor.isAfter(after)) {
        results.add(cursor);
      }
    }

    return results;
  }

  DateTime _advance(DateTime from, RecurrenceRule rule) {
    final n = rule.interval;
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: n));
      case RecurrenceFrequency.weekly:
        return from.add(Duration(days: 7 * n));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + n, from.day,
            from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + n, from.month, from.day,
            from.hour, from.minute);
    }
  }

  /// Checks whether [date] falls on an occurrence of [item].
  bool occursOn(PlannerItem item, DateTime date) {
    final rule = item.recurrence;
    if (rule == null) return false;

    final base = item.startDateTime ?? item.dueDate;
    if (base == null) return false;

    // Simple check: advance from base until we reach or pass date
    var cursor = base;
    for (int i = 0; i < 500; i++) {
      if (_sameDay(cursor, date)) return true;
      if (cursor.isAfter(date)) return false;
      cursor = _advance(cursor, rule);
    }
    return false;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
