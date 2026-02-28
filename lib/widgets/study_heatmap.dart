import 'package:flutter/material.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';

/// A 30-day study activity heatmap.
///
/// Each cell represents one day — darker = more study time.
/// Up to [days] days shown, latest day at bottom-right.
class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({
    super.key,
    required this.dailyMinutes,
    this.days = 35,
    this.isDark = true,
  });

  /// Map of dateKey (yyyy-MM-dd) → minutes studied that day.
  final Map<String, int> dailyMinutes;
  final int days;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build grid of the last [days] calendar days
    final cells = <_HeatCell>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      final mins = dailyMinutes[key] ?? 0;
      cells.add(_HeatCell(date: date, minutes: mins));
    }

    // Pad to start on Monday (fill leading empty cells)
    final firstWeekday = cells.first.date.weekday; // 1=Mon 7=Sun
    final leading = firstWeekday - 1; // days to pad at start

    final maxMinutes =
        cells.map((c) => c.minutes).fold(0, (a, b) => a > b ? a : b);

    const cols = 5; // 5 weeks visible
    const rows = 7; // Mon–Sun

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom']
              .map((d) => SizedBox(
                    width: 28,
                    child: Text(
                      d,
                      style: AppTypography.overline.copyWith(
                        color: isDark
                            ? DesignTokens.darkTextMuted
                            : DesignTokens.lightTextMuted,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid: cols × rows (week columns, day rows)
        SizedBox(
          height: rows * 30.0,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // days per column
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: cols * rows,
            itemBuilder: (context, index) {
              // index goes column by column (horizontal scroll)
              final col = index ~/ rows;
              final row = index % rows;
              final cellIndex = col * rows + row - leading;

              if (cellIndex < 0 || cellIndex >= cells.length) {
                return const SizedBox.shrink();
              }

              final cell = cells[cellIndex];
              final intensity = maxMinutes > 0
                  ? (cell.minutes / maxMinutes).clamp(0.0, 1.0)
                  : 0.0;

              return Tooltip(
                message: '${_fmtDate(cell.date)}: ${cell.minutes}min',
                child: AnimatedContainer(
                  duration: DesignTokens.durationFast,
                  decoration: BoxDecoration(
                    color: _cellColor(intensity, isDark),
                    borderRadius: DesignTokens.brXs,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Menos',
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 4),
            ...List.generate(5, (i) {
              final intensity = i / 4.0;
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: _cellColor(intensity, isDark),
                  borderRadius: DesignTokens.brXs,
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              'Mais',
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _cellColor(double intensity, bool isDark) {
    if (intensity == 0) {
      return isDark ? DesignTokens.darkBg4 : DesignTokens.lightBg3;
    }
    // Gradient from light accent to full accent
    return Color.lerp(
      DesignTokens.accent.withValues(alpha: 0.25),
      DesignTokens.accent,
      intensity,
    )!;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _HeatCell {
  const _HeatCell({required this.date, required this.minutes});
  final DateTime date;
  final int minutes;
}
