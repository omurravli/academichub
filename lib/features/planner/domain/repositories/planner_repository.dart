import 'package:studiq/features/planner/domain/entities/planner_item.dart';

abstract class PlannerRepository {
  Future<List<PlannerItem>> getAll();
  Future<List<PlannerItem>> getByDate(DateTime date);
  Future<List<PlannerItem>> getByProject(String projectId);
  Future<PlannerItem?> getById(String id);
  Future<PlannerItem> create(PlannerItem item);
  Future<PlannerItem> update(PlannerItem item);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<void> delete(String id);
  Future<List<PlannerItem>> getDeleted();
  Stream<List<PlannerItem>> watchAll();
  Stream<List<PlannerItem>> watchByDate(DateTime date);
}
