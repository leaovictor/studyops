import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal_model.dart';
import '../core/constants/app_constants.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _goals => _db.collection(AppConstants.colGoals);

  Stream<List<Goal>> watchGoals(String userId) {
    return _goals
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Goal.fromDoc(d)).toList());
  }

  Future<Goal> createGoal(Goal goal) async {
    final ref = await _goals.add(goal.toMap());
    return goal.copyWith(id: ref.id);
  }

  Future<void> updateGoal(Goal goal) async {
    await _goals.doc(goal.id).update(goal.toMap());
  }

  Future<void> deleteGoal(String goalId) async {
    final batch = _db.batch();

    // 1. Get and delete all subjects
    final subjectSnap = await _db
        .collection(AppConstants.colSubjects)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in subjectSnap.docs) {
      batch.delete(doc.reference);

      // Also delete topics for these subjects (since topics don't have goalId)
      final topicSnap = await _db
          .collection(AppConstants.colTopics)
          .where('subjectId', isEqualTo: doc.id)
          .get();
      for (final tDoc in topicSnap.docs) {
        batch.delete(tDoc.reference);
      }
    }

    // 2. Delete all flashcards
    final cardSnap = await _db
        .collection(AppConstants.colFlashcards)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in cardSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all error notebook entries
    final errorSnap = await _db
        .collection(AppConstants.colErrorNotebook)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in errorSnap.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete all study logs
    final logSnap = await _db
        .collection(AppConstants.colStudyLogs)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in logSnap.docs) {
      batch.delete(doc.reference);
    }

    // 5. Delete all study plans
    final planSnap = await _db
        .collection(AppConstants.colStudyPlans)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in planSnap.docs) {
      batch.delete(doc.reference);
    }

    // 6. Delete all daily tasks
    final taskSnap = await _db
        .collection(AppConstants.colDailyTasks)
        .where('goalId', isEqualTo: goalId)
        .get();
    for (final doc in taskSnap.docs) {
      batch.delete(doc.reference);
    }

    // 7. Delete the goal itself
    batch.delete(_goals.doc(goalId));

    await batch.commit();
  }

  Future<List<Goal>> getGoalsOnce(String userId) async {
    final snap = await _goals.where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => Goal.fromDoc(d)).toList();
  }
}
