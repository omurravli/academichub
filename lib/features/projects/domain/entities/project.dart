import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ProjectStatus { planning, inProgress, onHold, completed, cancelled }

class Project extends Equatable {
  final String id;
  final String title;
  final String? description;
  final Color color;
  final ProjectStatus status;
  final DateTime? dueDate;
  final double progress; // 0.0 – 1.0
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Project({
    required this.id,
    required this.title,
    this.description,
    required this.color,
    this.status = ProjectStatus.inProgress,
    this.dueDate,
    this.progress = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Project copyWith({
    String? id,
    String? title,
    String? description,
    Color? color,
    ProjectStatus? status,
    DateTime? dueDate,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? deletedAt = _sentinel,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt == _sentinel ? this.deletedAt : deletedAt as DateTime?,
    );
  }

  static const Object _sentinel = Object();

  int get progressPercent => (progress * 100).round();
  bool get isCompleted => status == ProjectStatus.completed;
  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props =>
      [id, title, description, color, status, dueDate, progress, createdAt, updatedAt, deletedAt];
}
