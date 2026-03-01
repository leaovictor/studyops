import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/study_log_service.dart';
import '../core/utils/app_date_utils.dart';
import 'auth_controller.dart';
import 'subject_controller.dart';
import 'goal_controller.dart';
import 'study_plan_controller.dart';
import '../services/schedule_generator_service.dart';
import '../core/analytics/study_score_engine.dart';
import 'performance_controller.dart';

final studyLogServiceProvider =
    Provider<StudyLogService>((ref) => StudyLogService());

final scheduleGeneratorServiceProvider =
    Provider<ScheduleGeneratorService>((ref) => ScheduleGeneratorService());

/// Dashboard summary data
class DashboardData {
  final int todayMinutes;
  final int todayProductiveMinutes;
  final int weekMinutes;
  final int weekProductiveMinutes;
  final int monthMinutes;
  final Map<String, int> minutesBySubject; // subjectId → minutes
  final List<MapEntry<String, int>>
      weeklyTrend; // dateKey → minutes (last 7 days)
  final int streakDays;
  final double consistencyPct; // 0.0 – 1.0 over last 7 days
  final String? suggestedSubjectId; // Focus suggestion based on schedule limits
  final int suggestedMinutes; // Time suggested for the focal subject
  final Map<String, Map<String, int>>
      plannedVsRead; // subjectId → {'planned': x, 'read': y}
  final Map<String, double> subjectDifficulties; // subjectId → avgDifficulty

  // Syllabus Progress
  final int totalTheory;
  final int completedTheory;
  final int totalReview;
  final int completedReview;
  final int totalExercises;
  final int completedExercises;

  const DashboardData({
    required this.todayMinutes,
    required this.todayProductiveMinutes,
    required this.weekMinutes,
    required this.weekProductiveMinutes,
    required this.monthMinutes,
    required this.minutesBySubject,
    required this.weeklyTrend,
    this.streakDays = 0,
    this.consistencyPct = 0.0,
    this.suggestedSubjectId,
    this.suggestedMinutes = 0,
    this.plannedVsRead = const {},
    this.subjectDifficulties = const {},
    this.totalTheory = 0,
    this.completedTheory = 0,
    this.totalReview = 0,
    this.completedReview = 0,
    this.totalExercises = 0,
    this.completedExercises = 0,
  });

  static const empty = DashboardData(
    todayMinutes: 0,
    todayProductiveMinutes: 0,
    weekMinutes: 0,
    weekProductiveMinutes: 0,
    monthMinutes: 0,
    minutesBySubject: {},
    weeklyTrend: [],
    streakDays: 0,
    consistencyPct: 0.0,
    suggestedSubjectId: null,
    suggestedMinutes: 0,
    plannedVsRead: {},
    subjectDifficulties: {},
  );
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return DashboardData.empty;

  final activeGoalId = ref.watch(activeGoalIdProvider);
  final service = ref.watch(studyLogServiceProvider);
  final now = DateTime.now();

  // Fetch at least 32 days back to cover streak and month transitions
  final streakLookback = now.subtract(const Duration(days: 32));
  final startOfMonth = DateTime(now.year, now.month, 1);
  final queryStart =
      streakLookback.isBefore(startOfMonth) ? streakLookback : startOfMonth;

  final logs = await service.getLogsForRange(
      user.uid, AppDateUtils.toKey(queryStart), AppDateUtils.toKey(now),
      goalId: activeGoalId);

  final todayKey = AppDateUtils.todayKey();
  final currentMonthPrefix =
      "${now.year}-${now.month.toString().padLeft(2, '0')}";
  final (weekStart, weekEnd) = AppDateUtils.currentWeekRange();

  int todayMinutes = 0;
  int todayProductiveMinutes = 0;
  int weekMinutes = 0;
  int weekProductiveMinutes = 0;
  int monthMinutes = 0;
  final minutesBySubject = <String, int>{};
  final dailyMap = <String, int>{};

  try {
    // Wait for essential domain data to avoid intermediate empty states
    final subjects = await ref.watch(subjectsProvider.future);
    final activeSubjectIds = subjects.map((s) => s.id).toSet();
    final allTopics = await ref.watch(allTopicsProvider.future);

    for (final log in logs) {
      if (!activeSubjectIds.contains(log.subjectId)) continue; // Filter deleted

      if (log.date.startsWith(currentMonthPrefix)) {
        monthMinutes += log.minutes;
        minutesBySubject[log.subjectId] =
            (minutesBySubject[log.subjectId] ?? 0) + log.minutes;
      }
      dailyMap[log.date] = (dailyMap[log.date] ?? 0) + log.minutes;

      if (log.date == todayKey) {
        todayMinutes += log.minutes;
        // We will add productiveMinutes mapping here shortly
        todayProductiveMinutes += log.productiveMinutes ?? log.minutes;
      }

      final logDate = AppDateUtils.fromKey(log.date);
      if (!logDate.isBefore(weekStart) && !logDate.isAfter(weekEnd)) {
        weekMinutes += log.minutes;
        weekProductiveMinutes += log.productiveMinutes ?? log.minutes;
      }
    }

    // Build weekly trend (last 7 days)
    final trend = <MapEntry<String, int>>[];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = AppDateUtils.toKey(d);
      trend.add(MapEntry(k, dailyMap[k] ?? 0));
    }

    // Consistency: how many of the last 7 days had ANY study
    final studiedDaysLast7 = trend.where((e) => e.value > 0).length;
    final consistencyPct = studiedDaysLast7 / 7.0;

    // Streak: consecutive days ending today with study
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final k = AppDateUtils.toKey(d);
      if ((dailyMap[k] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }

    // Generate Suggested Subject based on Time Allocation vs Read Time
    String? suggestedSubjectId;
    int suggestedMinutes = 0;

    final plannedVsRead = <String, Map<String, int>>{};
    final subjectDifficulties = <String, double>{};

    if (subjects.isNotEmpty) {
      // We base the active plan target daily time, default 3h (180 mins)
      final plan = await ref.watch(activePlanProvider.future);
      final dailyTotalTarget =
          plan != null ? (plan.dailyHours * 60).toInt() : 180;

      final scheduleService = ref.read(scheduleGeneratorServiceProvider);
      final distribution = scheduleService.distributeDailyTime(
          subjects, allTopics, dailyTotalTarget);

      // Find the subject with the largest gap between planned and studied today
      int maxGap = -1;

      for (final subject in subjects) {
        final allocated = distribution[subject.id] ?? 0;

        // How much studied today for this specific subject
        int todaySubjMinutes = 0;
        for (final log in logs) {
          if (log.subjectId == subject.id && log.date == todayKey) {
            todaySubjMinutes += log.minutes;
          }
        }

        // Add to planned vs read map
        plannedVsRead[subject.id] = {
          'planned': allocated,
          'read': todaySubjMinutes,
        };

        final gap = allocated - todaySubjMinutes;
        if (gap > maxGap && gap > 0) {
          maxGap = gap;
          suggestedSubjectId = subject.id;
          suggestedMinutes = gap;
        }

        // Calculate avg difficulty for the subject
        final subTopics = allTopics.where((t) => t.subjectId == subject.id);
        if (subTopics.isNotEmpty) {
          subjectDifficulties[subject.id] =
              subTopics.fold(0, (sum, t) => sum + t.difficulty) /
                  subTopics.length;
        } else {
          subjectDifficulties[subject.id] = 3.0;
        }
      }

      // If all subjects are completed for the day, simply suggest the most relevant overall
      if (suggestedSubjectId == null && distribution.isNotEmpty) {
        suggestedSubjectId = distribution.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        suggestedMinutes = distribution[suggestedSubjectId]!;
      }
    }

    // Calculate Syllabus Progress
    int completedTheory = 0;
    int completedReview = 0;
    int completedExercises = 0;

    for (final topic in allTopics) {
      if (topic.isTheoryDone) completedTheory++;
      if (topic.isReviewDone) completedReview++;
      if (topic.isExercisesDone) completedExercises++;
    }

    return DashboardData(
      todayMinutes: todayMinutes,
      todayProductiveMinutes: todayProductiveMinutes,
      weekMinutes: weekMinutes,
      weekProductiveMinutes: weekProductiveMinutes,
      monthMinutes: monthMinutes,
      minutesBySubject: minutesBySubject,
      weeklyTrend: trend,
      streakDays: streak,
      consistencyPct: consistencyPct,
      suggestedSubjectId: suggestedSubjectId,
      suggestedMinutes: suggestedMinutes,
      plannedVsRead: plannedVsRead,
      subjectDifficulties: subjectDifficulties,
      totalTheory: allTopics.length,
      completedTheory: completedTheory,
      totalReview: allTopics.length,
      completedReview: completedReview,
      totalExercises: allTopics.length,
      completedExercises: completedExercises,
    );
  } catch (e, st) {
    debugPrint('Dashboard Provider Error: $e');
    debugPrint('Stack trace: $st');
    rethrow;
  }
});

/// Provides a [StudyScore] derived from all existing data providers.
/// Recomputes automatically when dashboard or performance data changes.
final studyScoreProvider = Provider<StudyScore>((ref) {
  final dashAsync = ref.watch(dashboardProvider);
  final perf = ref.watch(performanceStatsProvider);
  final plan = ref.watch(activePlanProvider).valueOrNull;

  return dashAsync.when(
    loading: () => StudyScore.empty,
    error: (_, __) => StudyScore.empty,
    data: (data) {
      final targetDailyMinutes =
          plan != null ? (plan.dailyHours * 60).toInt() : 180;
      return StudyScoreEngine.compute(
        weekMinutes: data.weekMinutes,
        todayProductiveMinutes: data.todayProductiveMinutes,
        consistencyPct: data.consistencyPct,
        streakDays: data.streakDays,
        quizAccuracyPct: perf.averageAccuracy,
        totalTopics: data.totalTheory,
        completedTheory: data.completedTheory,
        completedReview: data.completedReview,
        completedExercises: data.completedExercises,
        targetDailyMinutes: targetDailyMinutes,
      );
    },
  );
});

/// Returns a Map<dateKey, minutes> for the past 35 days, used by StudyHeatmap.
/// Leverages the same StudyLogService + auth already used by dashboardProvider.
final thirtyDayHeatmapProvider = FutureProvider<Map<String, int>>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return {};

  final activeGoalId = ref.watch(activeGoalIdProvider);
  final service = ref.watch(studyLogServiceProvider);
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 35));

  final logs = await service.getLogsForRange(
    user.uid,
    AppDateUtils.toKey(start),
    AppDateUtils.toKey(now),
    goalId: activeGoalId,
  );

  final map = <String, int>{};
  for (final log in logs) {
    map[log.date] = (map[log.date] ?? 0) + log.minutes;
  }
  return map;
});
