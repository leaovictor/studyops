import '../../../models/subject_model.dart';
import '../../../models/topic_model.dart';

/// A weak subject identified by the weakness analyzer.
class WeakSubject {
  const WeakSubject({
    required this.subject,
    required this.weaknessScore,
    required this.weakTopics,
    required this.reason,
    required this.recommendedExtraMinutes,
  });

  /// The subject in question.
  final Subject subject;

  /// Weakness score: higher means more needs to study (0.0–1.0).
  final double weaknessScore;

  /// Topics within this subject that are lagging behind.
  final List<Topic> weakTopics;

  /// Human-readable reason for the weakness flag.
  final String reason;

  /// Suggested additional daily minutes for this subject.
  final int recommendedExtraMinutes;
}

/// WeaknessAnalyzer — pure Dart, no Flutter.
///
/// Analyses subjects + quiz performance to identify cognitive weak spots.
///
/// Signals evaluated:
///   1. Syllabus coverage gap (theory/review/exercises not done)
///   2. Quiz accuracy below threshold per subject (≤ 60%)
///   3. High-difficulty topics with nothing completed
///   4. High relevance score (priority × weight × difficulty) but low completion
abstract final class WeaknessAnalyzer {
  WeaknessAnalyzer._();

  static const double _lowAccuracyThreshold = 60.0; // %
  static const double _minCoverageRatioForGood = 0.50; // 50%

  /// Returns a ranked list of weak subjects (most urgent first).
  ///
  /// [accuracyBySubject] maps subjectId → quiz accuracy % (0–100).
  static List<WeakSubject> analyze({
    required List<Subject> subjects,
    required List<Topic> allTopics,
    required Map<String, double> accuracyBySubject,
    int targetDailyMinutes = 180,
  }) {
    if (subjects.isEmpty) return [];

    final results = <WeakSubject>[];

    for (final subject in subjects) {
      final topics = allTopics.where((t) => t.subjectId == subject.id).toList();
      if (topics.isEmpty) continue;

      // 1. Coverage analysis
      final total = topics.length;
      final theoryDone = topics.where((t) => t.isTheoryDone).length;
      final reviewDone = topics.where((t) => t.isReviewDone).length;
      final exercisesDone = topics.where((t) => t.isExercisesDone).length;

      final coverageRatio = total > 0
          ? (theoryDone + reviewDone + exercisesDone) / (total * 3.0)
          : 0.0;

      // 2. Quiz accuracy
      final accuracy = accuracyBySubject[subject.id]; // null if no data
      final hasLowAccuracy =
          accuracy != null && accuracy < _lowAccuracyThreshold;

      // 3. Difficult incomplete topics
      final hardIncomplete = topics
          .where((t) => t.difficulty >= 4 && !t.isTheoryDone && !t.isReviewDone)
          .toList();

      // 4. Relevance × coverage gap
      final relevance =
          subject.priority * subject.weight * subject.difficulty.toDouble();

      // Compute weakness score (0–1)
      double score = 0.0;

      // Coverage gap: inversely proportional — low coverage = high weakness
      score += (1.0 - coverageRatio.clamp(0.0, 1.0)) * 0.40;

      // Quiz accuracy penalty
      if (accuracy != null) {
        final accuracyRatio = accuracy / 100.0;
        score += (1.0 - accuracyRatio.clamp(0.0, 1.0)) * 0.35;
      } else {
        // No data yet — assume middle weakness for unknown performance
        score += 0.175;
      }

      // Hard incomplete topics penalty
      final hardPenalty =
          (hardIncomplete.length / topics.length.toDouble()).clamp(0.0, 1.0);
      score += hardPenalty * 0.15;

      // Relevance bonus — high-relevance subjects with low coverage need more attention
      const relevanceMax = 5.0 * 10.0 * 5.0; // max possible relevance
      final relevanceNorm = (relevance / relevanceMax).clamp(0.0, 1.0);
      if (coverageRatio < _minCoverageRatioForGood) {
        score += relevanceNorm * 0.10;
      }

      score = score.clamp(0.0, 1.0);

      // Filter: only flag as weak if score > 0.25 or explicitly low accuracy
      if (score <= 0.25 && !hasLowAccuracy) continue;

      // Build reason string
      final reasons = <String>[];
      if (coverageRatio < _minCoverageRatioForGood) {
        reasons
            .add('cobertura de ${(coverageRatio * 100).toStringAsFixed(0)}%');
      }
      if (hasLowAccuracy) {
        reasons.add('acerto de ${accuracy.toStringAsFixed(0)}% nas questões');
      }
      if (hardIncomplete.isNotEmpty) {
        reasons
            .add('${hardIncomplete.length} tópico(s) difícil(eis) pendente(s)');
      }

      final reason =
          reasons.isNotEmpty ? reasons.join(', ') : 'revisão recomendada';

      // Suggest extra minutes proportional to weakness score (0–30 extra)
      final extraMinutes = (score * 30).round().clamp(5, 30);

      final weakTopics = topics
          .where((t) => !t.isTheoryDone || !t.isReviewDone)
          .toList()
        ..sort((a, b) => b.difficulty.compareTo(a.difficulty));

      results.add(WeakSubject(
        subject: subject,
        weaknessScore: score,
        weakTopics: weakTopics.take(5).toList(),
        reason: reason,
        recommendedExtraMinutes: extraMinutes,
      ));
    }

    // Sort by weakness score descending (most critical first)
    results.sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    return results;
  }
}
