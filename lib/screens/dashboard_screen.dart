import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/flashcard_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/performance_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import 'package:el_tooltip/el_tooltip.dart';
import '../widgets/relevance_tooltip.dart';
import '../widgets/metric_card.dart';
import '../models/subject_model.dart';
import '../widgets/app_charts.dart';
import '../widgets/goal_switcher.dart';
import '../controllers/quote_controller.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(dueTodayNotesProvider);
    ref.invalidate(dueFlashcardsProvider);

    try {
      await ref.read(dashboardProvider.future);
    } catch (_) {}

    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(dashboardProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final dueNotes = ref.watch(dueTodayNotesProvider).valueOrNull ?? [];
    final dueFlashcards = ref.watch(dueFlashcardsProvider).valueOrNull ?? [];
    final activeId = ref.watch(activeGoalIdProvider);
    final activePlan = ref.watch(activePlanProvider).valueOrNull;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700 && width < 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: const WaterDropMaterialHeader(
              backgroundColor: AppTheme.primary,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 32,
              ),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: widget,
                      ),
                    ),
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

                      // Motivational Quote
                      const _MotivationalQuoteCard(),
                      const SizedBox(height: 32),

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
                            subject: subjects.firstWhere(
                              (s) => s.id == data.suggestedSubjectId,
                              orElse: () => subjects.isNotEmpty
                                  ? subjects.first
                                  : const Subject(
                                      id: '',
                                      userId: '',
                                      name: 'Desconhecida',
                                      color: '#7C6FFF',
                                      priority: 3,
                                      weight: 5,
                                      difficulty: 3),
                            ),
                            suggestedMinutes: data.suggestedMinutes,
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

                      // Syllabus Progress Section
                      _SectionCard(
                        title: 'Cobertura do Edital',
                        child: _SyllabusProgressRow(data: data),
                      ),
                      const SizedBox(height: 32),

                      // General Performance Card
                      const _GeneralPerformanceCard(),
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
                                child:
                                    _AchievementsList(streak: data.streakDays),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyChart() => Center(
        child: Text(
          'Sem dados ainda.\nEstude e registre suas sessões!',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
              fontSize: 13),
        ),
      );
}

class _MotivationalQuoteCard extends ConsumerWidget {
  const _MotivationalQuoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: quoteAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primary),
          ),
        ),
        error: (_, __) => const SizedBox(),
        data: (quote) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.format_quote_rounded,
                  color: AppTheme.accent, size: 28),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${quote.text}"',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '- ${quote.author}',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref.read(quoteProvider.notifier).fetchQuote(),
              icon: const Icon(Icons.refresh_rounded),
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
              tooltip: 'Nova frase',
            ),
          ],
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano de Estudo não configurado',
                  style: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Gere seu cronograma para começar a estudar hoje!',
                  style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
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

class _SuggestedSubjectCTA extends StatefulWidget {
  final Subject subject;
  final int suggestedMinutes;
  final VoidCallback onTap;

  const _SuggestedSubjectCTA({
    required this.subject,
    required this.suggestedMinutes,
    required this.onTap,
  });

  @override
  State<_SuggestedSubjectCTA> createState() => _SuggestedSubjectCTAState();
}

class _SuggestedSubjectCTAState extends State<_SuggestedSubjectCTA>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double? _lastScore;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _lastScore = _calculateScore(widget.subject);
  }

  double _calculateScore(Subject s) =>
      s.priority * s.weight * s.difficulty.toDouble();

  @override
  void didUpdateWidget(_SuggestedSubjectCTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newScore = _calculateScore(widget.subject);
    if (_lastScore != null && newScore != _lastScore) {
      _pulseController.forward(from: 0);
    }
    _lastScore = newScore;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final suggestedMinutes = widget.suggestedMinutes;
    final onTap = widget.onTap;
    final color =
        Color(int.parse('FF${subject.color.replaceAll('#', '')}', radix: 16));

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color:
                        color.withValues(alpha: 0.2 * _pulseController.value),
                    blurRadius: 15 * _pulseController.value,
                    spreadRadius: 2 * _pulseController.value,
                  )
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_alt_rounded, color: color, size: 36),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
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
                    ElTooltip(
                      position: ElTooltipPosition.topCenter,
                      padding: EdgeInsets.zero,
                      color: Colors.transparent,
                      content: RelevanceTooltip(
                        subject: subject,
                      ),
                      child: Icon(Icons.info_outline_rounded,
                          color: color, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sua prioridade agora é  ',
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodySmall?.color ??
                                  Colors.grey),
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: subject.name,
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.white),
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
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.arrow_forward_rounded,
              color:
                  (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey)
                      .withValues(alpha: 0.5)),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $userName 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                AppDateUtils.weekdayLabel(DateTime.now()),
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Render the GoalSwitcher inline on the dashboard
              const SizedBox(
                width: 250,
                child: GoalSwitcher(),
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

class _GeneralPerformanceCard extends ConsumerWidget {
  const _GeneralPerformanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(performanceStatsProvider);

    return InkWell(
      onTap: () => context.go('/performance'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withValues(alpha: 0.1),
              AppTheme.accent.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aproveitamento Geral',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${stats.averageAccuracy.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.totalQuestions} questões',
                  style: TextStyle(
                    fontSize: 12,
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalCorrect} acertos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _SyllabusProgressRow extends StatelessWidget {
  final DashboardData data;
  const _SyllabusProgressRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;
      return Column(
        children: [
          Row(
            children: [
              _ProgressCol(
                label: 'Teoria',
                completed: data.completedTheory,
                total: data.totalTheory,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 16),
              _ProgressCol(
                label: 'Revisão',
                completed: data.completedReview,
                total: data.totalReview,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 16),
              _ProgressCol(
                label: 'Exercícios',
                completed: data.completedExercises,
                total: data.totalExercises,
                color: AppTheme.accent,
              ),
            ],
          ),
          if (data.totalTheory > 0) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (data.completedTheory +
                        data.completedReview +
                        data.completedExercises) /
                    (data.totalTheory * 3),
                minHeight: 12,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(((data.completedTheory + data.completedReview + data.completedExercises) / (data.totalTheory * 3)) * 100).toInt()}% do edital concluído',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _ProgressCol extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;

  const _ProgressCol({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? completed / total : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$completed/$total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final List<Widget> cards = [
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Icon(Icons.more_horiz_rounded,
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
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
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
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
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey),
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
