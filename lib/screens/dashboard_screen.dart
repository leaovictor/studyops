import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/flashcard_controller.dart';
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
    final dueFlashcards = ref.watch(dueFlashcardsProvider).valueOrNull ?? [];

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700 && width < 1100;

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

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(userName: 'Victor'), // Mocked name
                const SizedBox(height: 32),

                // Top Metrics
                _TopMetricsRow(
                  data: data,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 32),

                // Main Content (Charts)
                if (isDesktop || isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ChartCard(
                          title: 'Progresso Semanal (horas)',
                          height: 300,
                          child: data.weeklyTrend.isEmpty
                              ? _emptyChart()
                              : WeeklyBarChart(data: data.weeklyTrend),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: _ChartCard(
                          title: 'Foco por Matéria',
                          height: 300,
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
                  )
                else
                  Column(
                    children: [
                      _ChartCard(
                        title: 'Progresso Semanal (horas)',
                        height: 240,
                        child: data.weeklyTrend.isEmpty
                            ? _emptyChart()
                            : WeeklyBarChart(data: data.weeklyTrend),
                      ),
                      const SizedBox(height: 24),
                      _ChartCard(
                        title: 'Foco por Matéria',
                        height: 240,
                        child: subjects.isEmpty
                            ? _emptyChart()
                            : SubjectPieChart(
                                data: data.minutesBySubject,
                                subjectColors: subjectColorMap,
                                subjectNames: subjectNameMap,
                              ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Bottom Section: Activities & Summary
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          title: 'Pendências de Hoje',
                          child: _TodaySummary(
                            dueNotesCount: dueNotes.length,
                            dueFlashcardsCount: dueFlashcards.length,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _SectionCard(
                          title: 'Últimas Conquistas',
                          child: _AchievementsList(streak: data.streakDays),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _SectionCard(
                        title: 'Pendências de Hoje',
                        child: _TodaySummary(
                          dueNotesCount: dueNotes.length,
                          dueFlashcardsCount: dueFlashcards.length,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionCard(
                        title: 'Últimas Conquistas',
                        child: _AchievementsList(streak: data.streakDays),
                      ),
                    ],
                  ),
              ],
            ),
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

class _Header extends StatelessWidget {
  final String userName;
  const _Header({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $userName 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppDateUtils.weekdayLabel(DateTime.now()),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go('/checklist'),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Iniciar Sessão'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _TopMetricsRow extends StatelessWidget {
  final DashboardData data;
  final bool isDesktop;
  final bool isTablet;

  const _TopMetricsRow({
    required this.data,
    required this.isDesktop,
    required this.isTablet,
  });

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
        label: 'Semana',
        value: AppDateUtils.formatMinutes(data.weekMinutes),
        accentColor: AppTheme.secondary,
      ),
      MetricCard(
        icon: Icons.local_fire_department_rounded,
        label: 'Streak',
        value: '${data.streakDays} dias',
        accentColor: Colors.orangeAccent,
      ),
      MetricCard(
        icon: Icons.auto_graph_rounded,
        label: 'Foco',
        value: '${(data.consistencyPct * 100).toInt()}%',
        accentColor: AppTheme.accent,
      ),
      if (isDesktop)
        MetricCard(
          icon: Icons.calendar_month_rounded,
          label: 'Mês',
          value: AppDateUtils.formatMinutes(data.monthMinutes),
          accentColor: AppTheme.primaryVariant,
        ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: c,
                )))
            .toList()
          ..last = Expanded(child: cards.last),
      );
    }

    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3, // Adjusted from 1.6 to prevent overflow on mobile
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
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: height, child: child),
        ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final int dueNotesCount;
  final int dueFlashcardsCount;

  const _TodaySummary({
    required this.dueNotesCount,
    required this.dueFlashcardsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryTile(
          icon: Icons.style_rounded,
          color: AppTheme.primary,
          label: 'Flashcards para hoje',
          count: dueFlashcardsCount,
          onTap: () => context.go('/flashcards'),
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          icon: Icons.book_rounded,
          color: AppTheme.warning,
          label: 'Revisões de Erros',
          count: dueNotesCount,
          onTap: () => context.go('/errors'),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final int streak;
  const _AchievementsList({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AchievementRow(
          icon: Icons.emoji_events_rounded,
          label: 'Foco Total',
          subtitle: 'Completou 100% da meta semanal',
          color: Colors.amber,
        ),
        const SizedBox(height: 16),
        _AchievementRow(
          icon: Icons.whatshot_rounded,
          label: 'Persistent',
          subtitle: 'Streak de $streak dias alcançada!',
          color: Colors.orangeAccent,
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _AchievementRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          radius: 24,
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
