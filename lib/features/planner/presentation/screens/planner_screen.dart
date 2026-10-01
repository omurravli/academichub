import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/app/router/app_router.dart';

import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/core/widgets/planner_item_tile.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';
import 'package:studiq/core/providers/repository_providers.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  String _activeFilter = 'All';
  PlannerItemStatus? _statusFilter;

  final _filters = [
    ('All', null as PlannerItemStatus?),
    ('To Do', PlannerItemStatus.todo),
    ('In Progress', PlannerItemStatus.inProgress),
    ('Done', PlannerItemStatus.done),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allAsync = ref.watch(plannerItemsProvider);
    final allItems = allAsync.valueOrNull ?? [];
    final filtered = _statusFilter == null
        ? allItems
        : allItems.where((i) => i.status == _statusFilter).toList();

    // Group by type
    final grouped = <String, List<PlannerItem>>{};
    for (final item in filtered) {
      final key = _typeLabel(item.type);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(plannerItemsProvider),
        child: CustomScrollView(
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
                    Text('Planner',
                        style: AppTextStyles.h2(color: cs.onSurface)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.addPlannerItem),
                      icon: Icon(Icons.add_rounded, color: cs.primary),
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
                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppFilterChip(
                          label: f.$1,
                          selected: _activeFilter == f.$1,
                          onTap: () => setState(() {
                            _activeFilter = f.$1;
                            _statusFilter = f.$2;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Grouped items
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'All clear!',
                    subtitle: 'No items in this category.',
                  )
                else
                  ...grouped.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GroupHeader(label: entry.key),
                          const SizedBox(height: AppSpacing.sm),
                          ...entry.value.map((item) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: PlannerItemTile(
                                  item: item,
                                  onTap: () => context.push('/planner/${item.id}'),
                                  onToggle: () => _toggle(ref, item),
                                  onDelete: () => _delete(ref, item),
                                ),
                              )),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      )),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addPlannerItem),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _toggle(WidgetRef ref, PlannerItem item) async {
    final repo = ref.read(plannerRepositoryProvider);
    await repo.update(item.copyWith(
      status: item.isCompleted ? PlannerItemStatus.todo : PlannerItemStatus.done,
      updatedAt: DateTime.now(),
    ));
    ref.read(plannerRefreshProvider.notifier).state++;
  }

  void _delete(WidgetRef ref, PlannerItem item) async {
    final repo = ref.read(plannerRepositoryProvider);
    await repo.softDelete(item.id);
    ref.read(plannerRefreshProvider.notifier).state++;
  }

  String _typeLabel(PlannerItemType type) {
    switch (type) {
      case PlannerItemType.task: return 'Tasks';
      case PlannerItemType.meeting: return 'Meetings';
      case PlannerItemType.exam: return 'Exams';
      case PlannerItemType.deadline: return 'Deadlines';
      case PlannerItemType.event: return 'Events';
      case PlannerItemType.reminder: return 'Reminders';
    }
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(label, style: AppTextStyles.labelMd(color: cs.onSurfaceVariant));
  }
}