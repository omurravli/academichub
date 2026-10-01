import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/core/widgets/planner_item_tile.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _filter = 'All';

  static const _filters = [
    _FilterItem('All', null),
    _FilterItem('Exams', PlannerItemType.exam),
    _FilterItem('Events', PlannerItemType.event),
    _FilterItem('Meetings', PlannerItemType.meeting),
    _FilterItem('Deadlines', PlannerItemType.deadline),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allAsync = ref.watch(plannerItemsProvider);
    final dayAsync = ref.watch(itemsForDateProvider(_selectedDay));

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margin, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Text('Calendar',
                        style: AppTextStyles.h2(color: cs.onSurface)),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _selectedDay = DateTime.now()),
                      icon: Icon(Icons.today_rounded,
                          color: cs.onSurfaceVariant),
                      tooltip: 'Go to today',
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppFilterChip(
                          label: f.label,
                          selected: _filter == f.label,
                          onTap: () => setState(() => _filter = f.label),
                          dotColor: f.type != null
                              ? _typeColor(f.type!, cs)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                allAsync.when(
                  loading: () => _MonthCard(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    allItems: const [],
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                    onMonthChanged: (d) => setState(() => _focusedMonth = d),
                  ),
                  error: (e, _) => const SizedBox(),
                  data: (allItems) => _MonthCard(
                    focusedMonth: _focusedMonth,
                    selectedDay: _selectedDay,
                    allItems: allItems,
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                    onMonthChanged: (d) => setState(() => _focusedMonth = d),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                SectionHeader(
                  title: DateFormat('EEEE, MMM d').format(_selectedDay),
                ),
                const SizedBox(height: AppSpacing.md),

                dayAsync.when(
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (dayItems) {
                    final filtered = _filter == 'All'
                        ? dayItems
                        : dayItems.where((i) {
                            final ft = _filters
                                .firstWhere((f) => f.label == _filter)
                                .type;
                            return ft == null || i.type == ft;
                          }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nothing here',
                        subtitle:
                            'No items for ${DateFormat('MMM d').format(_selectedDay)}.',
                      );
                    }
                    return Column(
                      children: filtered
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: PlannerItemTile(
                                  item: item,
                                  onTap: () => context.push('/planner/${item.id}'),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(PlannerItemType type, ColorScheme cs) {
    switch (type) {
      case PlannerItemType.exam: return cs.tertiary;
      case PlannerItemType.meeting: return cs.primary;
      case PlannerItemType.deadline: return cs.error;
      default: return cs.secondary;
    }
  }
}

class _FilterItem {
  final String label;
  final PlannerItemType? type;
  const _FilterItem(this.label, this.type);
}

class _MonthCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<PlannerItem> allItems;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthCard({
    required this.focusedMonth,
    required this.selectedDay,
    required this.allItems,
    required this.onDaySelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final weekdayOffset = firstDay.weekday % 7;
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    final Map<int, List<Color>> eventDots = {};
    for (final item in allItems) {
      final d = item.startDateTime ?? item.dueDate;
      if (d == null) continue;
      if (d.year != focusedMonth.year || d.month != focusedMonth.month) continue;
      eventDots.putIfAbsent(d.day, () => []);
      eventDots[d.day]!.add(_typeColor(item.type, cs));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.lightSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.softShadowDark : AppColors.softShadowLight,
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month - 1)),
                icon: Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
              ),
              Text(
                DateFormat('MMMM yyyy').format(focusedMonth),
                style: AppTextStyles.h3(color: cs.onSurface),
              ),
              IconButton(
                onPressed: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month + 1)),
                icon: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(d,
                      style:
                          AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              mainAxisExtent: 52,
            ),
            itemCount: weekdayOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < weekdayOffset) return const SizedBox();
              final day = index - weekdayOffset + 1;
              final date =
                  DateTime(focusedMonth.year, focusedMonth.month, day);
              final isSelected = date.day == selectedDay.day &&
                  date.month == selectedDay.month &&
                  date.year == selectedDay.year;
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final dots = eventDots[day] ?? [];

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : isToday
                                ? cs.primary.withOpacity(0.12)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: cs.primary.withOpacity(0.3),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: AppTextStyles.labelMd(
                            color: isSelected ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: dots.isEmpty
                          ? [const SizedBox(width: 5, height: 5)]
                          : dots.take(3).map((c) => Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                    color: c, shape: BoxShape.circle),
                              )).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _typeColor(PlannerItemType type, ColorScheme cs) {
    switch (type) {
      case PlannerItemType.exam: return cs.tertiary;
      case PlannerItemType.meeting: return cs.primary;
      case PlannerItemType.deadline: return cs.error;
      default: return cs.secondary;
    }
  }
}