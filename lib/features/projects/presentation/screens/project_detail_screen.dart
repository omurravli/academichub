import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/core/widgets/planner_item_tile.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/features/projects/presentation/providers/project_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final projectsAsync = ref.watch(projectsProvider);
    final milestonesAsync = ref.watch(milestonesProvider(projectId));

    // Use cached value on refresh so there's no full-screen flash.
    final projects = projectsAsync.valueOrNull;
    final project =
        projects?.cast<Project?>().firstWhere((p) => p!.id == projectId,
            orElse: () => null);

    if (projectsAsync.isLoading && project == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: _backButton(context),
        ),
        body: const Center(child: Text('Project not found.')),
      );
    }

    final milestones = milestonesAsync.valueOrNull ?? [];
    final liveProgress = milestones.isNotEmpty
        ? milestones.where((m) => m.completed).length / milestones.length
        : project.progress;
    final allDone = milestones.isNotEmpty && milestones.every((m) => m.completed);

    final relatedItems = ref
            .watch(plannerItemsProvider)
            .valueOrNull
            ?.where((i) => i.projectId == projectId)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: _backButton(context),
        actions: [
          IconButton(
            onPressed: () => context.push('/projects/$projectId?edit=true'),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, project.title),
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Project header card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                            color: project.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TypeBadge(
                        label: project.status.name,
                        backgroundColor: project.color.withValues(alpha: 0.15),
                        textColor: project.color,
                      ),
                      if (allDone) ...[
                        const SizedBox(width: AppSpacing.sm),
                        TypeBadge(
                          label: 'All done',
                          backgroundColor:
                              cs.tertiary.withValues(alpha: 0.15),
                          textColor: cs.tertiary,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(project.title,
                      style: AppTextStyles.h2(color: cs.onSurface)),
                  if (project.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(project.description!,
                        style:
                            AppTextStyles.bodyMd(color: cs.onSurfaceVariant)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress',
                          style: AppTextStyles.labelSm(
                              color: cs.onSurfaceVariant)),
                      Text(
                        '${(liveProgress * 100).round()}%',
                        style:
                            AppTextStyles.labelSm(color: project.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: AppProgressBar(
                      key: ValueKey(liveProgress),
                      value: liveProgress,
                      fillColor: project.color,
                    ),
                  ),
                  if (milestones.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${milestones.where((m) => m.completed).length} / ${milestones.length} tasks completed',
                      style:
                          AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (project.dueDate != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Due ${DateFormat('MMM d, yyyy').format(project.dueDate!)}',
                          style: AppTextStyles.labelMd(
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Tasks / milestones ───────────────────────────────────────────
            SectionHeader(
              title: 'Tasks',
              action: 'Add',
              onAction: () => _showAddMilestone(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),

            milestonesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error loading tasks: $e',
                  style: AppTextStyles.bodyMd(color: cs.error)),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyTasksState(
                    projectColor: project.color,
                    onAdd: () => _showAddMilestone(context, ref),
                  );
                }
                return Column(
                  children: list
                      .map((m) => _MilestoneTile(
                            key: ValueKey(m.id),
                            milestone: m,
                            projectColor: project.color,
                            onToggle: () => ref
                                .read(milestonesProvider(projectId).notifier)
                                .toggle(m),
                            onDelete: () => ref
                                .read(milestonesProvider(projectId).notifier)
                                .remove(m.id),
                          ))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Related planner tasks ────────────────────────────────────────
            SectionHeader(title: 'Linked Planner Tasks'),
            const SizedBox(height: AppSpacing.md),
            if (relatedItems.isEmpty)
              Text('No planner tasks linked to this project.',
                  style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant))
            else
              ...relatedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PlannerItemTile(item: item),
                  )),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Add milestone sheet ────────────────────────────────────────────────────

  void _showAddMilestone(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final titleCtrl = TextEditingController();
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.lg,
            AppSpacing.margin,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('Add Task',
                  style: AppTextStyles.h3(color: cs.onSurface)),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. Write introduction',
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    ref
                        .read(milestonesProvider(projectId).notifier)
                        .add(v, dueDate: dueDate);
                    Navigator.pop(ctx);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Optional due date
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setSheet(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? AppColors.darkSurfaceContainerLow
                        : AppColors.lightSurfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: dueDate != null
                          ? cs.primary.withValues(alpha: 0.4)
                          : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_rounded,
                          size: 18,
                          color: dueDate != null
                              ? cs.primary
                              : cs.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        dueDate != null
                            ? DateFormat('d MMM yyyy').format(dueDate!)
                            : 'Due date (optional)',
                        style: AppTextStyles.bodyMd(
                            color: dueDate != null
                                ? cs.onSurface
                                : cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      if (dueDate != null)
                        GestureDetector(
                          onTap: () => setSheet(() => dueDate = null),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: cs.onSurfaceVariant),
                        )
                      else
                        Icon(Icons.chevron_right,
                            size: 18, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    ref
                        .read(milestonesProvider(projectId).notifier)
                        .add(title, dueDate: dueDate);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  IconButton _backButton(BuildContext context) => IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/projects');
          }
        },
        icon: const Icon(Icons.arrow_back_rounded),
      );

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('"$title" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(projectRepositoryProvider)
                  .softDelete(projectId);
              ref.invalidate(projectsProvider);
              ref.invalidate(deletedProjectsProvider);
              if (context.mounted) context.go('/projects');
            },
            child: Text(
              'Delete',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone tile ─────────────────────────────────────────────────────────────

class _MilestoneTile extends StatelessWidget {
  final Milestone milestone;
  final Color projectColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MilestoneTile({
    super.key,
    required this.milestone,
    required this.projectColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = milestone.completed;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Dismissible(
        key: ValueKey(milestone.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: cs.onErrorContainer),
        ),
        onDismissed: (_) => onDelete(),
        child: Material(
          color: isDark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.lightSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  // Custom animated checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: done
                          ? projectColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: done
                          ? null
                          : Border.all(
                              color: cs.outlineVariant, width: 1.5),
                    ),
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milestone.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: done
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: cs.onSurfaceVariant,
                          ),
                        ),
                        if (milestone.dueDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              DateFormat('d MMM yyyy')
                                  .format(milestone.dueDate!),
                              style: AppTextStyles.labelSm(
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 18,
                      color: cs.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyTasksState extends StatelessWidget {
  final Color projectColor;
  final VoidCallback onAdd;

  const _EmptyTasksState({required this.projectColor, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: projectColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: projectColor.withValues(alpha: 0.2),
            style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded,
              size: 36, color: projectColor.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.md),
          Text('No tasks yet',
              style: AppTextStyles.h3(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Break your project into tasks.\nEach completed task advances your progress.',
            style: AppTextStyles.bodyMd(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add first task'),
            style: OutlinedButton.styleFrom(
              foregroundColor: projectColor,
              side: BorderSide(color: projectColor.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}
