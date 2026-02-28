import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../core/gamification/gamification_engine.dart';
import '../widgets/xp_level_card.dart';
import '../widgets/achievements_grid.dart';

/// Full Achievements & Profile screen.
/// Sections:
///   1. XP Level Card (hero section)
///   2. Stats summary row (unlocked count, total XP, current streak proxy)
///   3. Recent achievements (up to 6 unlocked)
///   4. All achievements grid (full catalog, locked items greyed out)
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unlockedCount = g.unlockedIds.length;
    final totalCount =
        g.unlockedAchievements.length + g.lockedAchievements.length;
    final coveragePct = totalCount > 0
        ? (unlockedCount / totalCount * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: AnimationLimiter(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width >= 600 ? 28 : 18,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 40,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  // ── Page Header ────────────────────────────────────────
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conquistas',
                            style: AppTypography.displaySm.copyWith(
                              color: isDark
                                  ? DesignTokens.darkTextPrimary
                                  : DesignTokens.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '$unlockedCount de $totalCount desbloqueadas ($coveragePct%)',
                            style: AppTypography.bodySm.copyWith(
                              color: isDark
                                  ? DesignTokens.darkTextMuted
                                  : DesignTokens.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

                  // ── Hero: XP Level Card ────────────────────────────────
                  const XpLevelCard(),
                  const SizedBox(height: Spacing.lg),

                  // ── Stats Row ─────────────────────────────────────────
                  _StatsRow(g: g, isDark: isDark),
                  const SizedBox(height: Spacing.xl),

                  // ── Recently Unlocked ─────────────────────────────────
                  if (g.unlockedAchievements.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Recentemente Desbloqueadas',
                      icon: Icons.new_releases_rounded,
                      color: DesignTokens.accent,
                      isDark: isDark,
                    ),
                    const SizedBox(height: Spacing.sm),
                    const AchievementsGrid(
                      showLocked: false,
                      maxItems: 6,
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],

                  // ── Full Catalog ──────────────────────────────────────
                  _SectionHeader(
                    title: 'Catálogo Completo',
                    icon: Icons.emoji_events_rounded,
                    color: DesignTokens.warning,
                    isDark: isDark,
                  ),
                  const SizedBox(height: Spacing.sm),
                  const AchievementsGrid(showLocked: true),
                  const SizedBox(height: Spacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.g, required this.isDark});
  final GamificationState g;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? DesignTokens.darkBg3 : DesignTokens.lightBg2;
    final borderColor =
        isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;

    final stats = [
      (
        label: 'XP Total',
        value: '${g.totalXp}',
        icon: Icons.bolt_rounded,
        color: DesignTokens.primary,
      ),
      (
        label: 'Nível',
        value: '${g.level}',
        icon: Icons.star_rounded,
        color: const Color(0xFFFFD700),
      ),
      (
        label: 'Conquistas',
        value: '${g.unlockedIds.length}',
        icon: Icons.emoji_events_rounded,
        color: DesignTokens.accent,
      ),
      (
        label: 'Rank',
        value: g.rankLabel,
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFB5B9FF),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacing.sm,
      crossAxisSpacing: Spacing.sm,
      childAspectRatio: 2.2,
      children: stats
          .map((s) => Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: DesignTokens.brMd,
                  border: Border.all(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md, vertical: Spacing.sm),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: s.color.withValues(alpha: 0.12),
                          borderRadius: DesignTokens.brSm,
                        ),
                        child: Icon(s.icon, color: s.color, size: 18),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.value,
                              style: AppTypography.headingSm.copyWith(
                                color: isDark
                                    ? DesignTokens.darkTextPrimary
                                    : DesignTokens.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              s.label,
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? DesignTokens.darkTextMuted
                                    : DesignTokens.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: Spacing.sm),
        Text(
          title,
          style: AppTypography.headingSm.copyWith(
            color: isDark
                ? DesignTokens.darkTextPrimary
                : DesignTokens.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
