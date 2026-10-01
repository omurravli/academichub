import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';

// Bump this to force all planner providers to reload
final plannerRefreshProvider = StateProvider<int>((ref) => 0);

final plannerItemsProvider = FutureProvider<List<PlannerItem>>((ref) {
  ref.watch(plannerRefreshProvider);
  return ref.watch(plannerRepositoryProvider).getAll();
});

final todayItemsProvider = FutureProvider<List<PlannerItem>>((ref) {
  ref.watch(plannerRefreshProvider);
  return ref.watch(plannerRepositoryProvider).getByDate(DateTime.now());
});

final deletedItemsProvider = FutureProvider<List<PlannerItem>>((ref) {
  ref.watch(plannerRefreshProvider);
  return ref.watch(plannerRepositoryProvider).getDeleted();
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final itemsForDateProvider = FutureProvider.family<List<PlannerItem>, DateTime>(
  (ref, date) {
    ref.watch(plannerRefreshProvider);
    return ref.watch(plannerRepositoryProvider).getByDate(date);
  },
);

// Items with upcoming reminders within the next 7 days, sorted by fire time.
// Each record pairs the item with the exact DateTime the notification fires.
final upcomingRemindersProvider =
    Provider<List<({PlannerItem item, DateTime fireAt})>>((ref) {
  final items = ref.watch(plannerItemsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final cutoff = now.add(const Duration(days: 7));

  final result = <({PlannerItem item, DateTime fireAt})>[];
  for (final item in items) {
    final r = item.reminder;
    if (r == null || !r.enabled) continue;
    final target = item.startDateTime ?? item.dueDate;
    if (target == null) continue;
    final fireAt = target.subtract(Duration(minutes: r.minutesBefore));
    if (fireAt.isAfter(now) && fireAt.isBefore(cutoff)) {
      result.add((item: item, fireAt: fireAt));
    }
  }
  result.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return result;
});

// Planner items checked off today, most recent first.
final completedTodayProvider = Provider<List<PlannerItem>>((ref) {
  final items = ref.watch(plannerItemsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return items
      .where((i) =>
          i.isCompleted &&
          i.updatedAt.year == now.year &&
          i.updatedAt.month == now.month &&
          i.updatedAt.day == now.day)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});