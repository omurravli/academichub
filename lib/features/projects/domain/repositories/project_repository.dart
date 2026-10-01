import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAll();
  Future<Project?> getById(String id);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<void> delete(String id);
  Future<List<Project>> getDeleted();
  Stream<List<Project>> watchAll();

  // Milestones
  Future<List<Milestone>> getMilestones(String projectId);
  Future<Milestone> createMilestone(Milestone milestone);
  Future<Milestone> updateMilestone(Milestone milestone);
  Future<void> deleteMilestone(String id);
}
