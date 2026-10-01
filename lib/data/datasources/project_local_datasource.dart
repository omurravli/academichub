import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:studiq/data/database/app_database.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';

class ProjectLocalDataSource {
  final AppDatabase _db;
  ProjectLocalDataSource(this._db);

  static const _projects = 'projects';
  static const _milestones = 'milestones';

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<List<Project>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      _projects,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(_projectFromRow).toList();
  }

  Future<List<Project>> getDeleted() async {
    final db = await _db.database;
    final rows = await db.query(
      _projects,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(_projectFromRow).toList();
  }

  Future<Project?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query(_projects, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _projectFromRow(rows.first);
  }

  Stream<List<Project>> watchAll() async* {
    yield await getAll();
  }

  Future<void> insert(Project project) async {
    final db = await _db.database;
    await db.insert(_projects, _projectToRow(project),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(Project project) async {
    final db = await _db.database;
    await db.update(_projects, _projectToRow(project),
        where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> softDelete(String id) async {
    final db = await _db.database;
    await db.update(
      _projects,
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _db.database;
    await db.update(
      _projects,
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_projects, where: 'id = ?', whereArgs: [id]);
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  Future<List<Milestone>> getMilestones(String projectId) async {
    final db = await _db.database;
    final rows = await db.query(_milestones,
        where: 'project_id = ?', whereArgs: [projectId]);
    return rows.map(_milestoneFromRow).toList();
  }

  Future<void> insertMilestone(Milestone m) async {
    final db = await _db.database;
    await db.insert(_milestones, _milestoneToRow(m),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateMilestone(Milestone m) async {
    final db = await _db.database;
    await db.update(_milestones, _milestoneToRow(m),
        where: 'id = ?', whereArgs: [m.id]);
  }

  Future<void> deleteMilestone(String id) async {
    final db = await _db.database;
    await db.delete(_milestones, where: 'id = ?', whereArgs: [id]);
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _projectToRow(Project p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'color_value': p.color.value,
        'status': p.status.name,
        'due_date': p.dueDate?.millisecondsSinceEpoch,
        'progress': p.progress,
        'created_at': p.createdAt.millisecondsSinceEpoch,
        'updated_at': p.updatedAt.millisecondsSinceEpoch,
        'deleted_at': p.deletedAt?.millisecondsSinceEpoch,
      };

  Project _projectFromRow(Map<String, dynamic> row) => Project(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        color: Color(row['color_value'] as int),
        status: ProjectStatus.values.byName(row['status'] as String),
        dueDate: row['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int)
            : null,
        progress: (row['progress'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row['updated_at'] as int),
        deletedAt: row['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
            : null,
      );

  Map<String, dynamic> _milestoneToRow(Milestone m) => {
        'id': m.id,
        'project_id': m.projectId,
        'title': m.title,
        'due_date': m.dueDate?.millisecondsSinceEpoch,
        'completed': m.completed ? 1 : 0,
        'created_at': m.createdAt.millisecondsSinceEpoch,
      };

  Milestone _milestoneFromRow(Map<String, dynamic> row) => Milestone(
        id: row['id'] as String,
        projectId: row['project_id'] as String,
        title: row['title'] as String,
        dueDate: row['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int)
            : null,
        completed: (row['completed'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int),
      );
}
