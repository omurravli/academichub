import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/widgets/app_widgets.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(project.status, cs);
    final isOverdue = project.dueDate != null &&
        project.dueDate!.isBefore(DateTime.now()) &&
        !project.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.lightSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color:
                  isDark ? AppColors.softShadowDark : AppColors.softShadowLight,
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge + menu
            Row(
              children: [
                TypeBadge(
                  label: _statusLabel(project.status),
                  backgroundColor: statusColor.withOpacity(0.15),
                  textColor: statusColor,
                  icon: _statusIcon(project.status),
                ),
                const Spacer(),
                Icon(Icons.more_horiz,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              project.title,
              style: AppTextStyles.h3(color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (project.description != null) ...[
              const SizedBox(height: AppSpacing.unit),
              Text(
                project.description!,
                style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                ),
                Text(
                  '${project.progressPercent}%',
                  style: AppTextStyles.labelSm(color: project.color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            AppProgressBar(value: project.progress, fillColor: project.color),
            const SizedBox(height: AppSpacing.md),

            // Footer
            Divider(color: cs.outlineVariant.withOpacity(0.3), height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  isOverdue ? Icons.warning_rounded : Icons.calendar_today,
                  size: 16,
                  color: isOverdue ? cs.error : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  project.dueDate != null
                      ? _dueDateLabel(project.dueDate!, isOverdue)
                      : 'No deadline',
                  style: AppTextStyles.labelMd(
                    color: isOverdue ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dueDateLabel(DateTime due, bool overdue) {
    final diff = due.difference(DateTime.now()).inDays;
    if (overdue) return 'Overdue';
    if (diff == 0) return 'Due Today';
    if (diff == 1) return 'Due Tomorrow';
    return 'Due ${DateFormat('MMM d').format(due)}';
  }

  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.planning: return 'Planning';
      case ProjectStatus.inProgress: return 'In Progress';
      case ProjectStatus.onHold: return 'On Hold';
      case ProjectStatus.completed: return 'Completed';
      case ProjectStatus.cancelled: return 'Cancelled';
    }
  }

  IconData _statusIcon(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.planning: return Icons.edit_note;
      case ProjectStatus.inProgress: return Icons.sync;
      case ProjectStatus.onHold: return Icons.pause_circle_outline;
      case ProjectStatus.completed: return Icons.check_circle_outline;
      case ProjectStatus.cancelled: return Icons.cancel_outlined;
    }
  }

  Color _statusColor(ProjectStatus s, ColorScheme cs) {
    switch (s) {
      case ProjectStatus.planning: return cs.tertiary;
      case ProjectStatus.inProgress: return cs.primary;
      case ProjectStatus.onHold: return cs.secondary;
      case ProjectStatus.completed: return cs.secondary;
      case ProjectStatus.cancelled: return cs.error;
    }
  }
}
