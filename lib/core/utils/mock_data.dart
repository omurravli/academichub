import 'package:flutter/material.dart';
import 'package:studiq/features/planner/domain/entities/planner_item.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';

abstract class MockData {
  static final now = DateTime.now();

  // ── Planner items ─────────────────────────────────────────────────────────

  static List<PlannerItem> plannerItems() => [
        PlannerItem(
          id: 'item-1',
          title: 'Research Methods Lecture',
          description: 'Weekly lecture on quantitative methods — Room B204',
          type: PlannerItemType.event,
          startDateTime: DateTime(now.year, now.month, now.day, 9, 0),
          endDateTime: DateTime(now.year, now.month, now.day, 10, 30),
          priority: PlannerItemPriority.medium,
          status: PlannerItemStatus.todo,
          recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
          reminder: const ReminderConfig(minutesBefore: 15),
          tags: ['lecture', 'HCI'],
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
        PlannerItem(
          id: 'item-2',
          title: 'Thesis Supervisor Meeting',
          description: 'Weekly 1:1 with Dr. Williams to review chapter progress',
          type: PlannerItemType.meeting,
          startDateTime: DateTime(now.year, now.month, now.day, 11, 0),
          endDateTime: DateTime(now.year, now.month, now.day, 12, 0),
          priority: PlannerItemPriority.high,
          status: PlannerItemStatus.todo,
          projectId: 'proj-1',
          reminder: const ReminderConfig(minutesBefore: 10),
          tags: ['thesis', 'meeting'],
          createdAt: now.subtract(const Duration(days: 3)),
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
        PlannerItem(
          id: 'item-3',
          title: 'Bio 301 Lab Report Draft',
          description: 'Complete the experimental analysis section for Lab #4',
          type: PlannerItemType.deadline,
          dueDate: now.add(const Duration(days: 1)),
          priority: PlannerItemPriority.urgent,
          status: PlannerItemStatus.inProgress,
          projectId: 'proj-2',
          reminder: const ReminderConfig(minutesBefore: 60),
          tags: ['biology', 'lab'],
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        PlannerItem(
          id: 'item-4',
          title: 'Cognitive Load Theory — Chapter 3',
          description: 'Read and annotate chapters 3-4 for thesis background',
          type: PlannerItemType.task,
          dueDate: DateTime(now.year, now.month, now.day, 17, 0),
          priority: PlannerItemPriority.medium,
          status: PlannerItemStatus.todo,
          projectId: 'proj-1',
          tags: ['reading', 'thesis'],
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        PlannerItem(
          id: 'item-5',
          title: 'HCI Mid-term Exam',
          description: 'Covers weeks 1-7: usability, evaluation methods, design heuristics',
          type: PlannerItemType.exam,
          startDateTime: now.add(const Duration(days: 5, hours: 9)),
          endDateTime: now.add(const Duration(days: 5, hours: 12)),
          dueDate: now.add(const Duration(days: 5)),
          priority: PlannerItemPriority.urgent,
          status: PlannerItemStatus.todo,
          reminder: const ReminderConfig(minutesBefore: 60),
          tags: ['exam', 'HCI'],
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
        ),
        PlannerItem(
          id: 'item-6',
          title: 'Study Session — AI Ethics',
          description: 'Group study at library for group presentation prep',
          type: PlannerItemType.task,
          startDateTime: DateTime(now.year, now.month, now.day, 15, 0),
          endDateTime: DateTime(now.year, now.month, now.day, 17, 0),
          priority: PlannerItemPriority.medium,
          status: PlannerItemStatus.done,
          projectId: 'proj-3',
          recurrence: const RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            byDay: [3], // Wednesday
          ),
          tags: ['study', 'group'],
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

  // ── Projects ──────────────────────────────────────────────────────────────

  static List<Project> projects() => [
        Project(
          id: 'proj-1',
          title: 'Senior Thesis: Cognitive Load in Digital Interfaces',
          description: 'Research and writing for final year HCI thesis project.',
          color: const Color(0xFF0058BE), // primary blue
          status: ProjectStatus.inProgress,
          dueDate: DateTime(now.year, 12, 15),
          progress: 0.65,
          createdAt: now.subtract(const Duration(days: 90)),
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        Project(
          id: 'proj-2',
          title: 'Bio 301 Lab Reports',
          description: 'Weekly experimental write-ups and data analysis.',
          color: const Color(0xFF006C49), // secondary green
          status: ProjectStatus.inProgress,
          dueDate: now.add(const Duration(days: 1)),
          progress: 0.40,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        Project(
          id: 'proj-3',
          title: 'Group Presentation: Ethics in AI',
          description: 'Coordinate slides and speaking notes with Sarah and Mark.',
          color: const Color(0xFF6B38D4), // tertiary purple
          status: ProjectStatus.planning,
          dueDate: DateTime(now.year, 11, 22),
          progress: 0.15,
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
      ];

  // ── Milestones ────────────────────────────────────────────────────────────

  static List<Milestone> milestones() => [
        Milestone(
          id: 'ms-1',
          projectId: 'proj-1',
          title: 'Literature Review Complete',
          dueDate: now.subtract(const Duration(days: 14)),
          completed: true,
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        Milestone(
          id: 'ms-2',
          projectId: 'proj-1',
          title: 'Research Methodology Draft',
          dueDate: now.add(const Duration(days: 7)),
          completed: false,
          createdAt: now.subtract(const Duration(days: 90)),
        ),
        Milestone(
          id: 'ms-3',
          projectId: 'proj-1',
          title: 'First Full Draft',
          dueDate: DateTime(now.year, 11, 30),
          completed: false,
          createdAt: now.subtract(const Duration(days: 90)),
        ),
      ];
}
