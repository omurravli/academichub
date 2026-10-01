import 'package:studiq/features/planner/domain/entities/planner_item.dart';

/// TODO: Implement with Firebase / Supabase / REST when backend is ready
abstract class PlannerRemoteDataSource {
  Future<List<PlannerItem>> getAll();
  Future<PlannerItem?> getById(String id);
  Future<PlannerItem> create(PlannerItem item);
  Future<PlannerItem> update(PlannerItem item);
  Future<void> delete(String id);
  Stream<List<PlannerItem>> watchAll();
}
