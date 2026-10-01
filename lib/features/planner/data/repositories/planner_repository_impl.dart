import 'package:uuid/uuid.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/planner/domain/repositories/planner_repository.dart';
import 'package:studiq/data/datasources/planner_firestore_datasource.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerFirestoreDataSource _remote;
  static const _uuid = Uuid();

  PlannerRepositoryImpl(this._remote);

  @override
  Future<List<PlannerItem>> getAll() => _remote.getAll();

  @override
  Future<List<PlannerItem>> getByDate(DateTime date) =>
      _remote.getByDate(date);

  @override
  Future<List<PlannerItem>> getByProject(String projectId) =>
      _remote.getByProject(projectId);

  @override
  Future<PlannerItem?> getById(String id) => _remote.getById(id);

  @override
  Future<PlannerItem> create(PlannerItem item) async {
    final now = DateTime.now();
    final newItem = item.copyWith(
      id: item.id.isEmpty ? _uuid.v4() : item.id,
      createdAt: now,
      updatedAt: now,
    );
    await _remote.insert(newItem);
    return newItem;
  }

  @override
  Future<PlannerItem> update(PlannerItem item) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
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
  Future<List<PlannerItem>> getDeleted() => _remote.getDeleted();

  @override
  Stream<List<PlannerItem>> watchAll() => _remote.watchAll();

  @override
  Stream<List<PlannerItem>> watchByDate(DateTime date) =>
      _remote.watchByDate(date);
}
