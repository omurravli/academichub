import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/presentation/providers/project_providers.dart';

class DeletedProjectsScreen extends ConsumerWidget {
  const DeletedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final deletedAsync = ref.watch(deletedProjectsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Deleted Projects', style: AppTextStyles.h3(color: cs.onSurface)),
        actions: [
          deletedAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClearAll(context, ref, items),
                    child: Text('Clear All',
                        style: AppTextStyles.labelMd(color: cs.error)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: deletedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_off_rounded,
              title: 'No deleted projects',
              subtitle: 'Projects you delete will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin, vertical: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _DeletedProjectTile(project: items[index]),
          );
        },
      ),
    );
  }

  void _confirmClearAll(
      BuildContext context, WidgetRef ref, List<Project> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text(
            'This will permanently delete all projects in the trash. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(projectRepositoryProvider);
              for (final p in items) {
                await repo.delete(p.id);
              }
              ref.invalidate(deletedProjectsProvider);
              ref.invalidate(projectsProvider);
            },
            child: Text('Delete All',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _DeletedProjectTile extends ConsumerWidget {
  final Project project;
  const _DeletedProjectTile({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deletedDate = project.deletedAt != null
        ? DateFormat('d MMM yyyy').format(project.deletedAt!)
        : '';

    return Material(
      color: isDark
          ? AppColors.darkSurfaceContainerLowest
          : AppColors.lightSurfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: project.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: AppTextStyles.labelMd(color: cs.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deletedDate.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Deleted $deletedDate',
                      style: AppTextStyles.labelSm(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _restore(ref),
              icon: Icon(Icons.restore_rounded, color: cs.primary, size: 20),
              tooltip: 'Restore',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: Icon(Icons.delete_forever_rounded, color: cs.error, size: 20),
              tooltip: 'Delete permanently',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _restore(WidgetRef ref) async {
    await ref.read(projectRepositoryProvider).restore(project.id);
    ref.invalidate(deletedProjectsProvider);
    ref.invalidate(projectsProvider);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('"${project.title}" will be removed forever.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(projectRepositoryProvider).delete(project.id);
              ref.invalidate(deletedProjectsProvider);
            },
            child: Text('Delete',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
