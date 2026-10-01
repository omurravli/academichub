import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:studiq/features/projects/domain/entities/milestone.dart';
import 'package:studiq/features/projects/domain/entities/project.dart';

class ProjectFirestoreDataSource {
  final String uid;

  ProjectFirestoreDataSource(this.uid);

  CollectionReference<Map<String, dynamic>> get _projects =>
      FirebaseFirestore.instance.collection('users/$uid/projects');

  CollectionReference<Map<String, dynamic>> get _milestones =>
      FirebaseFirestore.instance.collection('users/$uid/milestones');

  // ── Projects ──────────────────────────────────────────────────────────────

  Future<List<Project>> getAll() async {
    final snap = await _projects.where('deletedAt', isNull: true).get();
    return snap.docs.map((d) => _projectFromDoc(d.data())).toList();
  }

  Future<List<Project>> getDeleted() async {
    final snap = await _projects.where('deletedAt', isNull: false).get();
    return snap.docs.map((d) => _projectFromDoc(d.data())).toList();
  }

  Future<Project?> getById(String id) async {
    final doc = await _projects.doc(id).get();
    if (!doc.exists) return null;
    return _projectFromDoc(doc.data()!);
  }

  Stream<List<Project>> watchAll() async* {
    yield await getAll();
  }

  Future<void> insert(Project project) =>
      _projects.doc(project.id).set(_projectToDoc(project));

  Future<void> update(Project project) =>
      _projects.doc(project.id).set(_projectToDoc(project));

  Future<void> softDelete(String id) =>
      _projects.doc(id).update({'deletedAt': Timestamp.now()});

  Future<void> restore(String id) =>
      _projects.doc(id).update({'deletedAt': null});

  Future<void> delete(String id) => _projects.doc(id).delete();

  // ── Milestones ────────────────────────────────────────────────────────────

  Future<List<Milestone>> getMilestones(String projectId) async {
    final snap =
        await _milestones.where('projectId', isEqualTo: projectId).get();
    return snap.docs.map((d) => _milestoneFromDoc(d.data())).toList();
  }

  Future<void> insertMilestone(Milestone m) =>
      _milestones.doc(m.id).set(_milestoneToDoc(m));

  Future<void> updateMilestone(Milestone m) =>
      _milestones.doc(m.id).set(_milestoneToDoc(m));

  Future<void> deleteMilestone(String id) => _milestones.doc(id).delete();

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> _projectToDoc(Project p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'colorValue': p.color.toARGB32(),
        'status': p.status.name,
        'dueDate': p.dueDate != null ? Timestamp.fromDate(p.dueDate!) : null,
        'progress': p.progress,
        'createdAt': Timestamp.fromDate(p.createdAt),
        'updatedAt': Timestamp.fromDate(p.updatedAt),
        'deletedAt':
            p.deletedAt != null ? Timestamp.fromDate(p.deletedAt!) : null,
      };

  Project _projectFromDoc(Map<String, dynamic> d) => Project(
        id: d['id'] as String,
        title: d['title'] as String,
        description: d['description'] as String?,
        color: Color(d['colorValue'] as int),
        status:
            ProjectStatus.values.byName(d['status'] as String? ?? 'inProgress'),
        dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
        progress: (d['progress'] as num? ?? 0.0).toDouble(),
        createdAt: (d['createdAt'] as Timestamp).toDate(),
        updatedAt: (d['updatedAt'] as Timestamp).toDate(),
        deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> _milestoneToDoc(Milestone m) => {
        'id': m.id,
        'projectId': m.projectId,
        'title': m.title,
        'dueDate': m.dueDate != null ? Timestamp.fromDate(m.dueDate!) : null,
        'completed': m.completed,
        'createdAt': Timestamp.fromDate(m.createdAt),
      };

  Milestone _milestoneFromDoc(Map<String, dynamic> d) => Milestone(
        id: d['id'] as String,
        projectId: d['projectId'] as String,
        title: d['title'] as String,
        dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
        completed: d['completed'] as bool? ?? false,
        createdAt: (d['createdAt'] as Timestamp).toDate(),
      );
}
