import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_question_model.dart';
import '../services/question_bank_service.dart';

final questionBankServiceProvider =
    Provider<QuestionBankService>((ref) => QuestionBankService());

/// Stream of all shared questions.
/// We set [onlyApproved] to false for the global quiz right now to see all uploaded questions.
final selectedQuizSubjectProvider = StateProvider<String?>((ref) => null);
final selectedQuizTopicProvider = StateProvider<String?>((ref) => null);

/// Stream of all shared questions.
/// We set [onlyApproved] to false for the global quiz right now to see all uploaded questions.
final sharedQuestionsProvider = StreamProvider<List<SharedQuestion>>((ref) {
  final subject = ref.watch(selectedQuizSubjectProvider);
  final topic = ref.watch(selectedQuizTopicProvider);

  return ref.watch(questionBankServiceProvider).watchSharedQuestions(
        subjectName: subject,
        topicName: topic,
        onlyApproved: false,
      ); // allow all for now
});

/// Unique topic names for the currently selected subject.
final availableQuizTopicsProvider = StreamProvider<List<String>>((ref) {
  final subject = ref.watch(selectedQuizSubjectProvider);
  if (subject == null) return Stream.value([]);

  return ref
      .watch(questionBankServiceProvider)
      .watchSharedQuestions(subjectName: subject, onlyApproved: false)
      .map((questions) {
    final topics = questions
        .map((q) => q.topicName)
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    topics.sort();
    return topics;
  });
});

class QuestionBankController extends AsyncNotifier<void> {
  QuestionBankService get _service => ref.read(questionBankServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> approveQuestion(String id) async {
    await _service.approveQuestion(id);
  }

  Future<void> deleteQuestion(String id) async {
    await _service.deleteQuestion(id);
  }
}

final questionBankControllerProvider =
    AsyncNotifierProvider<QuestionBankController, void>(
        QuestionBankController.new);
