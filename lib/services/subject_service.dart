import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/constants/app_constants.dart';

class SubjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _subjects => _db.collection(AppConstants.colSubjects);
  CollectionReference get _topics => _db.collection(AppConstants.colTopics);

  // ── Subjects ──────────────────────────────────

  Stream<List<Subject>> watchSubjects(String userId, {String? goalId}) {
    Query query = _subjects.where('userId', isEqualTo: userId);
    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Subject.fromDoc(d)).toList()
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
  Future<Topic> createDefaultTopic(String userId, String subjectId) async {
    const topic =
        Topic(id: '', userId: '', subjectId: '', name: 'Geral', difficulty: 2);
    final ref = await _topics.add({
      'userId': userId,
      'subjectId': subjectId,
      'name': 'Geral',
      'difficulty': 2,
    });
    return topic.copyWith(id: ref.id, userId: userId, subjectId: subjectId);
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjects.doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String userId, String subjectId) async {
    final batch = _db.batch();

    // 1. Delete all topics
    final topicSnap = await _topics
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final doc in topicSnap.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete all flashcards
    final cardSnap = await _db
        .collection(AppConstants.colFlashcards)
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final doc in cardSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all error notes
    final errorSnap = await _db
        .collection(AppConstants.colErrorNotebook)
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final doc in errorSnap.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete all study logs
    final logSnap = await _db
        .collection(AppConstants.colStudyLogs)
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final doc in logSnap.docs) {
      batch.delete(doc.reference);
    }

    // 5. Delete all daily tasks
    final taskSnap = await _db
        .collection(AppConstants.colDailyTasks)
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .get();
    for (final doc in taskSnap.docs) {
      batch.delete(doc.reference);
    }

    // 6. Delete all FSRS Review Logs
    final fsrsSnap = await _db
        .collection('fsrs_review_logs')
        .where('subjectId', isEqualTo: subjectId)
        .get(); // FSRS Review Logs has general authenticated access, no userId filter required for rules.
    for (final doc in fsrsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 7. Delete the subject itself
    batch.delete(_subjects.doc(subjectId));

    await batch.commit();
  }

  // ── Topics ──────────────────────────────────

  Stream<List<Topic>> watchTopics(String userId, String subjectId) {
    return _topics
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Topic.fromDoc(d)).toList()
          ..sort((a, b) => b.difficulty.compareTo(a.difficulty)));
  }

  Stream<List<Topic>> watchAllTopicsForUser(
      String userId, List<String> subjectIds) {
    if (subjectIds.isEmpty) return Stream.value([]);
    return _topics
        .where('userId', isEqualTo: userId)
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

  Future<List<Topic>> getTopicsForSubjects(
      String userId, List<String> subjectIds) async {
    if (subjectIds.isEmpty) return [];
    final snap = await _topics
        .where('userId', isEqualTo: userId)
        .where('subjectId', whereIn: subjectIds)
        .get();
    return snap.docs.map((d) => Topic.fromDoc(d)).toList();
  }
}
