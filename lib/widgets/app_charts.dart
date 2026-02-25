import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';

// ── Weekly Bar Chart ─────────────────────────────

class WeeklyBarChart extends StatelessWidget {
  /// List of 7 entries in order: MapEntry(dateKey, minutes)
  final List<MapEntry<String, int>> data;

  const WeeklyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 120.0
        : (data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 30)
            .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                '${(v / 60).round()}h',
                style: TextStyle(
                  color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final date = AppDateUtils.fromKey(data[i].key);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppDateUtils.shortWeekdayLabel(date),
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final minutes = data[i].value.toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: minutes,
                width: 20,
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryVariant],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Subject Pie Chart ─────────────────────────────

class SubjectPieChart extends StatefulWidget {
  /// subjectId → minutes
  final Map<String, int> data;

  /// subjectId → color hex
  final Map<String, String> subjectColors;

  /// subjectId → name
  final Map<String, String> subjectNames;

  const SubjectPieChart({
    super.key,
    required this.data,
    required this.subjectColors,
    required this.subjectNames,
  });

  @override
  State<SubjectPieChart> createState() => _SubjectPieChartState();
}

class _SubjectPieChartState extends State<SubjectPieChart> {
  int? _touchedIndex;

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Text('Sem dados', style: TextStyle(color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey))),
      );
    }

    final total = widget.data.values.fold(0, (a, b) => a + b);
    final entries = widget.data.entries.toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final isTouched = i == _touchedIndex;
                final pct = (entry.value / total * 100).round();
                final color =
                    _hexColor(widget.subjectColors[entry.key] ?? '#7C6FFF');
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '$pct%',
                  color: color,
                  radius: isTouched ? 70 : 60,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: entries.map((e) {
            final color = _hexColor(widget.subjectColors[e.key] ?? '#7C6FFF');
            final name = widget.subjectNames[e.key] ?? e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name.length > 12 ? '${name.substring(0, 12)}…' : name,
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 30-Day Evolution Line Chart ───────────────────

class EvolutionLineChart extends StatelessWidget {
  /// dateKey → minutes (last N days)
  final List<MapEntry<String, int>> data;

  const EvolutionLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('Sem dados', style: TextStyle(color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey))),
      );
    }

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].value / 60.0),
    );

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        backgroundColor: Colors.transparent,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                '${v.round()}h',
                style: TextStyle(color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey), fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppTheme.primary,
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.3),
                  AppTheme.primary.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

// ── Planned Vs Read Bar Chart ─────────────────────────────

class PlannedVsReadChart extends StatelessWidget {
  /// subjectId → {'planned': x, 'read': y}
  final Map<String, Map<String, int>> data;
  final Map<String, String> subjectNames;

  const PlannedVsReadChart({
    super.key,
    required this.data,
    required this.subjectNames,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('Sem dados diários',
            style: TextStyle(color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey))),
      );
    }

    final entries = data.entries
        .where(
            (e) => (e.value['planned'] ?? 0) > 0 || (e.value['read'] ?? 0) > 0)
        .toList();

    if (entries.isEmpty) {
      return Center(
        child: Text('Sem planejamento hoje',
            style: TextStyle(color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey))),
      );
    }

    // Find the max Y
    double maxY = 60.0;
    for (final e in entries) {
      final plannedY = (e.value['planned'] ?? 0).toDouble();
      final readY = (e.value['read'] ?? 0).toDouble();
      if (plannedY > maxY) maxY = plannedY;
      if (readY > maxY) maxY = readY;
    }
    maxY += 30.0; // Margin top

    final barGroups = List.generate(entries.length, (i) {
      final entry = entries[i];
      final p = (entry.value['planned'] ?? 0).toDouble();
      final r = (entry.value['read'] ?? 0).toDouble();

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: p,
            color: Theme.of(context).dividerColor, // Planned - mute
            width: 12,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: r,
            color: p > r
                ? AppTheme.accent
                : const Color(0xFF10B981), // Read - active
            width: 12,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _LegendItem(color: Theme.of(context).dividerColor, label: 'Planejado'),
          const SizedBox(width: 16),
          const _LegendItem(color: AppTheme.accent, label: 'Lido Hoje'),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, _) => Text(
                      '${(v / 60).toStringAsFixed(1)}h',
                      style: TextStyle(
                          color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey), fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= entries.length) {
                        return const SizedBox.shrink();
                      }

                      final subjectName = subjectNames[entries[i].key] ?? '?';
                      final displayStr = subjectName.length > 8
                          ? '${subjectName.substring(0, 8)}…'
                          : subjectName;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          displayStr,
                          style: TextStyle(
                              color: (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey), fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), fontSize: 11)),
      ],
    );
  }
}