import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import 'goal_controller.dart';
import 'subject_controller.dart';

final questionServiceProvider = Provider((ref) => QuestionService());

// Selected subject state for the question bank screen
final selectedQuestionSubjectIdProvider = StateProvider<String?>((ref) => null);

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(questionServiceProvider);
  final goalId = ref.watch(activeGoalIdProvider);
  final subjectsAsync = ref.watch(subjectsProvider);
  final subjects = subjectsAsync.valueOrNull ?? [];

  if (subjects.isEmpty) return [];

  final selectedSubjectId = ref.watch(selectedQuestionSubjectIdProvider);
  final subjectToFetch = selectedSubjectId ?? subjects.first.id;

  return service.fetchQuestions(subjectId: subjectToFetch, goalId: goalId);
});
