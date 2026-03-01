import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/performance_controller.dart';
import '../core/gamification/gamification_engine.dart';
import '../shared/widgets/animated_progress.dart';

/// A premium weekly digest card for the dashboard.
/// Shows highlights from the last 7 days: hours studied, questions answered,
/// streak, XP earned, and a motivational message.
class WeeklyDigestCard extends ConsumerWidget {
  const WeeklyDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final perf = ref.watch(performanceStatsProvider);
    final g = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dashAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final weekHours = data.weekMinutes / 60.0;
        const targetHours = 21.0; // 3h/day ×7
        final weekProgress = (weekHours / targetHours).clamp(0.0, 1.0);

        final highlights = _buildHighlights(data, perf, g);
        final message = _motivationalMessage(weekProgress, data.streakDays);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.secondary.withValues(alpha: 0.12),
                isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg1,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: DesignTokens.brLg,
            border: Border.all(
                color: DesignTokens.secondary.withValues(alpha: 0.3)),
            boxShadow: DesignTokens.elevationLow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: DesignTokens.secondary.withValues(alpha: 0.15),
                        borderRadius: DesignTokens.brSm,
                      ),
                      child: const Icon(Icons.calendar_view_week_rounded,
                          size: 18, color: DesignTokens.secondary),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'Resumo da Semana',
                        style: AppTypography.headingSm.copyWith(
                          color: isDark
                              ? DesignTokens.darkTextPrimary
                              : DesignTokens.lightTextPrimary,
                        ),
                      ),
                    ),
                    // Streak badge
                    if (data.streakDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: 0.12),
                          borderRadius: DesignTokens.brXl,
                          border: Border.all(
                              color: const Color(0xFFFF6B35)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              '${data.streakDays}d',
                              style: AppTypography.labelSm.copyWith(
                                color: const Color(0xFFFF6B35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.md),

                // Weekly hours progress
                AnimatedProgress(
                  value: weekProgress,
                  label: 'Horas esta semana',
                  subtitle:
                      '${weekHours.toStringAsFixed(1)}h de ${targetHours.toStringAsFixed(0)}h meta',
                  height: 7,
                  gradient: const LinearGradient(
                    colors: [DesignTokens.secondary, Color(0xFF00B4D8)],
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Stat highlights
                AnimationLimiter(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Spacing.sm,
                    crossAxisSpacing: Spacing.sm,
                    childAspectRatio: 2.6,
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 300),
                      childAnimationBuilder: (w) => FadeInAnimation(child: w),
                      children: highlights
                          .map((h) => _StatChip(
                                icon: h.$1,
                                label: h.$2,
                                value: h.$3,
                                color: h.$4,
                                isDark: isDark,
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),

                // Motivational message
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md, vertical: Spacing.sm),
                  decoration: BoxDecoration(
                    color: DesignTokens.secondary.withValues(alpha: 0.08),
                    borderRadius: DesignTokens.brMd,
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          message,
                          style: AppTypography.bodySm.copyWith(
                            color: isDark
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.lightTextSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<(IconData, String, String, Color)> _buildHighlights(
    DashboardData data,
    PerformanceStats perf,
    GamificationState g,
  ) {
    final weekHours = data.weekMinutes / 60.0;
    return [
      (
        Icons.timer_rounded,
        'Horas estudadas',
        '${weekHours.toStringAsFixed(1)}h',
        DesignTokens.primary,
      ),
      (
        Icons.quiz_rounded,
        'Questões semanais',
        '${perf.totalQuestions}',
        DesignTokens.accent,
      ),
      (
        Icons.bolt_rounded,
        'XP total',
        '${g.totalXp} XP',
        DesignTokens.secondary,
      ),
      (
        Icons.trending_up_rounded,
        'Acerto médio',
        '${perf.averageAccuracy.toStringAsFixed(0)}%',
        DesignTokens.warning,
      ),
    ];
  }

  String _motivationalMessage(double weekProgress, int streakDays) {
    if (weekProgress >= 1.0) {
      return 'Meta semanal batida! Você está em modo elite. 🏆';
    }
    if (weekProgress >= 0.75) {
      return 'Quase lá! Mais um empurrão e a semana está completa.';
    }
    if (streakDays >= 7) {
      return '7+ dias de streak. Sua consistência é o seu maior diferencial.';
    }
    if (weekProgress >= 0.4) {
      return 'Bom progresso! Mantenha o ritmo para bater a meta da semana.';
    }
    if (streakDays >= 3) {
      return 'Streak de $streakDays dias! Continue assim e a aprovação vem naturalmente.';
    }
    return 'Cada hora estudada hoje é um investimento no seu futuro. Vá em frente!';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm, vertical: Spacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: DesignTokens.brSm,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTypography.labelSm.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.overline.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextMuted
                        : DesignTokens.lightTextMuted,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
