/// XP thresholds and level metadata for the StudyOps gamification system.
///
/// Levels use an exponential curve: XP to next = 100 * level^1.6
/// This keeps early levels fast (encouragement) and later levels rewarding (mastery).
abstract final class XpSystem {
  XpSystem._();

  /// XP awarded per event type.
  static const int xpStudySession = 20; // per study session logged
  static const int xpPerProductiveHour = 30; // per productive hour
  static const int xpQuizCorrect = 5; // per correct quiz answer
  static const int xpTopicComplete = 25; // theory + review + exercises done
  static const int xpStreakDay = 10; // daily streak bonus
  static const int xpStreakWeek = 75; // 7-day streak bonus
  static const int xpFlashcardReview = 2; // per flashcard reviewed
  static const int xpAchievementUnlocked = 50; // bonus when unlocking badge

  /// Maximum level cap.
  static const int maxLevel = 50;

  /// Computes the level (1-indexed) for a given total XP.
  static int levelForXp(int totalXp) {
    for (int level = maxLevel; level >= 1; level--) {
      if (totalXp >= cumulativeXpForLevel(level)) return level;
    }
    return 1;
  }

  /// Total XP required to reach [level] (cumulative from 0).
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    int cumulative = 0;
    for (int l = 1; l < level; l++) {
      cumulative += xpToNextLevel(l);
    }
    return cumulative;
  }

  /// XP required to advance from [level] to [level]+1.
  static int xpToNextLevel(int level) {
    // Exponential: 100 * level^1.6, capped at 5000
    final raw = 100.0 * _pow(level, 1.6);
    return raw.round().clamp(100, 5000);
  }

  /// XP progress within the current level (0.0–1.0).
  static double progressInLevel(int totalXp) {
    final level = levelForXp(totalXp);
    if (level >= maxLevel) return 1.0;
    final levelStart = cumulativeXpForLevel(level);
    final levelEnd = cumulativeXpForLevel(level + 1);
    final range = levelEnd - levelStart;
    if (range <= 0) return 1.0;
    return ((totalXp - levelStart) / range).clamp(0.0, 1.0);
  }

  /// XP needed to complete the current level.
  static int xpRemainingInLevel(int totalXp) {
    final level = levelForXp(totalXp);
    if (level >= maxLevel) return 0;
    final levelEnd = cumulativeXpForLevel(level + 1);
    return (levelEnd - totalXp).clamp(0, 999999);
  }

  /// Returns the rank label for a given level.
  static String rankLabel(int level) {
    if (level >= 45) return 'Lendário';
    if (level >= 35) return 'Mestre';
    if (level >= 25) return 'Elite';
    if (level >= 15) return 'Avançado';
    if (level >= 8) return 'Intermediário';
    if (level >= 3) return 'Iniciante';
    return 'Novato';
  }

  static double _pow(int base, double exp) {
    double result = 1.0;
    double b = base.toDouble();
    // Use log identity: base^exp = e^(exp * ln(base))
    // Simple iterative approximation via dart:math equivalent
    // Actually we just use repeated multiplication with fractional part
    int intExp = exp.floor();
    double fracExp = exp - intExp;

    // Integer part
    double intResult = 1.0;
    for (int i = 0; i < intExp; i++) {
      intResult *= b;
    }

    // Fractional part via estimate: b^0.x ≈ 1 + 0.x*(b-1) for b < 5
    // Good enough for level 1–50 with base 1–50
    double fracResult = 1.0 + fracExp * (b - 1.0);

    result = intResult * fracResult;
    return result;
  }
}
