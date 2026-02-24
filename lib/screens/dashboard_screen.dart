import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/flashcard_controller.dart';
import '../controllers/goal_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../models/subject_model.dart';
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
    final goalsAsync = ref.watch(goalsProvider);
    final activeId = ref.watch(activeGoalIdProvider);
    final activePlan = ref.watch(activePlanProvider).valueOrNull;

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

                // Empty Goals CTA
                goalsAsync.when(
                  data: (goals) => goals.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: _EmptyGoalsCTA(
                            onAdd: () {
                              // We can't directly access _showAddGoalDialog from GoalSwitcher
                              // but we can use the same logic here or refactor.
                              // Actually, the goal_switcher.dart doesn't export the dialog logic easily.
                              // I'll implement a simple dialog trigger here as well for now or refactor GoalSwitcher later.
                              _showAddGoalDialog(context, ref);
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // No Active Plan CTA
                if (activeId != null && activePlan == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _NoPlanCTA(
                      onTap: () => context.go('/settings'),
                    ),
                  ),

                // Suggested Study Subject
                if (activeId != null &&
                    activePlan != null &&
                    data.suggestedSubjectId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _SuggestedSubjectCTA(
                      subjectId: data.suggestedSubjectId!,
                      suggestedMinutes: data.suggestedMinutes,
                      subjects: subjects,
                      onTap: () => context.go('/subjects'),
                    ),
                  ),

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

                const SizedBox(height: 24),

                // Planned vs Read Row
                if (isDesktop || isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _ChartCard(
                          title: 'Planejado vs Lido Hoje',
                          height: 280,
                          child: PlannedVsReadChart(
                            data: data.plannedVsRead,
                            subjectNames: subjectNameMap,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  _ChartCard(
                    title: 'Planejado vs Lido Hoje',
                    height: 240,
                    child: PlannedVsReadChart(
                      data: data.plannedVsRead,
                      subjectNames: subjectNameMap,
                    ),
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

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Novo Objetivo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Medicina 2026, Concurso...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(goalControllerProvider.notifier)
                    .createGoal(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalsCTA extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoalsCTA({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bem-vindo ao StudyOps!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para começar, adicione seu primeiro objetivo de estudo\n(como um concurso ou vestibular específico).',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar Primeiro Objetivo'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPlanCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _NoPlanCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: AppTheme.accent, size: 24),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano de Estudo não configurado',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Gere seu cronograma para começar a estudar hoje!',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }
}

class _SuggestedSubjectCTA extends StatelessWidget {
  final String subjectId;
  final int suggestedMinutes;
  final List<Subject> subjects;
  final VoidCallback onTap;

  const _SuggestedSubjectCTA({
    required this.subjectId,
    required this.suggestedMinutes,
    required this.subjects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subject = subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => const Subject(
          id: '',
          userId: '',
          name: 'Desconhecida',
          color: '#7C6FFF',
          priority: 3,
          weight: 5),
    );

    final color =
        Color(int.parse('FF${subject.color.replaceAll('#', '')}', radix: 16));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_alt_rounded, color: color, size: 36),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ALOCAÇÃO INTELIGENTE',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Sua prioridade agora é  ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: subject.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Meta sugerida: ${AppDateUtils.formatMinutes(suggestedMinutes)} de foco contínuo.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.arrow_forward_rounded,
                color: AppTheme.textMuted.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
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
