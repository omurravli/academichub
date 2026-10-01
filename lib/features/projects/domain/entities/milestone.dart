import 'package:equatable/equatable.dart';

class Milestone extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final DateTime? dueDate;
  final bool completed;
  final DateTime createdAt;

  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    this.dueDate,
    this.completed = false,
    required this.createdAt,
  });

  Milestone copyWith({
    String? id,
    String? projectId,
    String? title,
    DateTime? dueDate,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Milestone(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, projectId, title, dueDate, completed, createdAt];
}
