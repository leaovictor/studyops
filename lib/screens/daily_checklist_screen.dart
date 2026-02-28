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
import '../controllers/error_notebook_controller.dart';
import '../widgets/study_plan_wizard_dialog.dart';
import '../models/daily_task_model.dart';
import '../models/error_note_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/knowledge_check_model.dart';
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
    final allErrorNotes = ref.watch(errorNotesProvider).valueOrNull ?? [];
    final selectedDate = ref.watch(selectedDateProvider);
    final controller = ref.read(dailyTaskControllerProvider.notifier);
    final errorController = ref.read(errorNotebookControllerProvider.notifier);

    // Filter error notes due today (only for today's view)
    final isViewingToday =
        AppDateUtils.toKey(selectedDate) == AppDateUtils.toKey(DateTime.now());
    final dueErrorNotes = isViewingToday
        ? allErrorNotes.where((n) => n.isDueToday).toList()
        : <ErrorNote>[];

    final doneTasks = tasks.where((t) => t.done).length;
    final totalTasks = tasks.length + dueErrorNotes.length;
    final progress = totalTasks > 0 ? doneTasks / totalTasks : 0.0;

    // Trigger confetti when hitting 100%
    if (progress == 1.0 && totalTasks > 0 && !_wasDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
      _wasDone = true;
    } else if (progress < 1.0) {
      _wasDone = false;
    }

    final subjectMap = {for (final s in subjects) s.id: s};
    final topicMap = {for (final t in allTopics) t.id: t};

    // Combine tasks and error notes for display
    final List<dynamic> combinedItems = [...tasks, ...dueErrorNotes];

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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    builder: (context) => StudyPlanWizardDialog(
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
                                          size: 18, color: AppTheme.primary),
                                      SizedBox(width: 12),
                                      Text('Gerenciar Plano (IA)'),
                                    ],
                                  ),
                                ),
                              ],
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
                                  '$doneTasks/$totalTasks tarefas concluídas',
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
                          onRefresh: () => _fetchAIInsight(forceRefresh: true),
                        ),

                        const SizedBox(height: 24),

                        if (combinedItems.isEmpty)
                          _EmptyChecklistState(subjects: subjects)
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
                                children: combinedItems.map((item) {
                                  if (item is DailyTask) {
                                    final subject = subjectMap[item.subjectId];
                                    final topic = topicMap[item.topicId];
                                    final showPomodoro =
                                        _pomodoroTaskId == item.id;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _ChecklistCard(
                                        title: topic?.name ?? 'Tópico',
                                        isDone: item.done,
                                        subject: subject,
                                        plannedMinutes: item.plannedMinutes,
                                        showPomodoro: showPomodoro,
                                        onTogglePomodoro: () {
                                          setState(() {
                                            _pomodoroTaskId =
                                                showPomodoro ? null : item.id;
                                          });
                                        },
                                        onToggleDone: (minutes) {
                                          if (item.done) {
                                            controller.markUndone(item.id);
                                          } else {
                                            // Trigger AI Knowledge Check before marking as done
                                            if (subject != null &&
                                                topic != null) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) =>
                                                    _KnowledgeCheckDialog(
                                                  subject: subject,
                                                  topicName: topic.name,
                                                  onCompleted: (correctCount,
                                                      totalQuestions) {
                                                    Navigator.pop(
                                                        context); // Close dialog

                                                    // Calculate productive minutes
                                                    int productiveMins = 0;
                                                    if (totalQuestions > 0) {
                                                      final score =
                                                          correctCount /
                                                              totalQuestions;
                                                      if (score >= 0.6) {
                                                        productiveMins =
                                                            minutes; // Approve all tracked minutes
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Sua nota foi ${(score * 100).toInt()}% (Abaixo da média de 60%). Seu tempo não foi contabilizado como produtivo.')),
                                                        );
                                                      }
                                                    }

                                                    final updatedItem =
                                                        item.copyWith(
                                                            productiveMinutes:
                                                                productiveMins);
                                                    controller.markDone(
                                                        updatedItem, minutes);
                                                    _confettiController.play();
                                                  },
                                                ),
                                              );
                                            } else {
                                              // Fallback if no subject mapping
                                              controller.markDone(
                                                  item, minutes);
                                              _confettiController.play();
                                            }
                                          }
                                        },
                                        onDelete: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text('Excluir Tarefa'),
                                              content: const Text(
                                                  'Tem certeza que deseja excluir esta tarefa?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AppTheme.error,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Excluir'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            controller.deleteTask(item.id);
                                          }
                                        },
                                      ),
                                    );
                                  } else if (item is ErrorNote) {
                                    final subject = subjectMap[item.subjectId];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _ChecklistCard(
                                        title: item.question,
                                        isDone: false,
                                        subject: subject,
                                        isErrorNote: true,
                                        onToggleDone: (_) {
                                          errorController.markReviewed(item);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Revisão adiada com sucesso! 🧠'),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        onDelete: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Excluir Nota'),
                                              content: const Text(
                                                  'Tem certeza que deseja remover esta nota do Caderno de Erros?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AppTheme.error,
                                                    foregroundColor:
                                                        Colors.white,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Excluir'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            errorController.deleteNote(item.id);
                                          }
                                        },
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
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

  Future<void> _fetchAIInsight({bool forceRefresh = false}) async {
    final activeGoal = ref.read(activeGoalProvider);
    final tasks = ref.read(dailyTasksProvider).valueOrNull ?? [];
    final user = ref.read(authStateProvider).valueOrNull;

    final dashboard = ref.read(dashboardProvider).valueOrNull;

    if (activeGoal == null || user == null) return;

    final taskIds = tasks.map((t) => t.id).join(',');
    final currentKey = "${activeGoal.id}_$taskIds";
    if (!forceRefresh && currentKey == _lastInsightKey && _aiInsight != null)
      return;

    setState(() {
      _isFetchingInsight = true;
      _lastInsightKey = currentKey;
    });

    try {
      final aiServiceProviderFuture = ref.read(aiServiceProvider.future);
      final aiService = await aiServiceProviderFuture;
      final userModel = ref.read(userSessionProvider).valueOrNull;

      if (aiService != null) {
        final insight = await aiService.getDailyInsight(
          userId: user.uid,
          objective: activeGoal.name,
          streak: dashboard?.streakDays ?? 0,
          consistency: dashboard?.consistencyPct ?? 0.0,
          personalContext: userModel?.personalContext,
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

class _ChecklistCard extends StatefulWidget {
  final String title;
  final bool isDone;
  final Subject? subject;
  final int? plannedMinutes;
  final bool showPomodoro;
  final VoidCallback? onTogglePomodoro;
  final void Function(int minutes) onToggleDone;
  final VoidCallback onDelete;
  final bool isErrorNote;

  const _ChecklistCard({
    required this.title,
    required this.isDone,
    required this.subject,
    this.plannedMinutes,
    this.showPomodoro = false,
    this.onTogglePomodoro,
    required this.onToggleDone,
    required this.onDelete,
    this.isErrorNote = false,
  });

  @override
  State<_ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<_ChecklistCard> {
  bool _isExpanded = false;

  Color _subjectColor() {
    if (widget.subject == null) return AppTheme.primary;
    final hex = widget.subject!.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor();

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDone
              ? Theme.of(context).colorScheme.surface
              : (Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDone
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
                    value: widget.isDone,
                    onChanged: (_) =>
                        widget.onToggleDone(widget.plannedMinutes ?? 0),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),

                // Subject name
                Expanded(
                  flex: 3,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.subject?.name ?? 'Matéria',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: _isExpanded ? null : 1,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  flex: 5,
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.isDone
                          ? (Theme.of(context).textTheme.labelSmall?.color ??
                              Colors.grey)
                          : (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white),
                      fontWeight: FontWeight.w500,
                      decoration:
                          widget.isDone ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: _isExpanded ? null : 1,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 12),

                // Trailing actions group
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isErrorNote)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REVISÃO',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (widget.plannedMinutes != null)
                      Text(
                        AppDateUtils.formatMinutes(widget.plannedMinutes!),
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.labelSmall?.color ??
                                  Colors.grey),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(width: 8),

                    // Pomodoro toggle
                    if (!widget.isDone && widget.onTogglePomodoro != null)
                      IconButton(
                        icon: Icon(
                          Icons.timer_rounded,
                          color: widget.showPomodoro
                              ? AppTheme.primary
                              : (Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.color ??
                                  Colors.grey),
                          size: 18,
                        ),
                        onPressed: widget.onTogglePomodoro,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    const SizedBox(width: 12),

                    // Delete
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color:
                              (Theme.of(context).textTheme.labelSmall?.color ??
                                  Colors.grey),
                          size: 18),
                      onPressed: widget.onDelete,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.showPomodoro)
              const Padding(
                padding: EdgeInsets.only(top: 12, left: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PomodoroTimer(),
                ),
              ),
          ],
        ),
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
  final List<Subject> subjects;

  const _EmptyChecklistState({required this.subjects});

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
            subjects.isEmpty
                ? 'Comece cadastrando as matérias que você precisa estudar para o seu objetivo.'
                : 'Crie um plano de estudo para que a IA gere seu cronograma diário.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey),
                fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (subjects.isEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/subjects'),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Sugerir Matérias com IA'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const StudyPlanWizardDialog(),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Gerar Cronograma com IA'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => subjects.isEmpty
                ? context.go('/subjects')
                : showDialog(
                    context: context,
                    builder: (context) => const StudyPlanWizardDialog(),
                  ),
            icon: Icon(
                subjects.isEmpty
                    ? Icons.list_alt_rounded
                    : Icons.calendar_month_rounded,
                size: 16),
            label: Text(subjects.isEmpty
                ? 'Cadastrar Matérias Manualmente'
                : 'Configurar Plano de Estudo'),
            style: TextButton.styleFrom(
              foregroundColor:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeCheckDialog extends ConsumerStatefulWidget {
  final Subject subject;
  final String topicName;
  final void Function(int correctAnswers, int totalQuestions) onCompleted;

  const _KnowledgeCheckDialog({
    required this.subject,
    required this.topicName,
    required this.onCompleted,
  });

  @override
  ConsumerState<_KnowledgeCheckDialog> createState() =>
      _KnowledgeCheckDialogState();
}

class _KnowledgeCheckDialogState extends ConsumerState<_KnowledgeCheckDialog> {
  List<KnowledgeCheckQuestion>? _questions;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  bool? _lastAnswerCorrect;
  bool _showExplanation = false;
  int _correctCount = 0;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    try {
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception("IA não configurada.");

      final questions = await aiService.generateKnowledgeCheck(
        subject: widget.subject.name,
        topic: widget.topicName,
      );

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
          if (questions.isEmpty) {
            _error = "Não foi possível gerar as perguntas.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _answer(bool isTrue) {
    if (_questions == null) return;
    final currentQ = _questions![_currentIndex];
    final isCorrect = isTrue == currentQ.isTrue;

    setState(() {
      _lastAnswerCorrect = isCorrect;
      _showExplanation = true;
      if (isCorrect) _correctCount++;
    });

    if (!isCorrect) {
      _saveToErrorNotebook(currentQ);
    }
  }

  Future<void> _saveToErrorNotebook(KnowledgeCheckQuestion question) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final activeGoalId = ref.read(activeGoalIdProvider);
    if (user == null) return;

    final note = ErrorNote(
      id: const Uuid().v4(),
      userId: user.uid,
      goalId: activeGoalId,
      subjectId: widget.subject.id,
      topicId: widget.topicName,
      question: "[V/F] ${question.statement}",
      correctAnswer: question.isTrue
          ? "Verdadeiro. ${question.explanation}"
          : "Falso. ${question.explanation}",
      errorReason: "Errei no teste rápido ao concluir a tarefa.",
      nextReview: DateTime.now().add(const Duration(days: 1)),
      reviewStage: 0,
    );

    try {
      await ref.read(errorNotebookControllerProvider.notifier).createNote(note);
    } catch (e) {
      debugPrint("Erro salvando no caderno: $e");
    }
  }

  void _nextQuestion() {
    if (_questions == null) return;

    if (_currentIndex < _questions!.length - 1) {
      setState(() {
        _currentIndex++;
        _showExplanation = false;
        _lastAnswerCorrect = null;
      });
    } else {
      widget.onCompleted(_correctCount, _questions!.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Gerando teste rápido de ${widget.subject.name}...'),
          ],
        ),
      );
    }

    if (_error != null || _questions == null || _questions!.isEmpty) {
      return AlertDialog(
        title: const Text('Ops!'),
        content: Text(_error ?? 'Erro ao gerar o teste.'),
        actions: [
          TextButton(
              onPressed: () => widget.onCompleted(0, 0),
              child: const Text('Pular Teste e Concluir Tarefa')),
        ],
      );
    }

    final currentQ = _questions![_currentIndex];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Teste Rápido', style: TextStyle(fontSize: 18)),
            ],
          ),
          Text(
            '${_currentIndex + 1}/${_questions!.length}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            currentQ.statement,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (!_showExplanation) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () => _answer(true),
                    child: const Text('Verdadeiro'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    onPressed: () => _answer(false),
                    child: const Text('Falso'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _lastAnswerCorrect!
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          _lastAnswerCorrect! ? Colors.green : AppTheme.error)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _lastAnswerCorrect!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color:
                            _lastAnswerCorrect! ? Colors.green : AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _lastAnswerCorrect! ? 'Correto!' : 'Incorreto!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lastAnswerCorrect!
                              ? Colors.green
                              : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentQ.explanation,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (!_lastAnswerCorrect!) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Salvo no Caderno de Erros 📓',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _nextQuestion,
              child: Text(_currentIndex < _questions!.length - 1
                  ? 'Próxima'
                  : 'Concluir Tarefa'),
            )
          ]
        ],
      ),
    );
  }
}
