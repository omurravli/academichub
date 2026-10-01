import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/app/router/app_router.dart';
import 'package:studiq/core/widgets/app_widgets.dart';
import 'package:studiq/core/widgets/project_card.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/presentation/providers/project_providers.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  String _filter = 'All';
  final _filters = ['All', 'In Progress', 'Planning', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final projectsAsync = ref.watch(projectsProvider);

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
                    Text('Projects', style: AppTextStyles.h2(color: cs.onSurface)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.tune_rounded, color: cs.onSurfaceVariant),
                    ),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.addProject),
                      icon: Icon(Icons.add_rounded, color: cs.primary),
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
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppFilterChip(
                          label: f,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                projectsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (projects) {
                    final filtered = _filter == 'All'
                        ? projects
                        : projects.where((p) {
                            switch (_filter) {
                              case 'In Progress':
                                return p.status == ProjectStatus.inProgress;
                              case 'Planning':
                                return p.status == ProjectStatus.planning;
                              case 'Completed':
                                return p.status == ProjectStatus.completed;
                              default:
                                return true;
                            }
                          }).toList();

                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.folder_open_rounded,
                        title: 'No projects yet',
                        subtitle: 'Start organizing your assignments and goals.',
                        actionLabel: 'New Project',
                        onAction: () => context.push(AppRoutes.addProject),
                      );
                    }

                    return Column(
                      children: [
                        ...filtered.map((proj) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: ProjectCard(
                                project: proj,
                                onTap: () => context.push('/projects/${proj.id}'),
                              ),
                            )),
                        _AddProjectCard(
                            onTap: () => context.push(AppRoutes.addProject)),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addProject),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _AddProjectCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProjectCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(Icons.add_rounded, color: cs.onSurfaceVariant, size: 28),
        ),
      ),
    );
  }
}