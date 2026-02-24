import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/error_note_model.dart';
import '../services/error_notebook_service.dart';
import '../core/constants/app_constants.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _questionsRef =>
      _firestore.collection(AppConstants.colQuestions);

  Future<List<Question>> fetchQuestions({
    required String subjectId,
    String? goalId,
    bool forceServer = false,
  }) async {
    Query query = _questionsRef.where('subjectId', isEqualTo: subjectId);

    if (goalId != null) {
      query = query.where('goalId', isEqualTo: goalId);
    }

    try {
      if (forceServer) {
        final serverSnapshot =
            await query.get(const GetOptions(source: Source.server));
        return serverSnapshot.docs.map((doc) => Question.fromDoc(doc)).toList();
      }

      // Try Cache First
      final cacheSnapshot =
          await query.get(const GetOptions(source: Source.cache));

      if (cacheSnapshot.docs.isEmpty) {
        // Fallback to Server if empty
        final serverSnapshot =
            await query.get(const GetOptions(source: Source.server));
        return serverSnapshot.docs.map((doc) => Question.fromDoc(doc)).toList();
      }

      return cacheSnapshot.docs.map((doc) => Question.fromDoc(doc)).toList();
    } catch (e) {
      // If an error happens while requesting cache, fetch from Server
      try {
        final serverSnapshot =
            await query.get(const GetOptions(source: Source.server));
        return serverSnapshot.docs.map((doc) => Question.fromDoc(doc)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> saveQuestion(Question question) async {
    if (question.id.isEmpty) {
      await _questionsRef.add(question.toMap());
    } else {
      await _questionsRef
          .doc(question.id)
          .set(question.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> seedQuestions(List<Map<String, dynamic>> questionsMap) async {
    if (questionsMap.isEmpty) return;

    final batch = _firestore.batch();

    for (var qMap in questionsMap) {
      final id = qMap['id'] as String?;
      final data = Map<String, dynamic>.from(qMap);
      data.remove('id'); // ID is the document name

      if (id != null && id.isNotEmpty) {
        final docRef = _questionsRef.doc(id);
        batch.set(docRef, data, SetOptions(merge: true));
      } else {
        final docRef = _questionsRef.doc();
        batch.set(docRef, data);
      }
    }

    await batch.commit();
  }

  /// Register an incorrect answer for a question by saving it in the Error Notebook
  /// integrated with FSRS stages. Stage 0 defaults to a 1 day interval.
  Future<void> registerWrongAnswer({
    required String userId,
    required Question question,
    required String givenAnswerText,
  }) async {
    final errorNotebookService = ErrorNotebookService();

    final errorNote = ErrorNote(
      id: '',
      userId: userId,
      goalId: question.goalId,
      subjectId: question.subjectId,
      topicId: 'questoes', // Or a map to a specific topic if needed
      question: question.text,
      correctAnswer: question.options[question.correctOptionIndex],
      errorReason:
          'Resposta submetida: $givenAnswerText\n\nExplicação: ${question.explanation}',
      nextReview: DateTime.now().add(const Duration(days: 1)),
      reviewStage: 0, // 0 = 1 day interval, Stage 1 = 3 days, etc.
    );

    await errorNotebookService.createNote(errorNote);
  }
}
