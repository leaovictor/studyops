import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/daily_task_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/daily_task_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../widgets/pomodoro_timer.dart';

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

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
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
      backgroundColor: AppTheme.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context, subjects, allTopics),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tarefa'),
      ),
      body: Stack(
        children: [
          CustomScrollView(
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checklist Diário',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
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
                                ref.read(selectedDateProvider.notifier).state =
                                    picked;
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 16),
                            label: Text(AppDateUtils.displayDate(selectedDate)),
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
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
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
                                backgroundColor: AppTheme.border,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      if (tasks.isEmpty)
                        _EmptyChecklistState()
                      else
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: widget,
                                ),
                              ),
                              children: tasks.map((task) {
                                final subject = subjectMap[task.subjectId];
                                final topic = topicMap[task.topicId];
                                final showPomodoro = _pomodoroTaskId == task.id;

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
                                    onDelete: () =>
                                        controller.deleteTask(task.id),
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
                ref.read(dailyTaskControllerProvider.notifier).addManualTask(
                      DailyTask(
                        id: const Uuid().v4(),
                        userId: user.uid,
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
        color: task.done ? AppTheme.bg1 : AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.done ? AppTheme.border : color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.done,
                onChanged: (_) => onToggleDone(task.plannedMinutes),
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8),

              // Subject badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subject?.name ?? 'Matéria',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  topicName,
                  style: TextStyle(
                    color:
                        task.done ? AppTheme.textMuted : AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),

              // Time
              Text(
                AppDateUtils.formatMinutes(task.plannedMinutes),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),

              // Pomodoro toggle
              if (!task.done) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.timer_rounded,
                    color: showPomodoro ? AppTheme.primary : AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: onTogglePomodoro,
                  visualDensity: VisualDensity.compact,
                ),
              ],

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textMuted, size: 18),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (showPomodoro)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 40),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const PomodoroTimer(),
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
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checklist_rounded,
              color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma tarefa para hoje',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie um plano de estudo para gerar seu cronograma\nou adicione uma tarefa manualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.go('/settings'),
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
