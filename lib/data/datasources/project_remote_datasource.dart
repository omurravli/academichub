import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';

/// TODO: Implement with Firebase / Supabase / REST when backend is ready
abstract class ProjectRemoteDataSource {
  Future<List<Project>> getAll();
  Future<Project?> getById(String id);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
  Future<void> delete(String id);
  Stream<List<Project>> watchAll();
  Future<List<Milestone>> getMilestones(String projectId);
}
