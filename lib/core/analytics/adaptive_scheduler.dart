import 'dart:math' as math;
import '../../../models/subject_model.dart';
import '../../../models/topic_model.dart';
import 'weakness_analyzer.dart';

/// A single scheduled study block for one day.
class StudyBlock {
  const StudyBlock({
    required this.date,
    required this.subjectId,
    required this.subjectName,
    required this.minutes,
    required this.topicIds,
    required this.isWeaknessBoost,
  });

  final DateTime date;
  final String subjectId;
  final String subjectName;

  /// Allocated study time in minutes.
  final int minutes;

  /// Topic IDs to cover in this block (ordered by priority).
  final List<String> topicIds;

  /// True if this block was boosted due to weakness detection.
  final bool isWeaknessBoost;
}

/// Weekly replanning recommendation.
class WeeklyAdaptation {
  const WeeklyAdaptation({
    required this.weekNumber,
    required this.adjustedDistribution,
    required this.message,
    required this.boostSubjectIds,
  });

  /// Which week of the plan (1-indexed).
  final int weekNumber;

  /// subjectId → adjusted daily minutes for this week.
  final Map<String, int> adjustedDistribution;

  /// Human-readable summary of the adaptation.
  final String message;

  /// Subject IDs that received a time boost this week.
  final List<String> boostSubjectIds;
}

/// AdaptiveScheduler — pure Dart, no Flutter.
///
/// Builds an intelligent study schedule that:
///   1. Distributes time by relevance (priority × weight × difficulty)
///   2. Inserts weakness boosts for flagged subjects (+10–30 min/day)
///   3. Respects a minimum 15 min floor per active subject
///   4. Performs weekly replanning where struggling subjects get more time
///   5. Prioritises uncompleted (theory → review → exercises) topics
abstract final class AdaptiveScheduler {
  AdaptiveScheduler._();

  static const int _minMinutesPerSubject = 15;
  static const int _defaultTargetDaily = 180;

  /// Builds a [WeeklyAdaptation] for the current week.
  ///
  /// Call this every Sunday to get next-week's adjusted schedule.
  static WeeklyAdaptation adaptWeek({
    required int weekNumber,
    required List<Subject> subjects,
    required List<Topic> allTopics,
    required Map<String, double> accuracyBySubject,
    int targetDailyMinutes = _defaultTargetDaily,
  }) {
    // 1. Base relevance distribution
    final baseDistribution =
        _distributeByRelevance(subjects, targetDailyMinutes);

    // 2. Identify weak subjects
    final weaknesses = WeaknessAnalyzer.analyze(
      subjects: subjects,
      allTopics: allTopics,
      accuracyBySubject: accuracyBySubject,
      targetDailyMinutes: targetDailyMinutes,
    );

    final boostSubjectIds = <String>[];
    final adapted = Map<String, int>.from(baseDistribution);

    // 3. Apply weakness boosts
    int totalBoost = 0;
    for (final ws in weaknesses) {
      if (totalBoost >= 45) break; // cap total extra at 45 min/day
      final boost = math.min(ws.recommendedExtraMinutes, 45 - totalBoost);
      adapted[ws.subject.id] = (adapted[ws.subject.id] ?? 0) + boost;
      totalBoost += boost;
      boostSubjectIds.add(ws.subject.id);
    }

    // 4. Rebalance: if total > target, proportionally trim non-boosted subjects
    int total = adapted.values.fold(0, (s, v) => s + v);
    if (total > targetDailyMinutes + 30) {
      final excess = total - (targetDailyMinutes + 30);
      final nonBoosted =
          adapted.keys.where((id) => !boostSubjectIds.contains(id)).toList();
      if (nonBoosted.isNotEmpty) {
        final trimPerSubject = (excess / nonBoosted.length).ceil();
        for (final id in nonBoosted) {
          final current = adapted[id] ?? 0;
          adapted[id] =
              math.max(_minMinutesPerSubject, current - trimPerSubject);
        }
      }
    }

    // 5. Summary message
    String message;
    if (boostSubjectIds.isEmpty) {
      message =
          'Você está no caminho certo! Continue com a distribuição atual.';
    } else {
      final names = weaknesses
          .where((w) => boostSubjectIds.contains(w.subject.id))
          .map((w) => w.subject.name)
          .join(', ');
      message =
          'Semana $weekNumber: reforço em $names com base no seu desempenho.';
    }

    return WeeklyAdaptation(
      weekNumber: weekNumber,
      adjustedDistribution: adapted,
      message: message,
      boostSubjectIds: boostSubjectIds,
    );
  }

  /// Schedules topics for a given day respecting the adapted distribution.
  ///
  /// Prioritises incomplete topics (theory first, then review, then exercises).
  /// Returns study blocks ordered by this priority.
  static List<StudyBlock> scheduleDay({
    required DateTime date,
    required Map<String, int> distribution,
    required List<Subject> subjects,
    required List<Topic> allTopics,
    required List<String> weaknessBoostSubjectIds,
  }) {
    final blocks = <StudyBlock>[];

    for (final subject in subjects) {
      final minutes = distribution[subject.id] ?? 0;
      if (minutes < _minMinutesPerSubject) continue;

      final topics = allTopics.where((t) => t.subjectId == subject.id).toList()
        ..sort(_topicPrioritySort);

      // Pick topics that fit in the allocated time
      final selectedTopicIds = <String>[];
      int remaining = minutes;
      for (final topic in topics) {
        if (remaining <= 0) break;
        final estimatedTopicMinutes = _estimateTopicMinutes(topic.difficulty);
        selectedTopicIds.add(topic.id);
        remaining -= estimatedTopicMinutes;
      }

      blocks.add(StudyBlock(
        date: date,
        subjectId: subject.id,
        subjectName: subject.name,
        minutes: minutes,
        topicIds: selectedTopicIds,
        isWeaknessBoost: weaknessBoostSubjectIds.contains(subject.id),
      ));
    }

    // Sort: weakness-boosted subjects first, then by minutes desc
    blocks.sort((a, b) {
      if (a.isWeaknessBoost != b.isWeaknessBoost) {
        return a.isWeaknessBoost ? -1 : 1;
      }
      return b.minutes.compareTo(a.minutes);
    });

    return blocks;
  }

  // ─── Private helpers ────────────────────────────────────────────────────

  /// Priority: incomplete theory > incomplete review > incomplete exercises > rest.
  static int _topicPrioritySort(Topic a, Topic b) {
    int pa = _topicPriority(a);
    int pb = _topicPriority(b);
    if (pa != pb) return pa.compareTo(pb);
    // Tie-break: harder topics first within same priority tier
    return b.difficulty.compareTo(a.difficulty);
  }

  static int _topicPriority(Topic t) {
    if (!t.isTheoryDone) return 0;
    if (!t.isReviewDone) return 1;
    if (!t.isExercisesDone) return 2;
    return 3; // all done → lowest priority
  }

  /// Rough estimate: 20 min for easy, 35 for medium, 50 for hard per topic.
  static int _estimateTopicMinutes(int difficulty) {
    if (difficulty <= 2) return 20;
    if (difficulty == 3) return 30;
    return 45;
  }

  /// Distributes [dailyMinutes] proportionally by relevance score.
  static Map<String, int> _distributeByRelevance(
      List<Subject> subjects, int dailyMinutes) {
    if (subjects.isEmpty) return {};

    final scores = <String, double>{};
    double totalScore = 0;

    for (final s in subjects) {
      final sc = s.priority * s.weight * s.difficulty.toDouble();
      scores[s.id] = sc;
      totalScore += sc;
    }

    if (totalScore == 0) {
      // Equal distribution as fallback
      final each = (dailyMinutes / subjects.length).floor();
      return {for (final s in subjects) s.id: each};
    }

    final dist = <String, int>{};
    int remaining = dailyMinutes;

    for (int i = 0; i < subjects.length; i++) {
      final s = subjects[i];
      final ratio = scores[s.id]! / totalScore;
      final allocated = i == subjects.length - 1
          ? remaining // give all remaining to last subject
          : math.max(_minMinutesPerSubject, (ratio * dailyMinutes).floor());
      dist[s.id] = allocated;
      if (i < subjects.length - 1) remaining -= allocated;
    }

    return dist;
  }
}
