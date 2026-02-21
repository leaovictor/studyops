import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/study_log_service.dart';
import '../core/utils/app_date_utils.dart';
import 'auth_controller.dart';

final studyLogServiceProvider =
    Provider<StudyLogService>((ref) => StudyLogService());

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

  const DashboardData({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.monthMinutes,
    required this.minutesBySubject,
    required this.weeklyTrend,
    this.streakDays = 0,
    this.consistencyPct = 0.0,
  });

  static const empty = DashboardData(
    todayMinutes: 0,
    weekMinutes: 0,
    monthMinutes: 0,
    minutesBySubject: {},
    weeklyTrend: [],
    streakDays: 0,
    consistencyPct: 0.0,
  );
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return DashboardData.empty;

  final service = ref.watch(studyLogServiceProvider);
  final now = DateTime.now();

  final logs = await service.getLogsForMonth(user.uid, now.year, now.month);

  final todayKey = AppDateUtils.todayKey();
  final (weekStart, weekEnd) = AppDateUtils.currentWeekRange();

  int todayMinutes = 0;
  int weekMinutes = 0;
  int monthMinutes = 0;
  final minutesBySubject = <String, int>{};
  final dailyMap = <String, int>{};

  for (final log in logs) {
    monthMinutes += log.minutes;
    minutesBySubject[log.subjectId] =
        (minutesBySubject[log.subjectId] ?? 0) + log.minutes;
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

  return DashboardData(
    todayMinutes: todayMinutes,
    weekMinutes: weekMinutes,
    monthMinutes: monthMinutes,
    minutesBySubject: minutesBySubject,
    weeklyTrend: trend,
    streakDays: streak,
    consistencyPct: consistencyPct,
  );
});
