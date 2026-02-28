import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';
import '../../core/gamification/gamification_engine.dart';
import '../../shared/widgets/animated_progress.dart';

/// Hero card displaying the user's current XP, level, rank, and level progress bar.
/// Designed to appear at the top of the achievements / profile screen.
class XpLevelCard extends ConsumerStatefulWidget {
  const XpLevelCard({super.key});

  @override
  ConsumerState<XpLevelCard> createState() => _XpLevelCardState();
}

class _XpLevelCardState extends ConsumerState<XpLevelCard>
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
    final g = ref.watch(gamificationProvider);
    final rarityColor = _rankColor(g.level);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              rarityColor.withValues(alpha: 0.15),
              DesignTokens.darkBg2,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: DesignTokens.brLg,
          border: Border.all(color: rarityColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level badge + rank row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Level badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          rarityColor,
                          rarityColor.withValues(alpha: 0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: rarityColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${g.level}',
                        style: AppTypography.scoreMd.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.rankLabel,
                          style: AppTypography.headingMd.copyWith(
                            color: rarityColor,
                          ),
                        ),
                        Text(
                          '${g.totalXp} XP total',
                          style: AppTypography.bodySm.copyWith(
                            color: DesignTokens.darkTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Achievements count badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${g.unlockedIds.length}',
                        style: AppTypography.scoreSm.copyWith(
                          color: DesignTokens.accent,
                        ),
                      ),
                      Text(
                        'conquistas',
                        style: AppTypography.labelSm.copyWith(
                          color: DesignTokens.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),

              // XP progress bar to next level
              AnimatedProgress(
                value: g.progressInLevel,
                label: 'Nível ${g.level} → ${g.level + 1}',
                subtitle: '${g.xpRemainingInLevel} XP para o próximo nível',
                gradient: LinearGradient(
                  colors: [rarityColor.withValues(alpha: 0.7), rarityColor],
                ),
                height: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rankColor(int level) {
    if (level >= 45) return const Color(0xFFFFD700); // gold — lendário
    if (level >= 35) return const Color(0xFFB5B9FF); // lilac — mestre
    if (level >= 25) return const Color(0xFF00D9AA); // teal — elite
    if (level >= 15) return const Color(0xFF00B4D8); // blue — avançado
    if (level >= 8) return const Color(0xFF7C6FFF); // purple — intermediário
    return const Color(0xFF8B8B8B); // gray — iniciante/novato
  }
}

/// Compact XP strip widget for embedding in the dashboard header area.
class XpMiniBar extends ConsumerWidget {
  const XpMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gamificationProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.xs + 2),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        borderRadius: DesignTokens.brXl,
        border: Border.all(color: DesignTokens.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level badge
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              gradient: DesignTokens.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${g.level}',
                style: AppTypography.labelSm.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          // Mini progress bar
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: DesignTokens.brXl,
              child: LinearProgressIndicator(
                value: g.progressInLevel,
                minHeight: 4,
                backgroundColor: DesignTokens.darkBg4,
                valueColor: const AlwaysStoppedAnimation(DesignTokens.primary),
              ),
            ),
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            '${g.totalXp} XP',
            style: AppTypography.labelSm.copyWith(
              color: DesignTokens.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
