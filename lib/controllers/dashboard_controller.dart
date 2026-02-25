import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/study_log_service.dart';
import '../core/utils/app_date_utils.dart';
import 'auth_controller.dart';
import 'subject_controller.dart';
import 'goal_controller.dart';
import 'study_plan_controller.dart';
import '../services/schedule_generator_service.dart';

final studyLogServiceProvider =
    Provider<StudyLogService>((ref) => StudyLogService());

final scheduleGeneratorServiceProvider =
    Provider<ScheduleGeneratorService>((ref) => ScheduleGeneratorService());

/// Dashboard summary data
class DashboardData {
  final int todayMinutes;
  final int weekMinutes;
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

  const DashboardData({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.monthMinutes,
    required this.minutesBySubject,
    required this.weeklyTrend,
    this.streakDays = 0,
    this.consistencyPct = 0.0,
    this.suggestedSubjectId,
    this.suggestedMinutes = 0,
    this.plannedVsRead = const {},
    this.subjectDifficulties = const {},
  });

  static const empty = DashboardData(
    todayMinutes: 0,
    weekMinutes: 0,
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
  final user = ref.watch(authStateProvider).valueOrNull;
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
  int weekMinutes = 0;
  int monthMinutes = 0;
  final minutesBySubject = <String, int>{};
  final dailyMap = <String, int>{};

  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final activeSubjectIds = subjects.map((s) => s.id).toSet();
  final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];

  for (final log in logs) {
    if (!activeSubjectIds.contains(log.subjectId)) continue; // Filter deleted

    if (log.date.startsWith(currentMonthPrefix)) {
      monthMinutes += log.minutes;
      minutesBySubject[log.subjectId] =
          (minutesBySubject[log.subjectId] ?? 0) + log.minutes;
    }
    dailyMap[log.date] = (dailyMap[log.date] ?? 0) + log.minutes;

    if (log.date == todayKey) todayMinutes += log.minutes;

    final logDate = AppDateUtils.fromKey(log.date);
    if (!logDate.isBefore(weekStart) && !logDate.isAfter(weekEnd)) {
      weekMinutes += log.minutes;
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
    final plan = ref.watch(activePlanProvider).valueOrNull;
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
      suggestedSubjectId =
          distribution.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      suggestedMinutes = distribution[suggestedSubjectId]!;
    }
  }

  return DashboardData(
    todayMinutes: todayMinutes,
    weekMinutes: weekMinutes,
    monthMinutes: monthMinutes,
    minutesBySubject: minutesBySubject,
    weeklyTrend: trend,
    streakDays: streak,
    consistencyPct: consistencyPct,
    suggestedSubjectId: suggestedSubjectId,
    suggestedMinutes: suggestedMinutes,
    plannedVsRead: plannedVsRead,
    subjectDifficulties: subjectDifficulties,
  );
});
