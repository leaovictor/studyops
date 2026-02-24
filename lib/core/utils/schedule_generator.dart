import '../../models/study_plan_model.dart';
import '../../models/subject_model.dart';
import '../../models/topic_model.dart';
import '../../models/daily_task_model.dart';
import 'app_date_utils.dart';
import 'package:uuid/uuid.dart';

class ScheduleGenerator {
  ScheduleGenerator._();

  /// Generates a list of [DailyTask]s for the full study plan duration.
  ///
  /// Distribution algorithm:
  /// 1. Compute a normalized weight for each topic:
  ///    `score = subject.priority * subject.weight * topic.difficulty`
  /// 2. Calculate each topic's share of daily study time proportionally.
  /// 3. Distribute topics across days, filling up `dailyHours`.
  static List<DailyTask> generate({
    required StudyPlan plan,
    required List<Subject> subjects,
    required List<Topic> topics,
  }) {
    if (subjects.isEmpty || topics.isEmpty) return [];

    final tasks = <DailyTask>[];
    const uuid = Uuid();

    // Build subject lookup
    final subjectMap = {for (final s in subjects) s.id: s};

    // Associate topics to subjects
    final topicsBySubject = <String, List<Topic>>{};
    for (final t in topics) {
      topicsBySubject.putIfAbsent(t.subjectId, () => []).add(t);
    }

    // Build weighted topic list — only topics whose subject exists
    final weightedTopics = <_WeightedTopic>[];
    for (final topic in topics) {
      final subject = subjectMap[topic.subjectId];
      if (subject == null) continue;
      final score = subject.priority * subject.weight * topic.difficulty;
      weightedTopics.add(_WeightedTopic(
          topic: topic, subject: subject, score: score.toDouble()));
    }

    if (weightedTopics.isEmpty) return [];

    final totalScore = weightedTopics.fold(0.0, (sum, w) => sum + w.score);
    final dailyTotalMinutes = (plan.dailyHours * 60).round();

    // Generate tasks for each day
    final startDate = plan.startDate;

    for (int day = 0; day < plan.durationDays; day++) {
      final date = startDate.add(Duration(days: day));
      final dateKey = AppDateUtils.toKey(date);

      // Assign topics proportionally on each day
      // Reset topic index per day to achieve even distribution across the plan
      final dayTopics =
          _buildDayTopics(weightedTopics, totalScore, dailyTotalMinutes);

      for (final entry in dayTopics) {
        if (entry.minutes < 5) continue;
        tasks.add(DailyTask(
          id: uuid.v4(),
          userId: plan.userId,
          goalId: plan.goalId,
          date: dateKey,
          subjectId: entry.topic.subjectId,
          topicId: entry.topic.id,
          plannedMinutes: entry.minutes,
          done: false,
          actualMinutes: 0,
        ));
      }
    }

    return tasks;
  }

  static List<_DayEntry> _buildDayTopics(
    List<_WeightedTopic> weightedTopics,
    double totalScore,
    int dailyMinutes,
  ) {
    final entries = <_DayEntry>[];
    for (final wt in weightedTopics) {
      final proportion = wt.score / totalScore;
      final minutes = (proportion * dailyMinutes).round();
      entries.add(_DayEntry(topic: wt.topic, minutes: minutes));
    }
    return entries;
  }
}

class _WeightedTopic {
  final Topic topic;
  final Subject subject;
  final double score;
  _WeightedTopic(
      {required this.topic, required this.subject, required this.score});
}

class _DayEntry {
  final Topic topic;
  final int minutes;
  _DayEntry({required this.topic, required this.minutes});
}
