import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _dayKey = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayTime = DateFormat('HH:mm');
  static final DateFormat _month = DateFormat('MMM yyyy', 'pt_BR');
  static final DateFormat _weekday = DateFormat('EEEE', 'pt_BR');
  static final DateFormat _shortWeekday = DateFormat('EEE', 'pt_BR');

  /// Returns today's date as a Firestore-compatible string key: "2024-01-15"
  static String todayKey() => _dayKey.format(DateTime.now());

  /// Converts a DateTime to a Firestore key string
  static String toKey(DateTime date) => _dayKey.format(date);

  /// Parses a Firestore key string to DateTime
  static DateTime fromKey(String key) => DateTime.parse(key);

  /// Returns start and end of the current week (Mon–Sun)
  static (DateTime, DateTime) currentWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return (
      DateTime(monday.year, monday.month, monday.day),
      DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
    );
  }

  /// Returns start and end of the current month
  static (DateTime, DateTime) currentMonthRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return (start, end);
  }

  /// Formats minutes as "Xh Ym" or "Ym"
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  /// Formats seconds to MM:SS for Pomodoro
  static String formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String displayDate(DateTime date) => _displayDate.format(date);
  static String displayTime(DateTime date) => _displayTime.format(date);
  static String monthLabel(DateTime date) => _month.format(date);
  static String weekdayLabel(DateTime date) => _weekday.format(date);
  static String shortWeekdayLabel(DateTime date) => _shortWeekday.format(date);

  /// Returns a list of dates between start and end (inclusive)
  static List<DateTime> dateRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}
