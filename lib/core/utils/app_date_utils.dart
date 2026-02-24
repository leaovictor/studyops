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

  /// Returns a concise relative label for FSRS intervals (e.g., "10m", "1d", "4d")
  static String formatFsrsInterval(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now);

    if (diff.isNegative) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  /// Returns "Hoje", "Amanhã" or the date for due label
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hoje';
    if (d == tomorrow) return 'Amanhã';
    return _displayDate.format(date);
  }

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
