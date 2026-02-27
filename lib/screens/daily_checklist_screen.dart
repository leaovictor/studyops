import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/daily_task_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../widgets/study_plan_wizard_dialog.dart';
import '../models/daily_task_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../widgets/pomodoro_timer.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DailyChecklistScreen extends ConsumerStatefulWidget {
  const DailyChecklistScreen({super.key});

  @override
  ConsumerState<DailyChecklistScreen> createState() =>
      _DailyChecklistScreenState();
}

class _DailyChecklistScreenState extends ConsumerState<DailyChecklistScreen> {
  String? _pomodoroTaskId;
  late ConfettiController _confettiController;
  bool _wasDone = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String? _aiInsight;
  bool _isFetchingInsight = false;
  String? _lastInsightKey;

  void _onRefresh() async {
    ref.invalidate(dailyTasksProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(allTopicsProvider);
    try {
      await ref.read(dailyTasksProvider.future);
    } catch (_) {}
    _refreshController.refreshCompleted();
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(dailyTasksProvider).valueOrNull ?? [];
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];
    final selectedDate = ref.watch(selectedDateProvider);
    final controller = ref.read(dailyTaskControllerProvider.notifier);

    final done = tasks.where((t) => t.done).length;
    final total = tasks.length;
    final progress = total > 0 ? done / total : 0.0;

    // Trigger confetti when hitting 100%
    if (progress == 1.0 && total > 0 && !_wasDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
      _wasDone = true;
    } else if (progress < 1.0) {
      _wasDone = false;
    }

    final subjectMap = {for (final s in subjects) s.id: s};
    final topicMap = {for (final t in allTopics) t.id: t};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, subjects, allTopics),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tarefa'),
      ),
      body: Stack(
        children: [
          SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: const WaterDropMaterialHeader(
              backgroundColor: AppTheme.primary,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date picker
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Checklist Diário',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: (Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color ??
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded,
                                        size: 20,
                                        color: (Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color ??
                                            Colors.grey)),
                                    onSelected: (value) {
                                      if (value == 'config') {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              StudyPlanWizardDialog(
                                                  activePlan: ref
                                                      .read(activePlanProvider)
                                                      .valueOrNull),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'config',
                                        child: Row(
                                          children: [
                                            Icon(Icons.auto_awesome_rounded,
                                                size: 18,
                                                color: AppTheme.primary),
                                            SizedBox(width: 12),
                                            Text('Gerenciar Plano (IA)'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Date picker
                            OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (ctx, child) => Theme(
                                    data: Theme.of(ctx),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  ref
                                      .read(selectedDateProvider.notifier)
                                      .state = picked;
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded,
                                  size: 16),
                              label:
                                  Text(AppDateUtils.displayDate(selectedDate)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$done/$total tarefas concluídas',
                                  style: TextStyle(
                                    color: (Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        Colors.grey),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 600),
                                builder: (_, value, __) =>
                                    LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor:
                                      Theme.of(context).dividerColor,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.primary),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _AIMentorCard(
                          insight: _aiInsight,
                          isLoading: _isFetchingInsight,
                          onRefresh: _fetchAIInsight,
                        ),

                        const SizedBox(height: 24),

                        if (tasks.isEmpty)
                          _EmptyChecklistState()
                        else
                          AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 375),
                                childAnimationBuilder: (widget) =>
                                    SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: widget,
                                  ),
                                ),
                                children: tasks.map((task) {
                                  final subject = subjectMap[task.subjectId];
                                  final topic = topicMap[task.topicId];
                                  final showPomodoro =
                                      _pomodoroTaskId == task.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _TaskCard(
                                      task: task,
                                      subject: subject,
                                      topicName: topic?.name ?? 'Tópico',
                                      showPomodoro: showPomodoro,
                                      onTogglePomodoro: () {
                                        setState(() {
                                          _pomodoroTaskId =
                                              showPomodoro ? null : task.id;
                                        });
                                      },
                                      onToggleDone: (minutes) {
                                        if (task.done) {
                                          controller.markUndone(task.id);
                                        } else {
                                          controller.markDone(task, minutes);
                                        }
                                      },
                                      onDelete: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir Tarefa'),
                                            content: const Text(
                                                'Tem certeza que deseja excluir esta tarefa?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppTheme.error,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          controller.deleteTask(task.id);
                                        }
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primary,
                AppTheme.accent,
                Colors.orange,
                Colors.pink,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(
    BuildContext context,
    List<Subject> subjects,
    List<Topic> allTopics,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cadastre matérias antes de adicionar tarefas')),
      );
      return;
    }

    Subject? selectedSubject = subjects.first;
    Topic? selectedTopic;
    int plannedMinutes = 30;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final filteredTopics =
            allTopics.where((t) => t.subjectId == selectedSubject?.id).toList();
        if (selectedTopic == null && filteredTopics.isNotEmpty) {
          selectedTopic = filteredTopics.first;
        }

        return AlertDialog(
          title: const Text('Adicionar Tarefa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Subject>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (s) => setS(() {
                  selectedSubject = s;
                  selectedTopic = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Topic>(
                key: ValueKey(selectedSubject?.id),
                initialValue:
                    filteredTopics.isNotEmpty ? filteredTopics.first : null,
                decoration: const InputDecoration(labelText: 'Tópico'),
                items: filteredTopics
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (t) => setS(() => selectedTopic = t),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '$plannedMinutes',
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duração planejada (min)'),
                onChanged: (v) =>
                    plannedMinutes = int.tryParse(v) ?? plannedMinutes,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedSubject == null || selectedTopic == null) return;
                final activeGoalId = ref.read(activeGoalIdProvider);
                if (activeGoalId == null) return;
                ref.read(dailyTaskControllerProvider.notifier).addManualTask(
                      DailyTask(
                        id: const Uuid().v4(),
                        userId: user.uid,
                        goalId: activeGoalId,
                        date:
                            AppDateUtils.toKey(ref.read(selectedDateProvider)),
                        subjectId: selectedSubject!.id,
                        topicId: selectedTopic!.id,
                        plannedMinutes: plannedMinutes,
                        done: false,
                        actualMinutes: 0,
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _fetchAIInsight() async {
    final activeGoal = ref.read(activeGoalProvider);
    final tasks = ref.read(dailyTasksProvider).valueOrNull ?? [];
    final user = ref.read(authStateProvider).valueOrNull;

    final dashboard = ref.read(dashboardProvider).valueOrNull;

    if (activeGoal == null || user == null) return;

    final taskIds = tasks.map((t) => t.id).join(',');
    final currentKey = "${activeGoal.id}_$taskIds";
    if (currentKey == _lastInsightKey && _aiInsight != null) return;

    setState(() {
      _isFetchingInsight = true;
      _lastInsightKey = currentKey;
    });

    try {
      final aiServiceProviderFuture = ref.read(aiServiceProvider.future);
      final aiService = await aiServiceProviderFuture;
      if (aiService != null) {
        final insight = await aiService.getDailyInsight(
          userId: user.uid,
          objective: activeGoal.name,
          streak: dashboard?.streakDays ?? 0,
          consistency: dashboard?.consistencyPct ?? 0.0,
          taskNames: tasks.map((t) {
            final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
            final s = subjects.firstWhere((s) => s.id == t.subjectId,
                orElse: () => Subject(
                    id: '',
                    userId: '',
                    name: 'Matéria',
                    color: '',
                    priority: 0,
                    weight: 0,
                    difficulty: 0));
            return s.name;
          }).toList(),
        );
        if (mounted) setState(() => _aiInsight = insight);
      }
    } catch (e) {
      debugPrint("Erro ao buscar insight IA: $e");
    } finally {
      if (mounted) setState(() => _isFetchingInsight = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAIInsight();
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTask task;
  final Subject? subject;
  final String topicName;
  final bool showPomodoro;
  final VoidCallback onTogglePomodoro;
  final void Function(int minutes) onToggleDone;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.subject,
    required this.topicName,
    required this.showPomodoro,
    required this.onTogglePomodoro,
    required this.onToggleDone,
    required this.onDelete,
  });

  Color _subjectColor() {
    if (subject == null) return AppTheme.primary;
    final hex = subject!.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: task.done
            ? Theme.of(context).colorScheme.surface
            : (Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.done
              ? Theme.of(context).dividerColor
              : color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: task.done,
                  onChanged: (_) => onToggleDone(task.plannedMinutes),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),

              // Subject name
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    subject?.name ?? 'Matéria',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  topicName,
                  style: TextStyle(
                    color: task.done
                        ? (Theme.of(context).textTheme.labelSmall?.color ??
                            Colors.grey)
                        : (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white),
                    fontWeight: FontWeight.w500,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              // Trailing actions group
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time
                  Text(
                    AppDateUtils.formatMinutes(task.plannedMinutes),
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.labelSmall?.color ??
                          Colors.grey),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pomodoro toggle
                  if (!task.done)
                    IconButton(
                      icon: Icon(
                        Icons.timer_rounded,
                        color: showPomodoro
                            ? AppTheme.primary
                            : (Theme.of(context).textTheme.labelSmall?.color ??
                                Colors.grey),
                        size: 18,
                      ),
                      onPressed: onTogglePomodoro,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  const SizedBox(width: 12),

                  // Delete
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: (Theme.of(context).textTheme.labelSmall?.color ??
                            Colors.grey),
                        size: 18),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          if (showPomodoro)
            const Padding(
              padding: EdgeInsets.only(top: 12, left: 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PomodoroTimer(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AIMentorCard extends StatelessWidget {
  final String? insight;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _AIMentorCard({
    required this.insight,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (insight == null && !isLoading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.8),
            AppTheme.accent.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Insights do Seu Mentor',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                InkWell(
                  onTap: onRefresh,
                  child: Icon(Icons.refresh_rounded,
                      color: Colors.white.withValues(alpha: 0.7), size: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading && insight == null)
            Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Text(
              insight ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyChecklistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: (Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_rounded,
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
              size: 48),
          const SizedBox(height: 16),
          Text(
            'Nenhuma tarefa para hoje',
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um plano de estudo para gerar seu cronograma\nou adicione uma tarefa manualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey),
                fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.go('/subjects'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Sugerir com IA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const StudyPlanWizardDialog(),
            ),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('Configurar Plano de Estudo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
