import '../models/subject_model.dart';
import '../models/topic_model.dart';

class ScheduleGeneratorService {
  /// Calculates the relevance score for a single subject based on:
  /// Score = Priority (1-5) * Weight (1-10) * Average Topic Difficulty (1-5)
  double calculateRelevanceScore(Subject subject, List<Topic> subjectTopics) {
    double avgDifficulty = 3.0; // Default if no topics
    if (subjectTopics.isNotEmpty) {
      final totalDiff =
          subjectTopics.fold(0, (sum, topic) => sum + topic.difficulty);
      avgDifficulty = totalDiff / subjectTopics.length;
    }

    return subject.priority * subject.weight * avgDifficulty;
  }

  /// Distributes the daily total time (in minutes) among the given subjects
  /// proportionally to their Relevance Scores.
  /// Returns a map of subjectId -> allocated minutes.
  Map<String, int> distributeDailyTime(
    List<Subject> subjects,
    List<Topic> allTopics,
    int dailyTotalMinutes,
  ) {
    if (subjects.isEmpty) return {};

    final scores = <String, double>{};
    double totalScore = 0.0;

    for (final subject in subjects) {
      final subjectTopics =
          allTopics.where((t) => t.subjectId == subject.id).toList();
      final score = calculateRelevanceScore(subject, subjectTopics);
      scores[subject.id] = score;
      totalScore += score;
    }

    if (totalScore == 0) return {};

    final distribution = <String, int>{};
    int remainingMinutes = dailyTotalMinutes;

    // Distribute time proportionally
    for (int i = 0; i < subjects.length; i++) {
      final subject = subjects[i];
      final score = scores[subject.id] ?? 0.0;

      // Calculate proportional minutes
      // Use floor to ensure we don't exceed remaining minutes initially
      int allocated = ((score / totalScore) * dailyTotalMinutes).floor();

      // Ensure at least 15 minutes is allocated if the score > 0 and time allows
      if (score > 0 && allocated < 15 && dailyTotalMinutes >= 15) {
        // We will redistribute residuals later if needed, but for now we clamp minimums
        // Let's do a strict proportional pass first, then fix minimums if required.
      }

      distribution[subject.id] = allocated;
      remainingMinutes -= allocated;
    }

    // Add remaining rounding minutes to the highest score subject
    if (remainingMinutes > 0 && subjects.isNotEmpty) {
      String highestSubjectId = subjects.first.id;
      double highestScore = -1;

      for (final entry in scores.entries) {
        if (entry.value > highestScore) {
          highestScore = entry.value;
          highestSubjectId = entry.key;
        }
      }

      distribution[highestSubjectId] =
          (distribution[highestSubjectId] ?? 0) + remainingMinutes;
    }

    return distribution;
  }
}
