import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_task_model.dart';
import '../models/study_log_model.dart';
import '../core/constants/app_constants.dart';

class DailyTaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _tasks => _db.collection(AppConstants.colDailyTasks);
  CollectionReference get _logs => _db.collection(AppConstants.colStudyLogs);

  Stream<List<DailyTask>> watchTasksForDate(String userId, String dateKey,
      {String? goalId}) {
    Query query = _tasks
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dateKey);

    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => DailyTask.fromDoc(d)).toList()
          ..sort((a, b) => a.subjectId.compareTo(b.subjectId)));
  }

  Future<void> markDone(DailyTask task, int actualMinutes) async {
    final batch = _db.batch();

    // Update the task
    batch.update(_tasks.doc(task.id), {
      'done': true,
      'actualMinutes': actualMinutes,
    });

    // Write a study log entry
    final logRef = _logs.doc();
    final log = StudyLog(
      id: logRef.id,
      userId: task.userId,
      goalId: task.goalId,
      date: task.date,
      subjectId: task.subjectId,
      minutes: actualMinutes > 0 ? actualMinutes : task.plannedMinutes,
    );
    batch.set(logRef, log.toMap());

    await batch.commit();
  }

  Future<void> markUndone(String taskId) async {
    await _tasks.doc(taskId).update({'done': false, 'actualMinutes': 0});
  }

  Future<DailyTask> addManualTask(DailyTask task) async {
    final ref = await _tasks.add(task.toMap());
    return task.copyWith(id: ref.id);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
  }
}
