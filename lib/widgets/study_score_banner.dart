import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';
import '../../core/analytics/study_score_engine.dart';
import '../../controllers/dashboard_controller.dart';
import '../../shared/widgets/animated_progress.dart';

/// Hero banner for the dashboard showing the holistic Study Score,
/// approval probability, weekly progress and next session recommendation.
class StudyScoreBanner extends ConsumerStatefulWidget {
  const StudyScoreBanner({super.key});

  @override
  ConsumerState<StudyScoreBanner> createState() => _StudyScoreBannerState();
}

class _StudyScoreBannerState extends ConsumerState<StudyScoreBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: DesignTokens.durationXSlow,
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = ref.watch(studyScoreProvider);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.primary.withValues(alpha: 0.12),
              DesignTokens.secondary.withValues(alpha: 0.07),
              DesignTokens.accent.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: DesignTokens.brLg,
          border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.25),
          ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: Spacing.xxs + 1),
                    decoration: const BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: DesignTokens.brSm,
                    ),
                    child: Text(
                      'STUDY SCORE',
                      style: AppTypography.overline.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _TierBadge(label: score.tierLabel),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Score + Approval row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Big score number
                  _AnimatedScoreCounter(score: score.total),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/ 1000',
                      style: AppTypography.headingSm.copyWith(
                        color: DesignTokens.darkTextMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Approval probability
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${score.approvalProbabilityPct.toStringAsFixed(0)}%',
                        style: AppTypography.scoreMd.copyWith(
                          color:
                              _probabilityColor(score.approvalProbabilityPct),
                        ),
                      ),
                      Text(
                        'prob. aprovação',
                        style: AppTypography.labelSm.copyWith(
                          color: DesignTokens.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // Weekly progress bar
              AnimatedProgress(
                value: score.weeklyProgressPct,
                label: 'Meta semanal',
                gradient: DesignTokens.primaryGradient,
                height: 6,
              ),
              const SizedBox(height: Spacing.md),

              // Score dimensions row
              _DimensionRow(score: score),
              const SizedBox(height: Spacing.md),

              // Next session CTA
              _NextSessionChip(minutes: score.nextSessionMinutes),
            ],
          ),
        ),
      ),
    );
  }

  Color _probabilityColor(double pct) {
    if (pct >= 70) return DesignTokens.accent;
    if (pct >= 45) return DesignTokens.warning;
    return DesignTokens.error;
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm, vertical: Spacing.xxs),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.15),
        borderRadius: DesignTokens.brXl,
        border: Border.all(
          color: DesignTokens.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(color: DesignTokens.primary),
      ),
    );
  }
}

class _AnimatedScoreCounter extends StatefulWidget {
  const _AnimatedScoreCounter({required this.score});
  final int score;

  @override
  State<_AnimatedScoreCounter> createState() => _AnimatedScoreCounterState();
}

class _AnimatedScoreCounterState extends State<_AnimatedScoreCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: DesignTokens.durationXSlow,
    );
    _rebuildAnimation(0, widget.score);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedScoreCounter old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _rebuildAnimation(_anim.value, widget.score);
      _ctrl
        ..reset()
        ..forward();
    }
  }

  void _rebuildAnimation(int from, int to) {
    _anim = IntTween(begin: from, end: to).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        '${_anim.value}',
        style: AppTypography.scoreLg.copyWith(
          color: DesignTokens.primary,
          fontSize: 52,
        ),
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({required this.score});
  final StudyScore score;

  @override
  Widget build(BuildContext context) {
    final dims = [
      ('Vol.', score.volumeScore, 200),
      ('Consist.', score.consistencyScore, 250),
      ('Perf.', score.performanceScore, 300),
      ('Cobert.', score.coverageScore, 150),
      ('Streak', score.momentumScore, 100),
    ];

    return Row(
      children: dims.map((d) {
        final label = d.$1;
        final value = d.$2;
        final max = d.$3;
        final pct = value / max;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Text(
                  label,
                  style: AppTypography.overline.copyWith(
                    color: DesignTokens.darkTextMuted,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: DesignTokens.brXl,
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor:
                        DesignTokens.darkBg4.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(
                        DesignTokens.secondary,
                        DesignTokens.primary,
                        pct,
                      )!,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value',
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 9,
                    color: DesignTokens.darkTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NextSessionChip extends StatelessWidget {
  const _NextSessionChip({required this.minutes});
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs + 2),
      decoration: BoxDecoration(
        color: DesignTokens.accent.withValues(alpha: 0.12),
        borderRadius: DesignTokens.brXl,
        border: Border.all(color: DesignTokens.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: DesignTokens.accent),
          const SizedBox(width: Spacing.xs),
          Text(
            'Próxima sessão sugerida: ${minutes}min de foco',
            style: AppTypography.labelMd.copyWith(
              color: DesignTokens.accent,
            ),
          ),
        ],
      ),
    );
  }
}
