import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studiq/core/providers/repository_providers.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/repositories/project_repository.dart';

final projectsProvider = FutureProvider<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getAll();
});

final deletedProjectsProvider = FutureProvider<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getDeleted();
});

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

// ── Milestones ────────────────────────────────────────────────────────────────

class MilestonesNotifier
    extends StateNotifier<AsyncValue<List<Milestone>>> {
  MilestonesNotifier(this._projectId, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final String _projectId;
  final Ref _ref;

  ProjectRepository get _repo => _ref.read(projectRepositoryProvider);

  Future<void> _load() async {
    try {
      final list = await _repo.getMilestones(_projectId);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (mounted) state = AsyncValue.data(list);
    } catch (e, s) {
      if (mounted) state = AsyncValue.error(e, s);
    }
  }

  Future<void> add(String title, {DateTime? dueDate}) async {
    if (title.trim().isEmpty) return;
    final m = Milestone(
      id: '',
      projectId: _projectId,
      title: title.trim(),
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    final saved = await _repo.createMilestone(m);
    final updated = List<Milestone>.from(state.valueOrNull ?? [])..add(saved);
    if (mounted) state = AsyncValue.data(updated);
    await _syncProgress(updated);
  }

  Future<void> toggle(Milestone m) async {
    final toggled = m.copyWith(completed: !m.completed);
    await _repo.updateMilestone(toggled);
    final updated = (state.valueOrNull ?? [])
        .map((e) => e.id == m.id ? toggled : e)
        .toList();
    if (mounted) state = AsyncValue.data(updated);
    await _syncProgress(updated);
  }

  Future<void> remove(String id) async {
    await _repo.deleteMilestone(id);
    final updated =
        (state.valueOrNull ?? []).where((m) => m.id != id).toList();
    if (mounted) state = AsyncValue.data(updated);
    await _syncProgress(updated);
  }

  Future<void> _syncProgress(List<Milestone> milestones) async {
    final progress = milestones.isEmpty
        ? 0.0
        : milestones.where((m) => m.completed).length /
            milestones.length;
    final project = await _repo.getById(_projectId);
    if (project == null) return;
    await _repo.update(project.copyWith(progress: progress));
    _ref.invalidate(projectsProvider);
  }
}

final milestonesProvider = StateNotifierProvider.family<MilestonesNotifier,
    AsyncValue<List<Milestone>>, String>(
  (ref, projectId) => MilestonesNotifier(projectId, ref),
);