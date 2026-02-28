import 'dart:math' as math;

/// StudyScoreEngine — pure Dart, no Flutter dependencies.
///
/// Calculates a holistic "Study Score" (0–1000) based on cognitive performance
/// dimensions and an "Approval Probability" (0–100%) based on syllabus coverage,
/// consistency and quiz accuracy.
///
/// Dimensions:
///   - Volume (20%)   : Total weekly/daily study hours vs target
///   - Consistency (25%) : How many of the last 7 days had study
///   - Performance (30%) : Quiz accuracy across all subjects
///   - Coverage (15%)  : Syllabus theory/review/exercise completion
///   - Momentum (10%)  : Current streak
abstract final class StudyScoreEngine {
  StudyScoreEngine._();

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Computes the overall Study Score (0–1000).
  static StudyScore compute({
    required int weekMinutes,
    required int todayProductiveMinutes,
    required double consistencyPct, // 0.0–1.0
    required int streakDays,
    required double quizAccuracyPct, // 0.0–100.0
    required int totalTopics,
    required int completedTheory,
    required int completedReview,
    required int completedExercises,
    int targetDailyMinutes = 180,
    int targetWeeklyMinutes = 1260, // 21h/week default
  }) {
    // 1. Volume score (0–200)
    final dailyRatio = (todayProductiveMinutes / targetDailyMinutes.toDouble())
        .clamp(0.0, 1.0);
    final weeklyRatio =
        (weekMinutes / targetWeeklyMinutes.toDouble()).clamp(0.0, 1.0);
    final volumeScore = ((dailyRatio * 0.4 + weeklyRatio * 0.6) * 200).round();

    // 2. Consistency score (0–250)
    final consistencyScore = (consistencyPct * 250).round();

    // 3. Performance / Quiz accuracy score (0–300)
    final performanceScore =
        ((quizAccuracyPct / 100.0).clamp(0.0, 1.0) * 300).round();

    // 4. Coverage score (0–150)
    final coverageTotal = totalTopics > 0
        ? ((completedTheory + completedReview + completedExercises) /
                (totalTopics * 3.0))
            .clamp(0.0, 1.0)
        : 0.0;
    final coverageScore = (coverageTotal * 150).round();

    // 5. Momentum / Streak score (0–100)
    // 30-day streak cap → 100 pts
    final streakScore = ((streakDays / 30.0).clamp(0.0, 1.0) * 100).round();

    final total = volumeScore +
        consistencyScore +
        performanceScore +
        coverageScore +
        streakScore;

    // Approval probability model (sigmoid-shaped, 0–100%)
    final approvalProbability = _approvalProbability(
      studyScore: total,
      quizAccuracyPct: quizAccuracyPct,
      consistencyPct: consistencyPct,
      syllabusCompletionPct: coverageTotal,
    );

    // Next session suggestion
    final nextSession = _suggestNextSession(
      consistencyPct: consistencyPct,
      todayProductiveMinutes: todayProductiveMinutes,
      targetDailyMinutes: targetDailyMinutes,
    );

    return StudyScore(
      total: total.clamp(0, 1000),
      volumeScore: volumeScore,
      consistencyScore: consistencyScore,
      performanceScore: performanceScore,
      coverageScore: coverageScore,
      momentumScore: streakScore,
      approvalProbabilityPct: approvalProbability,
      nextSessionMinutes: nextSession,
      weeklyProgressPct:
          (weekMinutes / targetWeeklyMinutes.toDouble()).clamp(0.0, 1.0),
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Logistic-like approval probability [0–100%].
  static double _approvalProbability({
    required int studyScore,
    required double quizAccuracyPct,
    required double consistencyPct,
    required double syllabusCompletionPct,
  }) {
    // Weighted composite (0–1)
    final composite = (studyScore / 1000.0) * 0.35 +
        (quizAccuracyPct / 100.0) * 0.40 +
        consistencyPct * 0.15 +
        syllabusCompletionPct * 0.10;

    // Sigmoid: maps 0–1 composite to a probability that saturates closer to 95%
    // f(x) = 1 / (1 + e^(-12*(x-0.5)))  → rescaled to [5%, 95%]
    final sigmoid = 1.0 / (1.0 + math.exp(-12.0 * (composite - 0.5)));
    return ((sigmoid * 90.0) + 5.0).clamp(0.0, 100.0);
  }

  /// Suggests the number of productive minutes for the next session.
  static int _suggestNextSession({
    required double consistencyPct,
    required int todayProductiveMinutes,
    required int targetDailyMinutes,
  }) {
    final remaining = targetDailyMinutes - todayProductiveMinutes;
    if (remaining <= 0) {
      // Day complete — suggest a light review session
      return 30;
    }
    // Cap at 90-minute focus blocks (Pomodoro-style)
    return math.min(remaining, 90);
  }
}

/// Immutable result produced by [StudyScoreEngine.compute].
class StudyScore {
  const StudyScore({
    required this.total,
    required this.volumeScore,
    required this.consistencyScore,
    required this.performanceScore,
    required this.coverageScore,
    required this.momentumScore,
    required this.approvalProbabilityPct,
    required this.nextSessionMinutes,
    required this.weeklyProgressPct,
  });

  /// Holistic score 0–1000.
  final int total;

  /// Individual dimension scores.
  final int volumeScore;
  final int consistencyScore;
  final int performanceScore;
  final int coverageScore;
  final int momentumScore;

  /// Probability of approval 0–100%.
  final double approvalProbabilityPct;

  /// Suggested duration for the next study session (minutes).
  final int nextSessionMinutes;

  /// Weekly study progress 0.0–1.0 relative to target.
  final double weeklyProgressPct;

  /// Label for the study score tier.
  String get tierLabel {
    if (total >= 850) return 'Elite';
    if (total >= 700) return 'Avançado';
    if (total >= 500) return 'Intermediário';
    if (total >= 300) return 'Iniciante';
    return 'Em Formação';
  }

  static const empty = StudyScore(
    total: 0,
    volumeScore: 0,
    consistencyScore: 0,
    performanceScore: 0,
    coverageScore: 0,
    momentumScore: 0,
    approvalProbabilityPct: 0,
    nextSessionMinutes: 60,
    weeklyProgressPct: 0,
  );
}
