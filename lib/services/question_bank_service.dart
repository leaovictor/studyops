import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_question_model.dart';
import '../core/constants/app_constants.dart';

class QuestionBankService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _shared =>
      _db.collection(AppConstants.colSharedQuestions);

  Future<int> addQuestions(List<SharedQuestion> questions) async {
    int addedCount = 0;

    for (final q in questions) {
      // 1. Check if hash already exists
      final existing =
          await _shared.where('textHash', isEqualTo: q.textHash).limit(1).get();

      if (existing.docs.isEmpty) {
        // 2. Add if new
        await _shared.add(q.toMap());
        addedCount++;
      }
    }

    return addedCount;
  }

  Stream<List<SharedQuestion>> watchSharedQuestions(
      {String? subjectName, bool onlyApproved = true}) {
    Query query = _shared;
    if (onlyApproved) {
      query = query.where('isApproved', isEqualTo: true);
    }
    if (subjectName != null) {
      query = query.where('subjectName', isEqualTo: subjectName);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) =>
            SharedQuestion.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> approveQuestion(String id) async {
    await _shared.doc(id).update({'isApproved': true});
  }

  Future<void> deleteQuestion(String id) async {
    await _shared.doc(id).delete();
  }
}
