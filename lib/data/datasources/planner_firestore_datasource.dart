import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';

class PlannerFirestoreDataSource {
  final String uid;

  PlannerFirestoreDataSource(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users/$uid/planner_items');

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<PlannerItem>> getAll() async {
    final snap = await _col.where('deletedAt', isNull: true).get();
    return snap.docs.map((d) => _fromDoc(d.data())).toList();
  }

  Future<List<PlannerItem>> getDeleted() async {
    final snap = await _col.where('deletedAt', isNull: false).get();
    return snap.docs.map((d) => _fromDoc(d.data())).toList();
  }

  Future<List<PlannerItem>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    final all = await getAll();
    return all.where((item) {
      final d = item.dueDate ?? item.startDateTime;
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Future<List<PlannerItem>> getByProject(String projectId) async {
    final snap = await _col.where('projectId', isEqualTo: projectId).get();
    return snap.docs.map((d) => _fromDoc(d.data())).toList();
  }

  Future<PlannerItem?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return _fromDoc(doc.data()!);
  }

  Stream<List<PlannerItem>> watchAll() async* {
    yield await getAll();
  }

  Stream<List<PlannerItem>> watchByDate(DateTime date) async* {
    yield await getByDate(date);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> insert(PlannerItem item) =>
      _col.doc(item.id).set(_toDoc(item));

  Future<void> update(PlannerItem item) =>
      _col.doc(item.id).set(_toDoc(item));

  Future<void> softDelete(String id) =>
      _col.doc(id).update({'deletedAt': Timestamp.now()});

  Future<void> restore(String id) =>
      _col.doc(id).update({'deletedAt': null});

  Future<void> delete(String id) => _col.doc(id).delete();

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> _toDoc(PlannerItem item) => {
        'id': item.id,
        'title': item.title,
        'description': item.description,
        'type': item.type.name,
        'startDateTime': item.startDateTime != null
            ? Timestamp.fromDate(item.startDateTime!)
            : null,
        'endDateTime': item.endDateTime != null
            ? Timestamp.fromDate(item.endDateTime!)
            : null,
        'dueDate':
            item.dueDate != null ? Timestamp.fromDate(item.dueDate!) : null,
        'priority': item.priority.name,
        'status': item.status.name,
        'projectId': item.projectId,
        'recurrence':
            item.recurrence != null ? _recurrenceToMap(item.recurrence!) : null,
        'reminder':
            item.reminder != null ? _reminderToMap(item.reminder!) : null,
        'tags': item.tags,
        'createdAt': Timestamp.fromDate(item.createdAt),
        'updatedAt': Timestamp.fromDate(item.updatedAt),
        'deletedAt':
            item.deletedAt != null ? Timestamp.fromDate(item.deletedAt!) : null,
      };

  PlannerItem _fromDoc(Map<String, dynamic> d) => PlannerItem(
        id: d['id'] as String,
        title: d['title'] as String,
        description: d['description'] as String?,
        type: PlannerItemType.values.byName(d['type'] as String),
        startDateTime: (d['startDateTime'] as Timestamp?)?.toDate(),
        endDateTime: (d['endDateTime'] as Timestamp?)?.toDate(),
        dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
        priority: PlannerItemPriority.values
            .byName(d['priority'] as String? ?? 'medium'),
        status:
            PlannerItemStatus.values.byName(d['status'] as String? ?? 'todo'),
        projectId: d['projectId'] as String?,
        recurrence: d['recurrence'] != null
            ? _recurrenceFromMap(d['recurrence'] as Map<String, dynamic>)
            : null,
        reminder: d['reminder'] != null
            ? _reminderFromMap(d['reminder'] as Map<String, dynamic>)
            : null,
        tags: List<String>.from(d['tags'] as List? ?? []),
        createdAt: (d['createdAt'] as Timestamp).toDate(),
        updatedAt: (d['updatedAt'] as Timestamp).toDate(),
        deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> _recurrenceToMap(RecurrenceRule r) => {
        'frequency': r.frequency.name,
        'interval': r.interval,
        'until':
            r.until != null ? Timestamp.fromDate(r.until!) : null,
        'count': r.count,
        'byDay': r.byDay,
        'byMonth': r.byMonth,
      };

  RecurrenceRule _recurrenceFromMap(Map<String, dynamic> m) => RecurrenceRule(
        frequency: RecurrenceFrequency.values.byName(m['frequency'] as String),
        interval: m['interval'] as int? ?? 1,
        until: (m['until'] as Timestamp?)?.toDate(),
        count: m['count'] as int?,
        byDay: m['byDay'] != null ? List<int>.from(m['byDay'] as List) : null,
        byMonth:
            m['byMonth'] != null ? List<int>.from(m['byMonth'] as List) : null,
      );

  Map<String, dynamic> _reminderToMap(ReminderConfig r) =>
      {'minutesBefore': r.minutesBefore, 'enabled': r.enabled};

  ReminderConfig _reminderFromMap(Map<String, dynamic> m) => ReminderConfig(
      minutesBefore: m['minutesBefore'] as int,
      enabled: m['enabled'] as bool? ?? true);
}
