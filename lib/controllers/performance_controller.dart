import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_log_model.dart';
import '../services/question_service.dart';
import 'auth_controller.dart';

import '../services/question_bank_service.dart';

final questionServiceProvider = Provider<QuestionService>((ref) => QuestionService());
final questionBankServiceProvider = Provider<QuestionBankService>((ref) => QuestionBankService());

final questionLogsProvider = StreamProvider<List<QuestionLog>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(questionServiceProvider).watchLogs(user.uid);
});

class QuestionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addLog({
    required String subjectId,
    String? topicId,
    required int total,
    required int correct,
  }) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final log = QuestionLog(
        id: '',
        userId: user.uid,
        subjectId: subjectId,
        topicId: topicId,
        totalQuestions: total,
        correctAnswers: correct,
        date: DateTime.now(),
      );
      await ref.read(questionServiceProvider).addLog(log);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final questionControllerProvider =
    AsyncNotifierProvider<QuestionController, void>(QuestionController.new);

// Performance summary stats
class PerformanceStats {
  final double averageAccuracy;
  final int totalQuestions;
  final int totalCorrect;
  final Map<String, double> accuracyBySubject;

  PerformanceStats({
    required this.averageAccuracy,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.accuracyBySubject,
  });
}

final performanceStatsProvider = Provider<PerformanceStats>((ref) {
  final logs = ref.watch(questionLogsProvider).valueOrNull ?? [];
  if (logs.isEmpty) {
    return PerformanceStats(
      averageAccuracy: 0,
      totalQuestions: 0,
      totalCorrect: 0,
      accuracyBySubject: {},
    );
  }

  int totalQ = 0;
  int totalC = 0;
  final subjTotals = <String, List<int>>{}; // subjectId -> [total, correct]

  for (final log in logs) {
    totalQ += log.totalQuestions;
    totalC += log.correctAnswers;

    if (!subjTotals.containsKey(log.subjectId)) {
      subjTotals[log.subjectId] = [0, 0];
    }
    subjTotals[log.subjectId]![0] += log.totalQuestions;
    subjTotals[log.subjectId]![1] += log.correctAnswers;
  }

  final accuracyBySubject = subjTotals.map((key, value) {
    return MapEntry(key, value[0] > 0 ? (value[1] / value[0]) * 100 : 0.0);
  });

  return PerformanceStats(
    averageAccuracy: totalQ > 0 ? (totalC / totalQ) * 100 : 0,
    totalQuestions: totalQ,
    totalCorrect: totalC,
    accuracyBySubject: accuracyBySubject,
  );
});
