import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studiq/data/datasources/planner_firestore_datasource.dart';
import 'package:studiq/data/datasources/project_firestore_datasource.dart';
import 'package:studiq/features/auth/presentation/providers/auth_provider.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/domain/repositories/planner_repository.dart';
import 'package:studiq/features/planner/data/repositories/planner_repository_impl.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';
import 'package:studiq/features/projects/domain/repositories/project_repository.dart';
import 'package:studiq/features/projects/data/repositories/project_repository_impl.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String? _currentUid(Ref ref) =>
    ref.watch(authStateProvider).maybeWhen(data: (u) => u?.uid, orElse: () => null);

// ── Repositories ──────────────────────────────────────────────────────────────

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  final uid = _currentUid(ref);
  if (uid == null) return const _EmptyPlannerRepository();
  return PlannerRepositoryImpl(PlannerFirestoreDataSource(uid));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final uid = _currentUid(ref);
  if (uid == null) return const _EmptyProjectRepository();
  return ProjectRepositoryImpl(ProjectFirestoreDataSource(uid));
});

// ── Empty stubs (shown while logged out / auth loading) ───────────────────────

class _EmptyPlannerRepository implements PlannerRepository {
  const _EmptyPlannerRepository();
  @override Future<List<PlannerItem>> getAll() async => [];
  @override Future<List<PlannerItem>> getDeleted() async => [];
  @override Future<List<PlannerItem>> getByDate(DateTime d) async => [];
  @override Future<List<PlannerItem>> getByProject(String id) async => [];
  @override Future<PlannerItem?> getById(String id) async => null;
  @override Future<PlannerItem> create(PlannerItem item) async => item;
  @override Future<PlannerItem> update(PlannerItem item) async => item;
  @override Future<void> softDelete(String id) async {}
  @override Future<void> restore(String id) async {}
  @override Future<void> delete(String id) async {}
  @override Stream<List<PlannerItem>> watchAll() => const Stream.empty();
  @override Stream<List<PlannerItem>> watchByDate(DateTime d) => const Stream.empty();
}

class _EmptyProjectRepository implements ProjectRepository {
  const _EmptyProjectRepository();
  @override Future<List<Project>> getAll() async => [];
  @override Future<List<Project>> getDeleted() async => [];
  @override Future<Project?> getById(String id) async => null;
  @override Future<Project> create(Project project) async => project;
  @override Future<Project> update(Project project) async => project;
  @override Future<void> softDelete(String id) async {}
  @override Future<void> restore(String id) async {}
  @override Future<void> delete(String id) async {}
  @override Stream<List<Project>> watchAll() => const Stream.empty();
  @override Future<List<Milestone>> getMilestones(String projectId) async => [];
  @override Future<Milestone> createMilestone(Milestone m) async => m;
  @override Future<Milestone> updateMilestone(Milestone m) async => m;
  @override Future<void> deleteMilestone(String id) async {}
}
