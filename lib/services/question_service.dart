import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_log_model.dart';
import '../core/constants/app_constants.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _logs => _db.collection(AppConstants.colQuestionLogs);

  Future<void> addLog(QuestionLog log) async {
    await _logs.add(log.toMap());
  }

  Stream<List<QuestionLog>> watchLogs(String userId) {
    return _logs
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => QuestionLog.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<QuestionLog>> getLogsForRange(
      String userId, DateTime start, DateTime end) async {
    final snap = await _logs
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snap.docs
        .map((d) => QuestionLog.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }
}
