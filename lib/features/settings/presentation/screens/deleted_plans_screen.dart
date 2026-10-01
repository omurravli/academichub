import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/presentation/providers/planner_providers.dart';

class DeletedPlansScreen extends ConsumerWidget {
  const DeletedPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final deletedAsync = ref.watch(deletedItemsProvider);

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
        title: Text('Deleted Plans', style: AppTextStyles.h3(color: cs.onSurface)),
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
              icon: Icons.delete_outline_rounded,
              title: 'No deleted plans',
              subtitle: 'Plans you delete will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin, vertical: AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _DeletedPlanTile(item: items[index]),
          );
        },
      ),
    );
  }

  void _confirmClearAll(
      BuildContext context, WidgetRef ref, List<PlannerItem> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text(
            'This will permanently delete all plans in the trash. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(plannerRepositoryProvider);
              for (final item in items) {
                await repo.delete(item.id);
              }
              ref.read(plannerRefreshProvider.notifier).state++;
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

class _DeletedPlanTile extends ConsumerWidget {
  final PlannerItem item;
  const _DeletedPlanTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final deletedDate = item.deletedAt != null
        ? DateFormat('d MMM yyyy').format(item.deletedAt!)
        : '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
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
              onPressed: () => _restore(context, ref),
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

  void _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(plannerRepositoryProvider).restore(item.id);
    ref.read(plannerRefreshProvider.notifier).state++;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text('"${item.title}" will be removed forever.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(plannerRepositoryProvider).delete(item.id);
              ref.read(plannerRefreshProvider.notifier).state++;
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
