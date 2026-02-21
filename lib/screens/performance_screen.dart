import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/subject_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../widgets/app_charts.dart';

class PerformanceScreen extends ConsumerWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: dashAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final subjectColorMap = {for (final s in subjects) s.id: s.color};
          final subjectNameMap = {for (final s in subjects) s.id: s.name};
          final trend = data.weeklyTrend;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Análise detalhada do seu desempenho de estudos',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Weekly trend chart
                      _SectionCard(
                        title: 'Evolução semanal (horas/dia)',
                        child: SizedBox(
                          height: 200,
                          child: trend.isEmpty
                              ? const Center(
                                  child: Text('Sem dados ainda',
                                      style:
                                          TextStyle(color: AppTheme.textMuted)))
                              : WeeklyBarChart(data: trend),
                        ),
                      ),
                      const SizedBox(height: 16),

                      LayoutBuilder(builder: (_, c) {
                        final isWide = c.maxWidth > 600;
                        final pieChart = _SectionCard(
                          title: 'Tempo por Matéria',
                          child: SizedBox(
                            height: 180,
                            child: subjects.isEmpty
                                ? const Center(
                                    child: Text('Sem matérias cadastradas',
                                        style: TextStyle(
                                            color: AppTheme.textMuted)))
                                : SubjectPieChart(
                                    data: data.minutesBySubject,
                                    subjectColors: subjectColorMap,
                                    subjectNames: subjectNameMap,
                                  ),
                          ),
                        );

                        final efficiencyTable = _SectionCard(
                          title: 'Eficiência por Matéria',
                          child: Column(
                            children: [
                              if (data.minutesBySubject.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Sem registros',
                                      style:
                                          TextStyle(color: AppTheme.textMuted)),
                                )
                              else
                                ...data.minutesBySubject.entries.map((e) {
                                  final subject = subjects.firstWhere(
                                      (s) => s.id == e.key,
                                      orElse: () => subjects.first);
                                  final color = Color(int.parse(
                                      'FF${subject.color.replaceAll('#', '')}',
                                      radix: 16));
                                  final totalMinutes = data.monthMinutes > 0
                                      ? data.monthMinutes
                                      : 1;
                                  final pct = e.value / totalMinutes;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(children: [
                                              Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  )),
                                              const SizedBox(width: 8),
                                              Text(subject.name,
                                                  style: const TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  )),
                                            ]),
                                            Text(
                                              AppDateUtils.formatMinutes(
                                                  e.value),
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            minHeight: 5,
                                            backgroundColor: AppTheme.border,
                                            valueColor:
                                                AlwaysStoppedAnimation(color),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: pieChart),
                              const SizedBox(width: 16),
                              Expanded(child: efficiencyTable),
                            ],
                          );
                        }
                        return Column(children: [
                          pieChart,
                          const SizedBox(height: 16),
                          efficiencyTable,
                        ]);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
