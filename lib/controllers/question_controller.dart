import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import 'goal_controller.dart';
import 'subject_controller.dart';

final questionServiceProvider = Provider((ref) => QuestionService());

class QuestionFilter {
  final String? subjectId;
  final String? banca;
  final int? ano;
  final List<String>? tags;
  final int limit;

  const QuestionFilter({
    this.subjectId,
    this.banca,
    this.ano,
    this.tags,
    this.limit = 10,
  });

  QuestionFilter copyWith({
    String? subjectId,
    String? banca,
    int? ano,
    List<String>? tags,
    int? limit,
  }) {
    return QuestionFilter(
      subjectId: subjectId ?? this.subjectId,
      banca: banca ?? this.banca,
      ano: ano ?? this.ano,
      tags: tags ?? this.tags,
      limit: limit ?? this.limit,
    );
  }
}

// Current filter state
final questionFilterProvider =
    StateProvider<QuestionFilter>((ref) => const QuestionFilter());

// Selected subject state for the question bank screen (legacy, maybe keep for compat)
final selectedQuestionSubjectIdProvider = StateProvider<String?>((ref) => null);

final questionsProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(questionServiceProvider);
  final goalId = ref.watch(activeGoalIdProvider);
  final filter = ref.watch(questionFilterProvider);
  final subjectsAsync = ref.watch(subjectsProvider);
  final subjects = subjectsAsync.valueOrNull ?? [];

  if (subjects.isEmpty) return [];

  final effectiveSubjectId = filter.subjectId ?? subjects.first.id;

  return service.fetchQuestions(
    subjectId: effectiveSubjectId,
    goalId: goalId,
    banca: filter.banca,
    ano: filter.ano,
    tags: filter.tags,
    limit: filter.limit,
  );
});
