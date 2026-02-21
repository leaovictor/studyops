import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../widgets/metric_card.dart';
import '../widgets/app_charts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final dueNotes = ref.watch(dueTodayNotesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: dashAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          final subjectColorMap = {
            for (final s in subjects) s.id: s.color,
          };
          final subjectNameMap = {
            for (final s in subjects) s.id: s.name,
          };

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dashboard',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  AppDateUtils.weekdayLabel(DateTime.now()),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.go('/checklist'),
                            icon: const Icon(Icons.checklist_rounded, size: 16),
                            label: const Text('Ver checklist'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),

                      // Due reviews banner
                      if (dueNotes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ReviewBanner(count: dueNotes.length),
                      ],

                      const SizedBox(height: 24),

                      // Metric cards
                      LayoutBuilder(builder: (_, constraints) {
                        final cols = constraints.maxWidth > 600 ? 3 : 2;
                        return _MetricGrid(data: data, cols: cols);
                      }),

                      const SizedBox(height: 32),

                      // Charts row
                      LayoutBuilder(builder: (_, constraints) {
                        final wide = constraints.maxWidth > 700;
                        final trend = data.weeklyTrend;

                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _ChartCard(
                                  title: 'Horas por dia (7 dias)',
                                  height: 220,
                                  child: trend.isEmpty
                                      ? _emptyChart()
                                      : WeeklyBarChart(data: trend),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _ChartCard(
                                  title: 'Distribuição por Matéria',
                                  height: 220,
                                  child: subjects.isEmpty
                                      ? _emptyChart()
                                      : SubjectPieChart(
                                          data: data.minutesBySubject,
                                          subjectColors: subjectColorMap,
                                          subjectNames: subjectNameMap,
                                        ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _ChartCard(
                              title: 'Horas por dia (7 dias)',
                              height: 200,
                              child: trend.isEmpty
                                  ? _emptyChart()
                                  : WeeklyBarChart(data: trend),
                            ),
                            const SizedBox(height: 16),
                            _ChartCard(
                              title: 'Distribuição por Matéria',
                              height: 200,
                              child: subjects.isEmpty
                                  ? _emptyChart()
                                  : SubjectPieChart(
                                      data: data.minutesBySubject,
                                      subjectColors: subjectColorMap,
                                      subjectNames: subjectNameMap,
                                    ),
                            ),
                          ],
                        );
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

  Widget _emptyChart() => const Center(
        child: Text(
          'Sem dados ainda.\nEstude e registre suas sessões!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
}

class _MetricGrid extends StatelessWidget {
  final DashboardData data;
  final int cols;
  const _MetricGrid({required this.data, required this.cols});

  @override
  Widget build(BuildContext context) {
    final cards = [
      MetricCard(
        icon: Icons.today_rounded,
        label: 'Hoje',
        value: AppDateUtils.formatMinutes(data.todayMinutes),
        accentColor: AppTheme.primary,
      ),
      MetricCard(
        icon: Icons.calendar_view_week_rounded,
        label: 'Esta semana',
        value: AppDateUtils.formatMinutes(data.weekMinutes),
        accentColor: AppTheme.secondary,
      ),
      MetricCard(
        icon: Icons.calendar_month_rounded,
        label: 'Este mês',
        value: AppDateUtils.formatMinutes(data.monthMinutes),
        accentColor: AppTheme.accent,
      ),
    ];

    return GridView.count(
      crossAxisCount: cols,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;
  const _ChartCard({
    required this.title,
    required this.child,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  final int count;
  const _ReviewBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppTheme.warning, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count revisão(ões) agendada(s) para hoje no Caderno de Erros',
              style: const TextStyle(color: AppTheme.warning, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/errors'),
            child: const Text('Ver',
                style: TextStyle(color: AppTheme.warning, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
