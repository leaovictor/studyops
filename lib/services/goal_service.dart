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
    // Note: In a real app, we might want to delete all related subjects/topics/cards.
    // For now, we follow the user request which is more about filtering.
    // But we should consider if subjects without a goal should be cleaned up.
    await _goals.doc(goalId).delete();
  }

  Future<List<Goal>> getGoalsOnce(String userId) async {
    final snap = await _goals.where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => Goal.fromDoc(d)).toList();
  }
}
