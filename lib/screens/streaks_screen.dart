import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../services/study_log_service.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Returns a map of dateKey → total minutes for the last 365 days.
final yearHeatmapProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {};

  final service = StudyLogService();
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 364));

  String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final logs = await service.getLogsForRange(
    user.uid,
    dateKey(from),
    dateKey(now),
  );

  final map = <String, int>{};
  for (final log in logs) {
    map[log.date] = (map[log.date] ?? 0) + log.minutes;
  }
  return map;
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashAsync = ref.watch(dashboardProvider);
    final yearAsync = ref.watch(yearHeatmapProvider);

    return Material(
      color: isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              '🔥 Hábito de Estudos',
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
              ),
            ),
          ),
          Expanded(
            child: dashAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (data) => yearAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (yearMap) {
                  final stats = _computeStreakStats(yearMap, data.streakDays);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg, vertical: Spacing.md),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 380),
                          childAnimationBuilder: (w) => SlideAnimation(
                            verticalOffset: 25,
                            child: FadeInAnimation(child: w),
                          ),
                          children: [
                            // ── Hero streak row ───────────────────────────────
                            _HeroStreakRow(stats: stats, isDark: isDark),
                            const SizedBox(height: Spacing.xl),

                            // ── Year calendar ─────────────────────────────────
                            _YearCalendar(yearMap: yearMap, isDark: isDark),
                            const SizedBox(height: Spacing.xl),

                            // ── Personal Records ──────────────────────────────
                            _RecordsCard(stats: stats, isDark: isDark),
                            const SizedBox(height: Spacing.xl),

                            // ── Monthly Breakdown ─────────────────────────────
                            _MonthlyBreakdown(yearMap: yearMap, isDark: isDark),
                            const SizedBox(height: Spacing.xxl),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StreakStats _computeStreakStats(
      Map<String, int> yearMap, int currentStreak) {
    // Longest streak calculation
    final now = DateTime.now();
    int longestStreak = 0;
    int tempStreak = 0;
    int totalStudyDays = 0;
    int totalMinutes = 0;

    for (int i = 364; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final mins = yearMap[key] ?? 0;
      if (mins > 0) {
        tempStreak++;
        totalStudyDays++;
        totalMinutes += mins;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }

    // Best single day
    int bestDayMinutes = 0;
    String? bestDayKey;
    for (final e in yearMap.entries) {
      if (e.value > bestDayMinutes) {
        bestDayMinutes = e.value;
        bestDayKey = e.key;
      }
    }

    return _StreakStats(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalStudyDays: totalStudyDays,
      totalMinutes: totalMinutes,
      bestDayMinutes: bestDayMinutes,
      bestDayKey: bestDayKey,
    );
  }
}

class _StreakStats {
  final int currentStreak;
  final int longestStreak;
  final int totalStudyDays;
  final int totalMinutes;
  final int bestDayMinutes;
  final String? bestDayKey;

  const _StreakStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalStudyDays,
    required this.totalMinutes,
    required this.bestDayMinutes,
    required this.bestDayKey,
  });
}

// ─── Hero Streak Row ─────────────────────────────────────────────────────────

class _HeroStreakRow extends StatelessWidget {
  const _HeroStreakRow({required this.stats, required this.isDark});
  final _StreakStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StreakHero(
          emoji: '🔥',
          value: '${stats.currentStreak}',
          label: 'Dias seguidos',
          color: const Color(0xFFFF6B35),
          isDark: isDark,
          flex: 2,
        ),
        const SizedBox(width: Spacing.sm),
        _StreakHero(
          emoji: '⚡',
          value: '${stats.longestStreak}',
          label: 'Maior streak',
          color: DesignTokens.primary,
          isDark: isDark,
          flex: 1,
        ),
        const SizedBox(width: Spacing.sm),
        _StreakHero(
          emoji: '📅',
          value: '${stats.totalStudyDays}',
          label: 'Dias ativos',
          color: DesignTokens.secondary,
          isDark: isDark,
          flex: 1,
        ),
      ],
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
    required this.flex,
  });
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final bool isDark;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: DesignTokens.brLg,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: Spacing.xs),
            Text(
              value,
              style: TextStyle(
                fontSize: flex == 2 ? 40 : 28,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Year Calendar ───────────────────────────────────────────────────────────

class _YearCalendar extends StatelessWidget {
  const _YearCalendar({required this.yearMap, required this.isDark});
  final Map<String, int> yearMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Max minutes in a single day for intensity scaling
    final maxMins = yearMap.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos 12 Meses',
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Weekday labels
          const Row(
            children: [
              SizedBox(width: 30),
              Expanded(child: _WeekdayLabel('D')),
              Expanded(child: _WeekdayLabel('S')),
              Expanded(child: _WeekdayLabel('T')),
              Expanded(child: _WeekdayLabel('Q')),
              Expanded(child: _WeekdayLabel('Q')),
              Expanded(child: _WeekdayLabel('S')),
              Expanded(child: _WeekdayLabel('S')),
            ],
          ),
          const SizedBox(height: 4),
          // Build 53 weeks grid (12 months)
          LayoutBuilder(
            builder: (context, constraints) {
              const weeks = 53;
              final cellSize = (constraints.maxWidth - 30) / 7;

              // We start from 52 weeks ago (Sunday)
              final start = now.subtract(const Duration(days: 364));
              // Normalize to start of week (Sunday = 0)
              final startOffset = start.weekday % 7;
              final startSunday = start.subtract(Duration(days: startOffset));

              // Build month labels
              final monthLabels = <int, String>{};
              for (int w = 0; w < weeks; w++) {
                final weekStart = startSunday.add(Duration(days: w * 7));
                if (weekStart.day <= 7) {
                  monthLabels[w] = _monthAbbr(weekStart.month);
                }
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month labels column
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: List.generate(weeks, (w) {
                        return SizedBox(
                          height: cellSize,
                          child: monthLabels.containsKey(w)
                              ? Text(
                                  monthLabels[w]!,
                                  style: AppTypography.overline.copyWith(
                                    fontSize: 8,
                                    color: isDark
                                        ? DesignTokens.darkTextMuted
                                        : DesignTokens.lightTextMuted,
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
                  ),
                  // Grid
                  Expanded(
                    child: Column(
                      children: List.generate(weeks, (w) {
                        return SizedBox(
                          height: cellSize,
                          child: Row(
                            children: List.generate(7, (d) {
                              final date =
                                  startSunday.add(Duration(days: w * 7 + d));
                              final key =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              final mins = yearMap[key] ?? 0;
                              final isFuture = date.isAfter(now);
                              final intensity = (maxMins > 0 && !isFuture)
                                  ? (mins / maxMins).clamp(0.0, 1.0)
                                  : 0.0;

                              return Expanded(
                                child: Tooltip(
                                  message: isFuture
                                      ? ''
                                      : mins > 0
                                          ? '${date.day}/${date.month}: ${mins}min'
                                          : '${date.day}/${date.month}: sem estudo',
                                  child: Container(
                                    margin: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: isFuture
                                          ? Colors.transparent
                                          : mins == 0
                                              ? (isDark
                                                  ? DesignTokens.darkBg3
                                                  : const Color(0xFFE8EDF2))
                                              : Color.lerp(
                                                  DesignTokens.primary
                                                      .withValues(alpha: 0.2),
                                                  DesignTokens.primary,
                                                  intensity,
                                                ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Menos',
                style: AppTypography.overline.copyWith(
                  fontSize: 9,
                  color: isDark
                      ? DesignTokens.darkTextMuted
                      : DesignTokens.lightTextMuted,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? (isDark
                            ? DesignTokens.darkBg3
                            : const Color(0xFFE8EDF2))
                        : DesignTokens.primary
                            .withValues(alpha: 0.2 + (i * 0.2)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'Mais',
                style: AppTypography.overline.copyWith(
                  fontSize: 9,
                  color: isDark
                      ? DesignTokens.darkTextMuted
                      : DesignTokens.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbr = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return abbr[month - 1];
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 9, color: Colors.grey),
    );
  }
}

// ─── Personal Records ─────────────────────────────────────────────────────────

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.stats, required this.isDark});
  final _StreakStats stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalHours = stats.totalMinutes / 60.0;
    final bestHours = stats.bestDayMinutes / 60.0;

    String bestDayStr = '—';
    if (stats.bestDayKey != null) {
      final parts = stats.bestDayKey!.split('-');
      if (parts.length == 3) {
        bestDayStr = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Recordes Pessoais',
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              _RecordTile(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF6B35),
                title: '${stats.longestStreak} dias',
                subtitle: 'Maior sequência',
                isDark: isDark,
              ),
              const SizedBox(width: Spacing.sm),
              _RecordTile(
                icon: Icons.timer_rounded,
                color: DesignTokens.primary,
                title: '${totalHours.toStringAsFixed(1)}h',
                subtitle: 'Total no ano',
                isDark: isDark,
              ),
              const SizedBox(width: Spacing.sm),
              _RecordTile(
                icon: Icons.star_rounded,
                color: DesignTokens.warning,
                title: '${bestHours.toStringAsFixed(1)}h',
                subtitle: 'Melhor dia ($bestDayStr)',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: DesignTokens.brMd,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: Spacing.xs),
            Text(
              title,
              style: AppTypography.headingSm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Monthly Breakdown ────────────────────────────────────────────────────────

class _MonthlyBreakdown extends StatelessWidget {
  const _MonthlyBreakdown({required this.yearMap, required this.isDark});
  final Map<String, int> yearMap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = <_MonthData>[];

    for (int m = 11; m >= 0; m--) {
      final target = DateTime(now.year, now.month - m, 1);
      final monthKey =
          '${target.year}-${target.month.toString().padLeft(2, '0')}';
      final mins = yearMap.entries
          .where((e) => e.key.startsWith(monthKey))
          .fold(0, (sum, e) => sum + e.value);
      final days = yearMap.entries
          .where((e) => e.key.startsWith(monthKey) && e.value > 0)
          .length;

      months.add(_MonthData(
        label: _monthAbbr(target.month),
        year: target.year,
        totalMinutes: mins,
        activeDays: days,
      ));
    }

    final maxMins =
        months.fold(0, (a, b) => a > b.totalMinutes ? a : b.totalMinutes);

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        boxShadow: DesignTokens.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Evolução Mensal',
            style: AppTypography.labelMd.copyWith(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
            ),
          ),
          const SizedBox(height: Spacing.md),
          // Bar chart
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final ratio = maxMins > 0 ? m.totalMinutes / maxMins : 0.0;
                final isCurrentMonth =
                    m.label == _monthAbbr(now.month) && m.year == now.year;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Hours label on hover (tooltip)
                        if (m.totalMinutes > 0)
                          Text(
                            '${(m.totalMinutes / 60).toStringAsFixed(0)}h',
                            style: AppTypography.overline.copyWith(
                              fontSize: 8,
                              color: isDark
                                  ? DesignTokens.darkTextMuted
                                  : DesignTokens.lightTextMuted,
                            ),
                          ),
                        const SizedBox(height: 2),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          height: (ratio * 70).clamp(2.0, 70.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCurrentMonth
                                  ? [
                                      DesignTokens.secondary,
                                      DesignTokens.primary
                                    ]
                                  : [
                                      DesignTokens.primary
                                          .withValues(alpha: 0.4),
                                      DesignTokens.primary
                                          .withValues(alpha: 0.7),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.label,
                          style: AppTypography.overline.copyWith(
                            fontSize: 9,
                            fontWeight: isCurrentMonth
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isCurrentMonth
                                ? DesignTokens.primary
                                : (isDark
                                    ? DesignTokens.darkTextMuted
                                    : DesignTokens.lightTextMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbr = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return abbr[month - 1];
  }
}

class _MonthData {
  final String label;
  final int year;
  final int totalMinutes;
  final int activeDays;
  const _MonthData({
    required this.label,
    required this.year,
    required this.totalMinutes,
    required this.activeDays,
  });
}
