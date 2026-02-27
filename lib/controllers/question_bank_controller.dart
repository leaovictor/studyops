import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_question_model.dart';
import '../services/question_bank_service.dart';

final questionBankServiceProvider =
    Provider<QuestionBankService>((ref) => QuestionBankService());

/// Stream of all shared questions.
/// We set [onlyApproved] to false for the global quiz right now to see all uploaded questions.
final sharedQuestionsProvider = StreamProvider<List<SharedQuestion>>((ref) {
  return ref
      .watch(questionBankServiceProvider)
      .watchSharedQuestions(onlyApproved: false); // allow all for now
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
