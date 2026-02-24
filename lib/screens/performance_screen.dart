import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/study_plan_controller.dart';
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
    final activePlan = ref.watch(activePlanProvider).valueOrNull;

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

          // KPI computations
          final consistencyPct = data.consistencyPct;
          final weekHours = data.weekMinutes / 60.0;
          final targetWeekHours = (activePlan?.dailyHours ?? 3.0) * 7;
          final productivity = targetWeekHours > 0
              ? (weekHours / targetWeekHours).clamp(0.0, 1.0)
              : 0.0;

          final String riskLabel;
          final Color riskColor;
          if (productivity >= 0.8) {
            riskLabel = 'Baixo';
            riskColor = AppTheme.accent;
          } else if (productivity >= 0.5) {
            riskLabel = 'Médio';
            riskColor = AppTheme.primary;
          } else {
            riskLabel = 'Alto';
            riskColor = Colors.redAccent;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
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
                          const SizedBox(height: 20),

                          // ── KPI Row ──────────────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.local_fire_department_rounded,
                                  iconColor: Colors.orangeAccent,
                                  label: 'Constância',
                                  value: '${(consistencyPct * 100).round()}%',
                                  subtitle:
                                      '${data.weeklyTrend.where((e) => e.value > 0).length}/7 dias',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.bolt_rounded,
                                  iconColor: AppTheme.primary,
                                  label: 'Produtividade',
                                  value: '${(productivity * 100).round()}%',
                                  subtitle:
                                      '${weekHours.toStringAsFixed(1)}h / ${targetWeekHours.toStringAsFixed(0)}h',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiCard(
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: riskColor,
                                  label: 'Risco de Atraso',
                                  value: riskLabel,
                                  valueColor: riskColor,
                                  subtitle: 'vs. meta semanal',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Streak chip
                          if (data.streakDays > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.orangeAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${data.streakDays} dia${data.streakDays > 1 ? 's' : ''} seguido${data.streakDays > 1 ? 's' : ''}!',
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Weekly trend chart
                          _SectionCard(
                            title: 'Evolução semanal (horas/dia)',
                            child: SizedBox(
                              height: 200,
                              child: trend.isEmpty
                                  ? const Center(
                                      child: Text('Sem dados ainda',
                                          style: TextStyle(
                                              color: AppTheme.textMuted)))
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
                                          style: TextStyle(
                                              color: AppTheme.textMuted)),
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
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                                        color: AppTheme
                                                            .textPrimary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      )),
                                                ]),
                                                Text(
                                                  AppDateUtils.formatMinutes(
                                                      e.value),
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
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
                                                backgroundColor:
                                                    AppTheme.border,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        color),
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final String subtitle;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
