import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../controllers/dashboard_controller.dart';
import '../core/analytics/study_score_engine.dart';
import '../core/gamification/gamification_engine.dart';
import '../shared/widgets/animated_progress.dart';

/// A summary insight card that combines StudyScore + Gamification + approval probability.
/// Designed to sit at the top of the Performance screen as a hero insight panel.
class PerformanceInsightCard extends ConsumerWidget {
  const PerformanceInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(studyScoreProvider);
    final g = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final approvalColor = score.approvalProbabilityPct >= 70
        ? DesignTokens.accent
        : score.approvalProbabilityPct >= 45
            ? DesignTokens.warning
            : DesignTokens.error;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primary.withValues(alpha: 0.12),
            isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg1,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.brLg,
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.25)),
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.15),
                    borderRadius: DesignTokens.brSm,
                  ),
                  child: const Icon(Icons.insights_rounded,
                      size: 18, color: DesignTokens.primary),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Visão Geral da Performance',
                  style: AppTypography.headingSm.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // Score + Approval side by side
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    label: 'Study Score',
                    value: '${score.total}',
                    unit: '/ 1000',
                    color: DesignTokens.primary,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.lightBorder,
                ),
                Expanded(
                  child: _StatBlock(
                    label: 'Prob. Aprovação',
                    value:
                        '${score.approvalProbabilityPct.toStringAsFixed(0)}%',
                    color: approvalColor,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.lightBorder,
                ),
                Expanded(
                  child: _StatBlock(
                    label: 'Nível',
                    value: '${g.level}',
                    unit: g.rankLabel,
                    color: DesignTokens.secondary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),

            // Score progress bar
            AnimatedProgress(
              value: score.total / 1000.0,
              label: 'Score Geral',
              showPercentage: false,
              height: 7,
              gradient: DesignTokens.primaryGradient,
            ),
            const SizedBox(height: Spacing.sm),

            // Approval probability bar
            AnimatedProgress(
              value: score.approvalProbabilityPct / 100.0,
              label: 'Probabilidade de Aprovação',
              showPercentage: false,
              height: 7,
              gradient: LinearGradient(
                colors: [approvalColor.withValues(alpha: 0.7), approvalColor],
              ),
            ),
            const SizedBox(height: Spacing.md),

            // 5 dimension mini-bars
            Text(
              'Dimensões',
              style: AppTypography.labelSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            _DimensionBars(score: score, isDark: isDark),

            if (score.nextSessionMinutes > 0) ...[
              const SizedBox(height: Spacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm + 2, vertical: Spacing.xs + 2),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withValues(alpha: 0.1),
                  borderRadius: DesignTokens.brXl,
                  border: Border.all(
                      color: DesignTokens.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded,
                        size: 14, color: DesignTokens.accent),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      'Próxima sessão sugerida: ${score.nextSessionMinutes}min de foco',
                      style: AppTypography.labelSm.copyWith(
                        color: DesignTokens.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.unit,
  });
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.scoreSm.copyWith(color: color),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextMuted
                        : DesignTokens.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DimensionBars extends StatelessWidget {
  const _DimensionBars({required this.score, required this.isDark});
  final StudyScore score;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dims = [
      ('Volume', score.volumeScore / 200.0, DesignTokens.primary),
      ('Consistência', score.consistencyScore / 250.0, DesignTokens.secondary),
      ('Performance', score.performanceScore / 300.0, DesignTokens.accent),
      ('Cobertura', score.coverageScore / 150.0, DesignTokens.warning),
      ('Momentum', score.momentumScore / 100.0, const Color(0xFFFF6B9D)),
    ];

    return Column(
      children: dims
          .map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      d.$1,
                      style: AppTypography.overline.copyWith(
                        color: isDark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.lightTextSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedProgress(
                      value: d.$2.clamp(0.0, 1.0),
                      showPercentage: false,
                      height: 5,
                      gradient: LinearGradient(
                        colors: [
                          d.$3.withValues(alpha: 0.6),
                          d.$3,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
