import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_plan_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/daily_task_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/schedule_generator.dart';
import 'ai_service.dart';

class StudyPlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _plans => _db.collection(AppConstants.colStudyPlans);
  CollectionReference get _tasks => _db.collection(AppConstants.colDailyTasks);

  Stream<StudyPlan?> watchActivePlan(String userId, {String? goalId}) {
    Query query = _plans.where('userId', isEqualTo: userId);
    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }
    return query
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
    AIService? aiService,
    String? routineContext,
  }) async {
    // Delete existing tasks for this user (regenerate from scratch) for the current goal
    final existingSnap = await _tasks
        .where('userId', isEqualTo: plan.userId)
        .where('goalId', isEqualTo: plan.goalId)
        .get();

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

    List<DailyTask> newTasks;

    if (aiService != null &&
        routineContext != null &&
        routineContext.trim().isNotEmpty) {
      newTasks = await aiService.generateSmartSchedule(
        userId: plan.userId,
        goalId: plan.goalId,
        subjects: subjects,
        topics: topics,
        startDate: plan.startDate,
        durationDays: plan.durationDays,
        routineContext: routineContext,
      );
    } else {
      newTasks = ScheduleGenerator.generate(
        plan: plan,
        subjects: subjects,
        topics: topics,
      );
    }

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
