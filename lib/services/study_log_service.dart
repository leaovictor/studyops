import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_log_model.dart';
import '../core/constants/app_constants.dart';

class StudyLogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _logs => _db.collection(AppConstants.colStudyLogs);

  Stream<List<StudyLog>> watchLogsForPeriod(
    String userId,
    String startDateKey,
    String endDateKey, {
    String? goalId,
  }) {
    Query query = _logs.where('userId', isEqualTo: userId);
    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }
    return query
        .where('date', isGreaterThanOrEqualTo: startDateKey)
        .where('date', isLessThanOrEqualTo: endDateKey)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StudyLog.fromDoc(d)).toList());
  }

  Future<List<StudyLog>> getLogsForMonth(String userId, int year, int month,
      {String? goalId}) async {
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final end =
        '$year-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    Query query = _logs.where('userId', isEqualTo: userId);
    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }

    final snap = await query
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    return snap.docs.map((d) => StudyLog.fromDoc(d)).toList();
  }
}
