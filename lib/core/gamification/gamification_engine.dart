import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/performance_controller.dart';
import '../../controllers/subject_controller.dart';
import '../../controllers/flashcard_controller.dart';
import 'xp_system.dart';
import 'achievement_catalog.dart';

export 'xp_system.dart';
export 'achievement_catalog.dart';

/// A snapshot of the user's current gamification state.
class GamificationState {
  const GamificationState({
    required this.totalXp,
    required this.level,
    required this.progressInLevel,
    required this.xpRemainingInLevel,
    required this.rankLabel,
    required this.unlockedIds,
    required this.newlyUnlocked,
  });

  final int totalXp;
  final int level;

  /// 0.0–1.0 progress within the current level.
  final double progressInLevel;

  /// XP remaining to reach next level.
  final int xpRemainingInLevel;

  final String rankLabel;

  /// All achievement IDs that have been earned.
  final Set<AchievementId> unlockedIds;

  /// Achievements unlocked *this* computation cycle (for toast notifications).
  final List<AchievementDef> newlyUnlocked;

  /// Convenience: list of all unlocked [AchievementDef]s in order.
  List<AchievementDef> get unlockedAchievements =>
      AchievementCatalog.all.where((a) => unlockedIds.contains(a.id)).toList();

  /// Convenience: list of still-locked [AchievementDef]s.
  List<AchievementDef> get lockedAchievements =>
      AchievementCatalog.all.where((a) => !unlockedIds.contains(a.id)).toList();

  static const empty = GamificationState(
    totalXp: 0,
    level: 1,
    progressInLevel: 0.0,
    xpRemainingInLevel: 100,
    rankLabel: 'Novato',
    unlockedIds: {},
    newlyUnlocked: [],
  );
}

/// Derives the full gamification state from all existing data providers.
/// Zero Firebase reads — purely computed from Riverpod state.
final gamificationProvider = Provider<GamificationState>((ref) {
  final dashAsync = ref.watch(dashboardProvider);
  final perf = ref.watch(performanceStatsProvider);
  // subjects available via allTopics filter — not needed directly
  ref.watch(subjectsProvider); // keep alive for dependency tracking
  final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];
  final studyScore = ref.watch(studyScoreProvider);
  final dueFlashcards = ref.watch(dueFlashcardsProvider).valueOrNull ?? [];

  return dashAsync.when(
    loading: () => GamificationState.empty,
    error: (_, __) => GamificationState.empty,
    data: (data) {
      // ── 1. Compute raw XP from all signals ────────────────────────────
      int xp = 0;

      // Study sessions: approximate from total month minutes
      // (1 session ≈ 30 min average)
      final approxSessions = (data.monthMinutes / 30).round();
      xp += approxSessions * XpSystem.xpStudySession;

      // Productive hours total (week + estimate from month)
      final productiveHours =
          ((data.weekMinutes + data.monthMinutes) / 60).floor();
      xp += productiveHours * XpSystem.xpPerProductiveHour;

      // Quiz correct answers
      xp += perf.totalCorrect * XpSystem.xpQuizCorrect;

      // Completed topics
      final completedTopics = allTopics
          .where((t) => t.isTheoryDone && t.isReviewDone && t.isExercisesDone)
          .length;
      xp += completedTopics * XpSystem.xpTopicComplete;

      // Streak bonus
      xp += data.streakDays * XpSystem.xpStreakDay;
      if (data.streakDays >= 7) xp += XpSystem.xpStreakWeek;

      // Flashcards due = rough proxy for total reviewed (inverse: fewer due = more reviewed)
      // simple approach: add a fixed base if dueFlashcards is small (user is keeping up)
      if (dueFlashcards.isEmpty) xp += 20;

      // ── 2. Determine unlocked achievements ────────────────────────────
      final totalMonthMinutes = data.monthMinutes;
      final totalMinutesEst =
          data.weekMinutes + totalMonthMinutes; // rough cumulative estimate

      final unlockedIds = <AchievementId>{};

      // Streak milestones
      if (data.streakDays >= 3) unlockedIds.add(AchievementId.streak3);
      if (data.streakDays >= 7) unlockedIds.add(AchievementId.streak7);
      if (data.streakDays >= 14) unlockedIds.add(AchievementId.streak14);
      if (data.streakDays >= 30) unlockedIds.add(AchievementId.streak30);

      // Study volume (in minutes → hours)
      final totalHours = totalMinutesEst ~/ 60;
      if (totalMinutesEst > 0) unlockedIds.add(AchievementId.firstSession);
      if (totalHours >= 10) unlockedIds.add(AchievementId.tenHours);
      if (totalHours >= 50) unlockedIds.add(AchievementId.fiftyHours);
      if (totalHours >= 100) unlockedIds.add(AchievementId.hundredHours);

      // Quiz performance
      if (perf.totalQuestions > 0) unlockedIds.add(AchievementId.firstQuiz);
      if (perf.averageAccuracy >= 80) unlockedIds.add(AchievementId.accuracy80);
      if (perf.averageAccuracy >= 90) unlockedIds.add(AchievementId.accuracy90);
      if (perf.totalQuestions >= 100) {
        unlockedIds.add(AchievementId.questionsHundred);
      }

      // Syllabus coverage
      if (completedTopics >= 1) unlockedIds.add(AchievementId.firstTopicDone);
      if (completedTopics >= 10) unlockedIds.add(AchievementId.tenTopicsDone);
      if (allTopics.isNotEmpty) {
        final coverage = completedTopics / allTopics.length;
        if (coverage >= 0.5) unlockedIds.add(AchievementId.halfSyllabus);
        if (coverage >= 1.0) unlockedIds.add(AchievementId.fullSyllabus);
      }

      // Flashcards
      if (dueFlashcards.isNotEmpty || completedTopics > 0) {
        // Unlocked if user has any flashcard activity
        unlockedIds.add(AchievementId.firstFlashcard);
      }

      // Consistency
      if (data.consistencyPct >= 1.0) {
        unlockedIds.add(AchievementId.sevenDayConsistency);
      }

      // Study Score milestones
      if (studyScore.total >= 500) unlockedIds.add(AchievementId.score500);
      if (studyScore.total >= 800) unlockedIds.add(AchievementId.score800);
      if (studyScore.total >= 1000) unlockedIds.add(AchievementId.score1000);

      // Add XP from unlocked achievements
      for (final id in unlockedIds) {
        final def = AchievementCatalog.byId(id);
        if (def != null) xp += def.xpReward;
      }

      // ── 3. Level computation ─────────────────────────────────────────
      final level = XpSystem.levelForXp(xp);

      // Level milestones
      if (level >= 5) unlockedIds.add(AchievementId.level5);
      if (level >= 10) unlockedIds.add(AchievementId.level10);
      if (level >= 25) unlockedIds.add(AchievementId.level25);

      return GamificationState(
        totalXp: xp,
        level: level,
        progressInLevel: XpSystem.progressInLevel(xp),
        xpRemainingInLevel: XpSystem.xpRemainingInLevel(xp),
        rankLabel: XpSystem.rankLabel(level),
        unlockedIds: unlockedIds,
        newlyUnlocked: const [], // toast logic can be added per-session
      );
    },
  );
});
