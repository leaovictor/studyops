import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';
import '../../core/analytics/study_plan_engine.dart';
import '../../shared/widgets/animated_progress.dart';
import '../../shared/widgets/state_views.dart';

/// Shows the top weak subjects with weakness score bars and recommended boost.
/// Designed to be embedded in the schedule/study plan screens.
class WeaknessInsightCard extends ConsumerWidget {
  const WeaknessInsightCard({super.key, this.maxItems = 3});

  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakSubjects = ref.watch(weakSubjectsProvider);
    final adaptation = ref.watch(weeklyAdaptationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? DesignTokens.darkBg3 : DesignTokens.lightBg1;
    final borderColor =
        isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: DesignTokens.brLg,
        border: Border.all(color: borderColor),
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.md, Spacing.md, Spacing.md, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.12),
                    borderRadius: DesignTokens.brSm,
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      size: 18, color: DesignTokens.warning),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'Pontos de Atenção',
                  style: AppTypography.headingSm.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                if (weakSubjects.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.12),
                      borderRadius: DesignTokens.brXl,
                    ),
                    child: Text(
                      '${weakSubjects.length} matéria${weakSubjects.length > 1 ? 's' : ''}',
                      style: AppTypography.labelSm
                          .copyWith(color: DesignTokens.warning),
                    ),
                  ),
              ],
            ),
          ),

          // Weekly adaptation message
          if (adaptation != null && adaptation.boostSubjectIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, Spacing.sm, Spacing.md, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm + 2, vertical: Spacing.xs + 2),
                decoration: BoxDecoration(
                  color: DesignTokens.secondary.withValues(alpha: 0.08),
                  borderRadius: DesignTokens.brSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: DesignTokens.secondary),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        adaptation.message,
                        style: AppTypography.bodySm.copyWith(
                          color: DesignTokens.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: Spacing.sm),

          // Body
          if (weakSubjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: AppEmptyView(
                icon: Icons.check_circle_rounded,
                iconColor: DesignTokens.accent,
                title: 'Nenhum ponto crítico!',
                subtitle: 'Continue estudando para manter o desempenho.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weakSubjects.take(maxItems).length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color:
                    isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              ),
              itemBuilder: (context, i) {
                final ws = weakSubjects[i];
                return _WeakSubjectTile(weakSubject: ws, isDark: isDark);
              },
            ),

          if (weakSubjects.length > maxItems)
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Center(
                child: Text(
                  '+${weakSubjects.length - maxItems} matéria(s) com atenção necessária',
                  style: AppTypography.labelSm.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextMuted
                        : DesignTokens.lightTextMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeakSubjectTile extends StatelessWidget {
  const _WeakSubjectTile({required this.weakSubject, required this.isDark});
  final WeakSubject weakSubject;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ws = weakSubject;
    final subjectColor = _parseColor(ws.subject.color);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject color dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: subjectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  ws.subject.name,
                  style: AppTypography.labelLg.copyWith(
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // Boost chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.warning.withValues(alpha: 0.12),
                  borderRadius: DesignTokens.brXl,
                ),
                child: Text(
                  '+${ws.recommendedExtraMinutes}min/dia',
                  style: AppTypography.labelSm.copyWith(
                    color: DesignTokens.warning,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          AnimatedProgress(
            value: ws.weaknessScore,
            showPercentage: false,
            height: 5,
            gradient: LinearGradient(
              colors: [
                subjectColor.withValues(alpha: 0.6),
                DesignTokens.warning,
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            ws.reason,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return DesignTokens.primary;
    }
  }
}
