import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/constants/app_constants.dart';

class SubjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _subjects => _db.collection(AppConstants.colSubjects);
  CollectionReference get _topics => _db.collection(AppConstants.colTopics);

  // ── Subjects ──────────────────────────────────

  Stream<List<Subject>> watchSubjects(String userId) {
    return _subjects.where('userId', isEqualTo: userId).snapshots().map(
        (snap) => snap.docs.map((d) => Subject.fromDoc(d)).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority)));
  }

  Future<Subject> createSubject(Subject subject) async {
    final ref = await _subjects.add(subject.toMap());
    return subject.copyWith(id: ref.id);
  }

  /// Creates a subject with a pre-determined ID (used during onboarding).
  Future<Subject> createSubjectWithId(Subject subject) async {
    await _subjects.doc(subject.id).set(subject.toMap());
    return subject;
  }

  /// Creates a default "Geral" topic for a subject.
  Future<Topic> createDefaultTopic(String subjectId) async {
    const topic = Topic(id: '', subjectId: '', name: 'Geral', difficulty: 2);
    final ref = await _topics.add({
      'subjectId': subjectId,
      'name': 'Geral',
      'difficulty': 2,
    });
    return topic.copyWith(id: ref.id, subjectId: subjectId);
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjects.doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String subjectId) async {
    // Also delete all topics in this subject
    final topicSnap =
        await _topics.where('subjectId', isEqualTo: subjectId).get();
    final batch = _db.batch();
    for (final doc in topicSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_subjects.doc(subjectId));
    await batch.commit();
  }

  // ── Topics ──────────────────────────────────

  Stream<List<Topic>> watchTopics(String subjectId) {
    return _topics.where('subjectId', isEqualTo: subjectId).snapshots().map(
        (snap) => snap.docs.map((d) => Topic.fromDoc(d)).toList()
          ..sort((a, b) => b.difficulty.compareTo(a.difficulty)));
  }

  Stream<List<Topic>> watchAllTopicsForUser(
      String userId, List<String> subjectIds) {
    if (subjectIds.isEmpty) return Stream.value([]);
    return _topics
        .where('subjectId', whereIn: subjectIds)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Topic.fromDoc(d)).toList());
  }

  Future<Topic> createTopic(Topic topic) async {
    final ref = await _topics.add(topic.toMap());
    return topic.copyWith(id: ref.id);
  }

  Future<void> updateTopic(Topic topic) async {
    await _topics.doc(topic.id).update(topic.toMap());
  }

  Future<void> deleteTopic(String topicId) async {
    await _topics.doc(topicId).delete();
  }

  Future<List<Topic>> getTopicsForSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) return [];
    final snap = await _topics.where('subjectId', whereIn: subjectIds).get();
    return snap.docs.map((d) => Topic.fromDoc(d)).toList();
  }
}
