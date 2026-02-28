import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../controllers/study_plan_controller.dart';
import '../../controllers/performance_controller.dart';
import '../../core/analytics/weakness_analyzer.dart';
import '../../core/analytics/adaptive_scheduler.dart';

export '../../core/analytics/weakness_analyzer.dart';
export '../../core/analytics/adaptive_scheduler.dart';

/// Provides the ranked list of weak subjects for the authenticated user.
///
/// Derived from: subjects, all topics, quiz accuracy per subject.
/// Auto-refreshes when any dependency changes.
final weakSubjectsProvider = Provider<List<WeakSubject>>((ref) {
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];
  final perf = ref.watch(performanceStatsProvider);

  return WeaknessAnalyzer.analyze(
    subjects: subjects,
    allTopics: allTopics,
    accuracyBySubject: perf.accuracyBySubject,
  );
});

/// Provides this week's adaptive schedule recommendation.
final weeklyAdaptationProvider = Provider<WeeklyAdaptation?>((ref) {
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  if (subjects.isEmpty) return null;

  final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];
  final perf = ref.watch(performanceStatsProvider);
  final plan = ref.watch(activePlanProvider).valueOrNull;

  final now = DateTime.now();
  final planStart = plan?.startDate ?? now;
  final daysSinceStart = now.difference(planStart).inDays;
  final weekNumber = (daysSinceStart / 7).floor() + 1;
  final targetDailyMinutes =
      plan != null ? (plan.dailyHours * 60).toInt() : 180;

  return AdaptiveScheduler.adaptWeek(
    weekNumber: weekNumber,
    subjects: subjects,
    allTopics: allTopics,
    accuracyBySubject: perf.accuracyBySubject,
    targetDailyMinutes: targetDailyMinutes,
  );
});

/// Provides the study blocks for today based on adaptive schedule.
final todayStudyBlocksProvider = Provider<List<StudyBlock>>((ref) {
  final adaptation = ref.watch(weeklyAdaptationProvider);
  if (adaptation == null) return [];

  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];

  return AdaptiveScheduler.scheduleDay(
    date: DateTime.now(),
    distribution: adaptation.adjustedDistribution,
    subjects: subjects,
    allTopics: allTopics,
    weaknessBoostSubjectIds: adaptation.boostSubjectIds,
  );
});

/// Checks whether the user is authenticated (helper used by plan engine widgets).
final isPlanReadyProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final plan = ref.watch(activePlanProvider).valueOrNull;
  return user != null && plan != null;
});
