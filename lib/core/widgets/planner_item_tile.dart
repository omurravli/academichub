import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/app/theme/app_theme.dart';

class PlannerItemTile extends StatelessWidget {
  final PlannerItem item;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const PlannerItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _typeColor(item.type, cs);

    return Material(
      color: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.lightSurfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.softShadowDark
                    : AppColors.softShadowLight,
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? cs.outlineVariant : typeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        // Checkbox — only when onToggle provided
                        if (onToggle != null) ...[
                          GestureDetector(
                            onTap: onToggle,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: item.isCompleted
                                    ? cs.secondary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: item.isCompleted
                                      ? cs.secondary
                                      : cs.outlineVariant,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: item.isCompleted
                                  ? Icon(Icons.check,
                                      size: 14, color: cs.onSecondary)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],

                        // Title & meta
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTextStyles.labelMd(
                                  color: item.isCompleted
                                      ? cs.onSurfaceVariant
                                      : cs.onSurface,
                                ).copyWith(
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_timeString() != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _timeString()!,
                                  style: AppTextStyles.labelSm(
                                      color: cs.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Trash when completed, priority dot otherwise
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: item.isCompleted && onDelete != null
                              ? GestureDetector(
                                  key: const ValueKey('trash'),
                                  onTap: onDelete,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: AppSpacing.sm),
                                    child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: cs.error,
                                        size: 20),
                                  ),
                                )
                              : (item.priority == PlannerItemPriority.urgent ||
                                      item.priority == PlannerItemPriority.high)
                                  ? Container(
                                      key: const ValueKey('dot'),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: item.priority ==
                                                PlannerItemPriority.urgent
                                            ? cs.error
                                            : cs.tertiary,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : const SizedBox(key: ValueKey('empty')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _timeString() {
    if (item.startDateTime != null) {
      final fmt = DateFormat('h:mm a');
      final start = fmt.format(item.startDateTime!);
      if (item.endDateTime != null) {
        return '$start – ${fmt.format(item.endDateTime!)}';
      }
      return start;
    }
    if (item.dueDate != null) {
      return 'Due ${DateFormat('MMM d').format(item.dueDate!)}';
    }
    return null;
  }

  Color _typeColor(PlannerItemType type, ColorScheme cs) {
    switch (type) {
      case PlannerItemType.exam: return cs.tertiary;
      case PlannerItemType.meeting: return cs.primary;
      case PlannerItemType.deadline: return cs.error;
      case PlannerItemType.event: return cs.secondary;
      case PlannerItemType.task: return cs.primary;
      case PlannerItemType.reminder: return cs.secondary;
    }
  }
}