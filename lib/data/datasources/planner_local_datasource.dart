import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:studiq/data/database/app_database.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';

class PlannerLocalDataSource {
  final AppDatabase _db;
  PlannerLocalDataSource(this._db);

  static const _table = 'planner_items';

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<PlannerItem>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<PlannerItem>> getDeleted() async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<PlannerItem>> getByDate(DateTime date) async {
    final db = await _db.database;
    final start = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    final rows = await db.query(
      _table,
      where:
          '(due_date BETWEEN ? AND ?) OR (start_date_time BETWEEN ? AND ?)',
      whereArgs: [start, end, start, end],
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<PlannerItem>> getByProject(String projectId) async {
    final db = await _db.database;
    final rows = await db.query(
      _table,
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    return rows.map(_fromRow).toList();
  }

  Future<PlannerItem?> getById(String id) async {
    final db = await _db.database;
    final rows =
        await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Stream<List<PlannerItem>> watchAll() async* {
    yield await getAll();
  }

  Stream<List<PlannerItem>> watchByDate(DateTime date) async* {
    yield await getByDate(date);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> insert(PlannerItem item) async {
    final db = await _db.database;
    await db.insert(_table, _toRow(item),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(PlannerItem item) async {
    final db = await _db.database;
    await db.update(_table, _toRow(item),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> softDelete(String id) async {
    final db = await _db.database;
    await db.update(
      _table,
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restore(String id) async {
    final db = await _db.database;
    await db.update(
      _table,
      {'deleted_at': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(PlannerItem item) => {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'type': item.type.name,
        'start_date_time': item.startDateTime?.millisecondsSinceEpoch,
        'end_date_time': item.endDateTime?.millisecondsSinceEpoch,
        'due_date': item.dueDate?.millisecondsSinceEpoch,
        'priority': item.priority.name,
        'status': item.status.name,
        'project_id': item.projectId,
        'recurrence_json': item.recurrence != null
            ? jsonEncode(_recurrenceToJson(item.recurrence!))
            : null,
        'reminder_json': item.reminder != null
            ? jsonEncode(_reminderToJson(item.reminder!))
            : null,
        'tags_json': jsonEncode(item.tags),
        'created_at': item.createdAt.millisecondsSinceEpoch,
        'updated_at': item.updatedAt.millisecondsSinceEpoch,
        'deleted_at': item.deletedAt?.millisecondsSinceEpoch,
      };

  PlannerItem _fromRow(Map<String, dynamic> row) => PlannerItem(
        id: row['id'] as String,
        title: row['title'] as String,
        description: row['description'] as String?,
        type: PlannerItemType.values.byName(row['type'] as String),
        startDateTime: row['start_date_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                row['start_date_time'] as int)
            : null,
        endDateTime: row['end_date_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                row['end_date_time'] as int)
            : null,
        dueDate: row['due_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int)
            : null,
        priority:
            PlannerItemPriority.values.byName(row['priority'] as String),
        status: PlannerItemStatus.values.byName(row['status'] as String),
        projectId: row['project_id'] as String?,
        recurrence: row['recurrence_json'] != null
            ? _recurrenceFromJson(
                jsonDecode(row['recurrence_json'] as String))
            : null,
        reminder: row['reminder_json'] != null
            ? _reminderFromJson(
                jsonDecode(row['reminder_json'] as String))
            : null,
        tags: List<String>.from(
            jsonDecode(row['tags_json'] as String? ?? '[]')),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row['updated_at'] as int),
        deletedAt: row['deleted_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['deleted_at'] as int)
            : null,
      );

  Map<String, dynamic> _recurrenceToJson(RecurrenceRule r) => {
        'frequency': r.frequency.name,
        'interval': r.interval,
        'until': r.until?.millisecondsSinceEpoch,
        'count': r.count,
        'byDay': r.byDay,
        'byMonth': r.byMonth,
      };

  RecurrenceRule _recurrenceFromJson(Map<String, dynamic> j) =>
      RecurrenceRule(
        frequency: RecurrenceFrequency.values.byName(j['frequency']),
        interval: j['interval'] ?? 1,
        until: j['until'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['until'])
            : null,
        count: j['count'],
        byDay: j['byDay'] != null ? List<int>.from(j['byDay']) : null,
        byMonth:
            j['byMonth'] != null ? List<int>.from(j['byMonth']) : null,
      );

  Map<String, dynamic> _reminderToJson(ReminderConfig r) =>
      {'minutesBefore': r.minutesBefore, 'enabled': r.enabled};

  ReminderConfig _reminderFromJson(Map<String, dynamic> j) =>
      ReminderConfig(
          minutesBefore: j['minutesBefore'], enabled: j['enabled'] ?? true);
}

