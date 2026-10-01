import 'package:equatable/equatable.dart';

enum PlannerItemType { task, meeting, exam, deadline, reminder, event }

enum PlannerItemPriority { low, medium, high, urgent }

enum PlannerItemStatus { todo, inProgress, done, cancelled }

/// Recurrence rule
class RecurrenceRule extends Equatable {
  final RecurrenceFrequency frequency;
  final int interval; // every N frequency units
  final DateTime? until;
  final int? count;
  final List<int>? byDay; // 1=Mon…7=Sun
  final List<int>? byMonth;

  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byDay,
    this.byMonth,
  });

  @override
  List<Object?> get props =>
      [frequency, interval, until, count, byDay, byMonth];
}

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Reminder configuration attached to a planner item
class ReminderConfig extends Equatable {
  final int minutesBefore;
  final bool enabled;

  const ReminderConfig({required this.minutesBefore, this.enabled = true});

  @override
  List<Object?> get props => [minutesBefore, enabled];
}

/// Core domain entity — no Drift/database imports
class PlannerItem extends Equatable {
  final String id;
  final String title;
  final String? description;
  final PlannerItemType type;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? dueDate;
  final PlannerItemPriority priority;
  final PlannerItemStatus status;
  final String? projectId;
  final RecurrenceRule? recurrence;
  final ReminderConfig? reminder;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PlannerItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.startDateTime,
    this.endDateTime,
    this.dueDate,
    this.priority = PlannerItemPriority.medium,
    this.status = PlannerItemStatus.todo,
    this.projectId,
    this.recurrence,
    this.reminder,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  PlannerItem copyWith({
    String? id,
    String? title,
    String? description,
    PlannerItemType? type,
    DateTime? startDateTime,
    DateTime? endDateTime,
    DateTime? dueDate,
    PlannerItemPriority? priority,
    PlannerItemStatus? status,
    String? projectId,
    RecurrenceRule? recurrence,
    ReminderConfig? reminder,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _sentinel,
  }) {
    return PlannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      recurrence: recurrence ?? this.recurrence,
      reminder: reminder ?? this.reminder,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  static const Object _sentinel = Object();

  bool get isCompleted => status == PlannerItemStatus.done;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isCompleted;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [
        id, title, description, type, startDateTime, endDateTime,
        dueDate, priority, status, projectId, recurrence, reminder,
        tags, createdAt, updatedAt, deletedAt,
      ];
}
