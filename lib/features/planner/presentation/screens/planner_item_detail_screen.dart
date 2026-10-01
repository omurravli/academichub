import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';

class PlannerItemDetailScreen extends ConsumerWidget {
  final String itemId;
  const PlannerItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final allAsync = ref.watch(plannerItemsProvider);

    return allAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (items) {
        final item = items.cast<PlannerItem?>().firstWhere(
              (i) => i!.id == itemId,
              orElse: () => null,
            );

        if (item == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.go('/planner'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: const Center(child: Text('Item not found.')),
          );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/planner');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                onPressed: () => context.go('/planner/$itemId?edit=true'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TypeBadge(
                  label: item.type.name,
                  backgroundColor: _typeColor(item.type, cs).withOpacity(0.15),
                  textColor: _typeColor(item.type, cs),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(item.title, style: AppTextStyles.h2(color: cs.onSurface)),
                if (item.description != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(item.description!,
                      style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: AppSpacing.xl),
                _DetailRow(
                  icon: Icons.flag_rounded,
                  label: 'Priority',
                  value: item.priority.name,
                ),
                if (item.startDateTime != null)
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Start',
                    value: DateFormat('EEE, MMM d • h:mm a').format(item.startDateTime!),
                  ),
                if (item.endDateTime != null)
                  _DetailRow(
                    icon: Icons.access_time_filled_rounded,
                    label: 'End',
                    value: DateFormat('EEE, MMM d • h:mm a').format(item.endDateTime!),
                  ),
                if (item.dueDate != null)
                  _DetailRow(
                    icon: Icons.event_rounded,
                    label: 'Due',
                    value: DateFormat('EEE, MMM d').format(item.dueDate!),
                    valueColor: item.isOverdue ? cs.error : null,
                  ),
                if (item.reminder != null)
                  _DetailRow(
                    icon: Icons.notifications_active_outlined,
                    label: 'Reminder',
                    value: '${item.reminder!.minutesBefore} min before',
                  ),
                if (item.recurrence != null)
                  _DetailRow(
                    icon: Icons.repeat_rounded,
                    label: 'Repeats',
                    value: item.recurrence!.frequency.name,
                  ),
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: item.tags
                        .map((tag) => Chip(
                              label: Text(tag),
                              labelStyle: AppTextStyles.labelSm(
                                  color: cs.onSurfaceVariant),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.labelMd(color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: AppTextStyles.labelMd(color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }
}