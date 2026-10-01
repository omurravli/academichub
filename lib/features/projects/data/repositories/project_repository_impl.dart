import 'package:uuid/uuid.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';
import 'package:studiq/features/projects/domain/repositories/project_repository.dart';
import 'package:studiq/data/datasources/project_firestore_datasource.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectFirestoreDataSource _remote;
  static const _uuid = Uuid();

  ProjectRepositoryImpl(this._remote);

  @override
  Future<List<Project>> getAll() => _remote.getAll();

  @override
  Future<Project?> getById(String id) => _remote.getById(id);

  @override
  Future<Project> create(Project project) async {
    final now = DateTime.now();
    final newProject = project.copyWith(
      id: project.id.isEmpty ? _uuid.v4() : project.id,
      createdAt: now,
      updatedAt: now,
    );
    await _remote.insert(newProject);
    return newProject;
  }

  @override
  Future<Project> update(Project project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    await _remote.update(updated);
    return updated;
  }

  @override
  Future<void> softDelete(String id) => _remote.softDelete(id);

  @override
  Future<void> restore(String id) => _remote.restore(id);

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<List<Project>> getDeleted() => _remote.getDeleted();

  @override
  Stream<List<Project>> watchAll() => _remote.watchAll();

  @override
  Future<List<Milestone>> getMilestones(String projectId) =>
      _remote.getMilestones(projectId);

  @override
  Future<Milestone> createMilestone(Milestone milestone) async {
    final m = milestone.copyWith(
      id: milestone.id.isEmpty ? _uuid.v4() : milestone.id,
      createdAt: DateTime.now(),
    );
    await _remote.insertMilestone(m);
    return m;
  }

  @override
  Future<Milestone> updateMilestone(Milestone milestone) async {
    await _remote.updateMilestone(milestone);
    return milestone;
  }

  @override
  Future<void> deleteMilestone(String id) => _remote.deleteMilestone(id);
}
