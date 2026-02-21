import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_plan_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/schedule_generator.dart';

class StudyPlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _plans => _db.collection(AppConstants.colStudyPlans);
  CollectionReference get _tasks => _db.collection(AppConstants.colDailyTasks);

  Stream<StudyPlan?> watchActivePlan(String userId) {
    return _plans
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : StudyPlan.fromDoc(snap.docs.first));
  }

  Future<StudyPlan> createPlan(StudyPlan plan) async {
    final ref = await _plans.add(plan.toMap());
    return plan.copyWith(id: ref.id);
  }

  Future<void> updatePlan(StudyPlan plan) async {
    await _plans.doc(plan.id).update(plan.toMap());
  }

  Future<void> deletePlan(String planId) async {
    await _plans.doc(planId).delete();
  }

  /// Generates daily tasks for the plan and saves them in batches.
  Future<void> generateAndSaveTasks({
    required StudyPlan plan,
    required List<Subject> subjects,
    required List<Topic> topics,
  }) async {
    // Delete existing tasks for this user (regenerate from scratch)
    final existingSnap =
        await _tasks.where('userId', isEqualTo: plan.userId).get();

    const batchLimit = 400;
    var batch = _db.batch();
    int opCount = 0;

    for (final doc in existingSnap.docs) {
      batch.delete(doc.reference);
      opCount++;
      if (opCount >= batchLimit) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    final newTasks = ScheduleGenerator.generate(
      plan: plan,
      subjects: subjects,
      topics: topics,
    );

    for (final task in newTasks) {
      final ref = _tasks.doc(task.id);
      batch.set(ref, task.toMap());
      opCount++;
      if (opCount >= batchLimit) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();
  }
}
