import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_tokens.dart';
import '../../core/design_system/typography_scale.dart';
import '../../core/design_system/spacing_system.dart';
import '../../core/gamification/gamification_engine.dart';

/// Grid of achievement badges — shows unlocked in full color, locked greyed out.
class AchievementsGrid extends ConsumerWidget {
  const AchievementsGrid({super.key, this.showLocked = true, this.maxItems});

  final bool showLocked;
  final int? maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = showLocked ? AchievementCatalog.all : g.unlockedAchievements;

    final displayItems =
        maxItems != null ? items.take(maxItems!).toList() : items;

    if (displayItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Text(
            'Nenhuma conquista ainda. Continue estudando!',
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: Spacing.sm,
        crossAxisSpacing: Spacing.sm,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) {
        final def = displayItems[i];
        final isUnlocked = g.unlockedIds.contains(def.id);
        return _AchievementBadge(def: def, isUnlocked: isUnlocked);
      },
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.def, required this.isUnlocked});
  final AchievementDef def;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isUnlocked ? def.color : Colors.grey.shade600;
    final bgColor = isUnlocked
        ? def.color.withValues(alpha: 0.12)
        : (isDark ? DesignTokens.darkBg4 : DesignTokens.lightBg2);
    final borderColor = isUnlocked
        ? def.color.withValues(alpha: 0.3)
        : (isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder);

    return Tooltip(
      message: isUnlocked ? def.description : 'Bloqueado: ${def.description}',
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: DesignTokens.brMd,
          border: Border.all(color: borderColor),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: def.color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rarity glow ring for epic/legendary
              if (isUnlocked &&
                  def.rarity.index >= AchievementRarity.epic.index)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: def.color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(def.icon, color: color, size: 32),
                )
              else
                Icon(
                  isUnlocked ? def.icon : Icons.lock_rounded,
                  color: color,
                  size: 32,
                ),
              const SizedBox(height: Spacing.xs),
              Text(
                def.title,
                style: AppTypography.labelSm.copyWith(
                  color: isUnlocked
                      ? (isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.lightTextPrimary)
                      : Colors.grey.shade500,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked && def.xpReward > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '+${def.xpReward} XP',
                  style: AppTypography.overline.copyWith(
                    color: color,
                    fontSize: 9,
                  ),
                ),
              ],
              if (isUnlocked && def.rarity != AchievementRarity.common)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: def.color.withValues(alpha: 0.15),
                    borderRadius: DesignTokens.brXl,
                  ),
                  child: Text(
                    _rarityLabel(def.rarity),
                    style: AppTypography.overline.copyWith(
                      color: def.color,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _rarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.rare:
        return 'RARO';
      case AchievementRarity.epic:
        return 'ÉPICO';
      case AchievementRarity.legendary:
        return 'LENDÁRIO';
      default:
        return '';
    }
  }
}
