import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/app/router/app_router.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/core/widgets/planner_item_tile.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';
import 'package:studiq/features/projects/presentation/providers/project_providers.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/features/timer/presentation/providers/pomodoro_provider.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayAsync = ref.watch(todayItemsProvider);
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: cs.surface,
      body: todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (items) {
          final done = items.where((i) => i.isCompleted).length;
          final total = items.length;

          return CustomScrollView(
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
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkSurfaceContainerHigh
                                : AppColors.lightSurfaceContainerHigh,
                          ),
                          child: Icon(Icons.person, color: cs.primary, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Studiq',
                            style: AppTextStyles.h3(color: cs.onSurface)),
                        const Spacer(),
                        _NotificationBell(
                          onTap: () =>
                              _showNotificationCenter(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppSpacing.sm),
                    Text(_greeting(now),
                        style: AppTextStyles.h1(color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: AppTextStyles.bodyLg(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _DailyFocusCard(done: done, total: total),
                    const SizedBox(height: AppSpacing.xl),

                    SectionHeader(
                      title: "Today's Schedule",
                      onAction: () => context.go(AppRoutes.planner),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (items.isEmpty)
                      EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Nothing scheduled today',
                        subtitle: 'Tap + to add your first item.',
                        actionLabel: 'Add Item',
                        onAction: () => context.go(AppRoutes.addPlannerItem),
                      )
                    else
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: PlannerItemTile(
                              item: item,
                              onTap: () => context.push('/planner/${item.id}'),
                              onToggle: () => _toggleItem(ref, item),
                              onDelete: () => _deleteItem(ref, item),
                            ),
                          )),

                    const SizedBox(height: AppSpacing.xl),

                    if (projects.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Active Projects',
                        action: 'View all',
                        onAction: () => context.go(AppRoutes.projects),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...projects.take(2).map((proj) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _MiniProjectRow(project: proj),
                          )),
                    ],

                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.addPlannerItem),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _deleteItem(WidgetRef ref, PlannerItem item) async {
    await ref.read(plannerRepositoryProvider).delete(item.id);
    ref.read(plannerRefreshProvider.notifier).state++;
  }

  void _toggleItem(WidgetRef ref, PlannerItem item) async {
    final repo = ref.read(plannerRepositoryProvider);
    final updated = item.copyWith(
      status: item.isCompleted
          ? PlannerItemStatus.todo
          : PlannerItemStatus.done,
      updatedAt: DateTime.now(),
    );
    await repo.update(updated);
    ref.read(plannerRefreshProvider.notifier).state++;
  }

  String _greeting(DateTime dt) {
    final h = dt.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const _NotificationCenterSheet(),
    );
  }
}

class _DailyFocusCard extends StatefulWidget {
  final int done;
  final int total;
  const _DailyFocusCard({required this.done, required this.total});

  @override
  State<_DailyFocusCard> createState() => _DailyFocusCardState();
}

class _DailyFocusCardState extends State<_DailyFocusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0;

  double get _targetProgress =>
      widget.total == 0 ? 0.0 : widget.done / widget.total;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: _targetProgress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _previousProgress = _targetProgress;
  }

  @override
  void didUpdateWidget(_DailyFocusCard old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done || old.total != widget.total) {
      _animation = Tween<double>(
        begin: _previousProgress,
        end: _targetProgress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
      _previousProgress = _targetProgress;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = widget.done;
    final total = widget.total;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final pct = (progress * 100).round();

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainerLow
                : AppColors.lightSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.softShadowDark
                    : AppColors.softShadowLight,
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Focus',
                        style: AppTextStyles.h3(color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Add items to start your day!'
                          : done == total
                              ? 'All done — great work! 🎉'
                              : '$done of $total completed',
                      style:
                          AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$done/$total',
                                style:
                                    AppTextStyles.h2(color: cs.primary)),
                            Text('DONE',
                                style: AppTextStyles.labelSm(
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Container(
                              width: 1,
                              height: 36,
                              color: cs.outlineVariant),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${total - done}',
                                style:
                                    AppTextStyles.h2(color: cs.tertiary)),
                            Text('LEFT',
                                style: AppTextStyles.labelSm(
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerHigh
                            : AppColors.lightSurfaceContainerHigh,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(cs.primary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.lightSurfaceContainerLowest,
                      ),
                      child: Center(
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniProjectRow extends StatelessWidget {
  final dynamic project;
  const _MiniProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainerLow
            : AppColors.lightSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.softShadowDark : AppColors.softShadowLight,
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: project.color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(project.title,
                    style: AppTextStyles.labelMd(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${project.progressPercent}%',
                  style: AppTextStyles.labelSm(color: project.color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(value: project.progress, fillColor: project.color),
        ],
      ),
    );
  }
}

// ── Notification bell with badge ──────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final upcoming = ref.watch(upcomingRemindersProvider);
    final now = DateTime.now();
    final todayCount = upcoming
        .where((r) =>
            r.fireAt.year == now.year &&
            r.fireAt.month == now.month &&
            r.fireAt.day == now.day)
        .length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              todayCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: cs.onSurface,
              size: 24,
            ),
            if (todayCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      todayCount > 9 ? '9+' : '$todayCount',
                      style: TextStyle(
                        color: cs.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Notification centre sheet ──────────────────────────────────────────────────

class _NotificationCenterSheet extends ConsumerStatefulWidget {
  const _NotificationCenterSheet();

  @override
  ConsumerState<_NotificationCenterSheet> createState() =>
      _NotificationCenterSheetState();
}

class _NotificationCenterSheetState
    extends ConsumerState<_NotificationCenterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // ── Drag handle + title ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin, AppSpacing.lg, AppSpacing.margin, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text('Notifications',
                        style: AppTextStyles.h3(color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Recent'),
                  ],
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  indicatorColor: cs.primary,
                  dividerColor: cs.outlineVariant,
                ),
              ],
            ),
          ),

          // ── Tab views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UpcomingTab(scrollController: scrollController),
                _RecentTab(scrollController: scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming tab ───────────────────────────────────────────────────────────────

class _UpcomingTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _UpcomingTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final upcoming = ref.watch(upcomingRemindersProvider);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (upcoming.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: AppSpacing.md),
                Text('No upcoming reminders',
                    style: AppTextStyles.h3(color: cs.onSurface)),
                const SizedBox(height: AppSpacing.sm),
                Text('Add reminders to planner items\nto see them here.',
                    style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      );
    }

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final todayItems =
        upcoming.where((r) => sameDay(r.fireAt, now)).toList();
    final tomorrowItems =
        upcoming.where((r) => sameDay(r.fireAt, tomorrow)).toList();
    final laterItems = upcoming
        .where((r) =>
            !sameDay(r.fireAt, now) && !sameDay(r.fireAt, tomorrow))
        .toList();

    final timeFormat = DateFormat('HH:mm');

    Widget buildItem(({PlannerItem item, DateTime fireAt}) r) {
      final diff = r.fireAt.difference(now);
      final timeUntil = diff.inMinutes < 60
          ? 'in ${diff.inMinutes}m'
          : diff.inHours < 24
              ? 'in ${diff.inHours}h'
              : 'in ${diff.inDays}d';

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_typeIcon(r.item.type),
                  size: 18, color: cs.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.item.title,
                      style: AppTextStyles.bodyMd(color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${timeFormat.format(r.fireAt)}  ·  $timeUntil',
                    style:
                        AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildGroup(String label, List<({PlannerItem item, DateTime fireAt})> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                bottom: AppSpacing.sm, top: AppSpacing.md),
            child: Text(label.toUpperCase(),
                style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
          ),
          ...items.map(buildItem),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xxl),
      children: [
        buildGroup('Today', todayItems),
        buildGroup('Tomorrow', tomorrowItems),
        buildGroup('This Week', laterItems),
      ],
    );
  }

  IconData _typeIcon(PlannerItemType type) => switch (type) {
        PlannerItemType.exam => Icons.quiz_rounded,
        PlannerItemType.meeting => Icons.people_rounded,
        PlannerItemType.deadline => Icons.flag_rounded,
        PlannerItemType.event => Icons.event_rounded,
        PlannerItemType.reminder => Icons.notifications_rounded,
        PlannerItemType.task => Icons.check_circle_outline_rounded,
      };
}

// ── Recent tab ─────────────────────────────────────────────────────────────────

class _RecentTab extends ConsumerWidget {
  final ScrollController scrollController;
  const _RecentTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completed = ref.watch(completedTodayProvider);
    final todaySessions = ref.watch(pomodoroProvider).todaySessions;
    final timeFormat = DateFormat('HH:mm');

    final hasAnything = todaySessions > 0 || completed.isNotEmpty;

    if (!hasAnything) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Icon(Icons.history_rounded,
                    size: 48,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: AppSpacing.md),
                Text("Nothing yet today",
                    style: AppTextStyles.h3(color: cs.onSurface)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                    'Completed tasks and\nfocus sessions will appear here.',
                    style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin, AppSpacing.md, AppSpacing.margin, AppSpacing.xxl),
      children: [
        if (todaySessions > 0) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('FOCUS SESSIONS'.toUpperCase(),
                style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.lightSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.timer_rounded,
                      size: 18, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$todaySessions focus session${todaySessions == 1 ? '' : 's'} completed',
                        style: AppTextStyles.bodyMd(color: cs.onSurface),
                      ),
                      Text(
                        '${todaySessions * 25} min of focused work today',
                        style: AppTextStyles.labelSm(
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 3,
                  children: List.generate(
                    todaySessions.clamp(0, 8),
                    (_) => Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (completed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text('COMPLETED TODAY'.toUpperCase(),
                style: AppTextStyles.labelSm(color: cs.onSurfaceVariant)),
          ),
          ...completed.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.check_rounded,
                          size: 18, color: cs.tertiary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.bodyMd(color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            timeFormat.format(item.updatedAt),
                            style: AppTextStyles.labelSm(
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}