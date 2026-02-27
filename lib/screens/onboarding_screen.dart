import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../controllers/auth_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/goal_controller.dart';
import '../models/study_plan_model.dart';
import '../models/subject_model.dart';
import '../models/goal_model.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Onboarding state holder
// ---------------------------------------------------------------------------
class _OnboardingData {
  String objective;
  DateTime deadline;
  double dailyHours;
  List<_OnboardingSubject> subjects;

  _OnboardingData({
    required this.objective,
    required this.deadline,
    required this.dailyHours,
    required this.subjects,
  });
}

class _OnboardingSubject {
  final String id;
  String name;
  String color;
  int priority;

  _OnboardingSubject({
    required this.id,
    this.name = '',
    required this.color,
    this.priority = 3,
  });
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  late final _OnboardingData _data;

  @override
  void initState() {
    super.initState();
    _data = _OnboardingData(
      objective: '',
      dailyHours: 3.0,
      deadline: DateTime.now().add(const Duration(days: 60)),
      subjects: [
        _OnboardingSubject(
          id: const Uuid().v4(),
          color: AppConstants.defaultSubjectColors.first,
          name: '',
          priority: 3,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _finish() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // 1. Create the Goal
    final goalName =
        _data.objective.trim().isNotEmpty ? _data.objective.trim() : 'Geral';

    // We need to create the goal and get its ID
    final goalService = ref.read(goalServiceProvider);
    final goal = await goalService.createGoal(Goal(
      id: '',
      userId: user.uid,
      name: goalName,
      createdAt: DateTime.now(),
    ));

    // Set as active goal
    ref.read(activeGoalIdProvider.notifier).state = goal.id;

    // 2. Filter valid subjects and link to the goal
    final validSubjects =
        _data.subjects.where((s) => s.name.trim().isNotEmpty).toList();

    final subjectController = ref.read(subjectControllerProvider.notifier);
    for (final s in validSubjects) {
      final subject = Subject(
        id: s.id,
        userId: user.uid,
        goalId: goal.id, // Linked to the new goal
        name: s.name.trim(),
        color: s.color,
        priority: s.priority,
        weight: s.priority, // default weight = priority
        difficulty: 3,
      );
      await subjectController.createSubjectWithId(subject);
      await subjectController.createDefaultTopic(s.id);
    }

    // 3. Create study plan
    final durationDays =
        _data.deadline.difference(DateTime.now()).inDays.clamp(7, 365);
    final plan = StudyPlan(
      id: '',
      userId: user.uid,
      goalId: goal.id,
      startDate: DateTime.now(),
      durationDays: durationDays,
      dailyHours: _data.dailyHours,
    );

    await ref
        .read(studyPlanControllerProvider.notifier)
        .createPlanAndGenerate(plan);

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width >= 600 ? 32 : 16),
              child: Column(
                children: [
                  // Top logo + progress
                  _OnboardingHeader(
                    currentPage: _currentPage,
                    totalPages: 4,
                    onBack: _currentPage > 0 ? _prevPage : null,
                  ),
                  const SizedBox(height: 32),

                  // Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _Step0Welcome(onNext: _nextPage),
                        _Step1Objective(data: _data, onNext: _nextPage),
                        _Step2Hours(
                            data: _data, onNext: _nextPage, setState: setState),
                        _Step3Subjects(
                            data: _data,
                            onNext: _nextPage,
                            onSkip: _nextPage,
                            setState: setState),
                        _Step4Generating(onFinish: _finish),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _OnboardingHeader extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onBack;

  const _OnboardingHeader({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_rounded,
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey)),
                visualDensity: VisualDensity.compact,
              )
            else
              const SizedBox(width: 40),
            const Spacer(),
            // Logo
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Study',
                    style: TextStyle(
                        color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white),
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(
                    text: 'Ops',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 40,
              child: Text(
                '${currentPage + 1}/$totalPages',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (currentPage + 1) / totalPages),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 3,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.close_rounded,
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 0 — Boas-vindas
// ---------------------------------------------------------------------------
class _Step0Welcome extends StatelessWidget {
  final VoidCallback onNext;
  const _Step0Welcome({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: AppTheme.primary, size: 64),
        ),
        const SizedBox(height: 32),
        Text(
          'Olá, futuro aprovado! 👋',
          style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
              fontSize: 28,
              fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'O StudyOps é o seu novo quartel-general de estudos. Vamos configurar seu primeiro objetivo em menos de 2 minutos?',
          style: TextStyle(
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 16,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        _ContinueButton(onPressed: onNext, label: 'Começar Jornada! 🚀'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Objetivo + Prazo
// ---------------------------------------------------------------------------
class _Step1Objective extends StatefulWidget {
  final _OnboardingData data;
  final VoidCallback onNext;
  const _Step1Objective({required this.data, required this.onNext});

  @override
  State<_Step1Objective> createState() => _Step1ObjectiveState();
}

class _Step1ObjectiveState extends State<_Step1Objective> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.data.objective);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.data.deadline,
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked != null) setState(() => widget.data.deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎯 Qual é o seu objetivo?',
          style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Isso vai guiar toda a sua estratégia de estudos.',
          style: TextStyle(
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _ctrl,
          onChanged: (v) => widget.data.objective = v,
          decoration: const InputDecoration(
            labelText: 'Ex: ENEM 2025, Concurso INSS, OAB...',
            prefixIcon: Icon(Icons.flag_rounded),
          ),
          style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white)),
        ),
        const SizedBox(height: 20),
        // Deadline picker
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prazo (data da prova)',
                          style: TextStyle(
                              color: (Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey),
                              fontSize: 12)),
                      Text(
                        '${widget.data.deadline.day.toString().padLeft(2, '0')}/'
                        '${widget.data.deadline.month.toString().padLeft(2, '0')}/'
                        '${widget.data.deadline.year}',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.white),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.data.deadline.difference(DateTime.now()).inDays} dias até o prazo',
          style: TextStyle(
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
              fontSize: 12),
        ),
        const SizedBox(height: 24),
        const _GamifiedTip(
          text:
              'Dica de Ouro: Ter um objetivo claro e um prazo definido aumenta sua chance de sucesso em até 40%!',
          icon: Icons.tips_and_updates_rounded,
        ),
        const Spacer(),
        _ContinueButton(
          onPressed:
              widget.data.objective.trim().isNotEmpty ? widget.onNext : null,
          label: 'Continuar',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Horas por dia
// ---------------------------------------------------------------------------
class _Step2Hours extends StatelessWidget {
  final _OnboardingData data;
  final VoidCallback onNext;
  final void Function(void Function()) setState;

  const _Step2Hours({
    required this.data,
    required this.onNext,
    required this.setState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⏰ Quantas horas por dia?',
          style: TextStyle(
              color: (Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.white),
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Seja realista — consistência vale mais que volume.',
          style: TextStyle(
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
              fontSize: 14),
        ),
        const SizedBox(height: 48),
        Center(
          child: Column(
            children: [
              Text(
                '${data.dailyHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'por dia',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Slider(
          value: data.dailyHours,
          min: 0.5,
          max: 12,
          divisions: 23,
          activeColor: AppTheme.primary,
          onChanged: (v) => setState(() => data.dailyHours = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30 min',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    fontSize: 12)),
            Text('12h',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.labelSmall?.color ??
                        Colors.grey),
                    fontSize: 12)),
          ],
        ),
        const SizedBox(height: 24),
        // Recomendations
        _RecommendationChips(
          hours: data.dailyHours,
          onTap: (v) => setState(() => data.dailyHours = v),
        ),
        const SizedBox(height: 24),
        const _GamifiedTip(
          text:
              'Menos é Mais: É melhor estudar 1h todo dia com foco total do que 6h uma vez por semana e desistir.',
          icon: Icons.timer_outlined,
        ),
        const Spacer(),
        _ContinueButton(onPressed: onNext, label: 'Continuar'),
      ],
    );
  }
}

class _RecommendationChips extends StatelessWidget {
  final double hours;
  final void Function(double) onTap;
  const _RecommendationChips({required this.hours, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final opts = [1.0, 2.0, 3.0, 4.0, 6.0];
    return Wrap(
      spacing: 8,
      children: opts.map((h) {
        final selected = (hours - h).abs() < 0.1;
        return ChoiceChip(
          label: Text('${h.toStringAsFixed(0)}h'),
          selected: selected,
          onSelected: (_) => onTap(h),
          selectedColor: AppTheme.primary.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: selected
                ? AppTheme.primary
                : (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Matérias
// ---------------------------------------------------------------------------
class _Step3Subjects extends ConsumerStatefulWidget {
  final _OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final void Function(void Function()) setState;

  const _Step3Subjects({
    required this.data,
    required this.onNext,
    required this.onSkip,
    required this.setState,
  });

  @override
  ConsumerState<_Step3Subjects> createState() => _Step3SubjectsState();
}

class _Step3SubjectsState extends ConsumerState<_Step3Subjects> {
  bool _isGenerating = false;

  Future<void> _suggestWithAI() async {
    if (widget.data.objective.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, defina um objetivo primeiro!')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final aiService = await ref.read(aiServiceProvider.future);

      if (aiService == null || user == null) {
        throw Exception('IA não configurada ou usuário não logado.');
      }

      final suggestions = await aiService.suggestSubjectsForObjective(
        user.uid,
        widget.data.objective,
      );

      if (suggestions.isNotEmpty) {
        widget.setState(() {
          // Limpa matérias vazias se houver mais de uma
          widget.data.subjects.removeWhere((s) => s.name.trim().isEmpty);

          for (final suggestion in suggestions) {
            final name = suggestion['name'] as String;
            widget.data.subjects.add(_OnboardingSubject(
              id: const Uuid().v4(),
              color: suggestion['color'] as String? ??
                  AppConstants.defaultSubjectColors[
                      widget.data.subjects.length %
                          AppConstants.defaultSubjectColors.length],
              name: name,
              priority: (suggestion['priority'] as num?)?.toInt() ?? 3,
            ));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sugerir matérias: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCount =
        widget.data.subjects.where((s) => s.name.trim().isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Suas matérias',
                    style: TextStyle(
                        color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white),
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione as matérias do seu estudo. Você pode editar depois.',
                    style: TextStyle(
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            if (!_isGenerating)
              IconButton.filledTonal(
                onPressed: _suggestWithAI,
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                ),
                tooltip: 'Sugerir com IA',
              )
            else
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: widget.data.subjects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == widget.data.subjects.length) {
                return TextButton.icon(
                  onPressed: () => widget.setState(() {
                    widget.data.subjects.add(_OnboardingSubject(
                      id: const Uuid().v4(),
                      color: AppConstants.defaultSubjectColors[
                          widget.data.subjects.length %
                              AppConstants.defaultSubjectColors.length],
                      name: '',
                      priority: 3,
                    ));
                  }),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Adicionar matéria'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppTheme.primary),
                );
              }
              final s = widget.data.subjects[i];
              return _SubjectRow(
                subject: s,
                onNameChanged: (v) => s.name = v,
                onColorChanged: (c) => widget.setState(() => s.color = c),
                onPriorityChanged: (p) => widget.setState(() => s.priority = p),
                onDelete: widget.data.subjects.length > 1
                    ? () =>
                        widget.setState(() => widget.data.subjects.removeAt(i))
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const _GamifiedTip(
          text:
              'Poder do Foco: Distribuímos o seu tempo baseando-se no peso de cada matéria. Quanto mais importante, mais você verá ela!',
          icon: Icons.psychology_rounded,
        ),
        const SizedBox(height: 20),
        _ContinueButton(
          onPressed: validCount > 0 ? widget.onNext : null,
          label: 'Gerar meu plano →',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Pular esta etapa',
              style: TextStyle(
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey),
                  fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatefulWidget {
  final _OnboardingSubject subject;
  final void Function(String) onNameChanged;
  final void Function(String) onColorChanged;
  final void Function(int) onPriorityChanged;
  final VoidCallback? onDelete;

  const _SubjectRow({
    required this.subject,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.onPriorityChanged,
    required this.onDelete,
  });

  @override
  State<_SubjectRow> createState() => _SubjectRowState();
}

class _SubjectRowState extends State<_SubjectRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.subject.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
        int.parse('FF${widget.subject.color.replaceAll('#', '')}', radix: 16));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Color dot picker
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onNameChanged,
              decoration: const InputDecoration(
                hintText: 'Nome da matéria',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(Icons.close_rounded,
                  size: 16,
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey)),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolher cor'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppConstants.defaultSubjectColors.map((hex) {
            final c =
                Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
            final selected = hex == widget.subject.color;
            return GestureDetector(
              onTap: () {
                widget.onColorChanged(hex);
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: c.withValues(alpha: 0.5), blurRadius: 6)
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — Generating
// ---------------------------------------------------------------------------
class _Step4Generating extends StatefulWidget {
  final Future<void> Function() onFinish;
  const _Step4Generating({required this.onFinish});

  @override
  State<_Step4Generating> createState() => _Step4GeneratingState();
}

class _Step4GeneratingState extends State<_Step4Generating>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Trigger after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    await widget.onFinish();
    if (mounted) {
      _anim.stop();
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _done
                ? Container(
                    key: const ValueKey('done'),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppTheme.accent, size: 48),
                  )
                : RotationTransition(
                    key: const ValueKey('loading'),
                    turns: _anim,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.primary, size: 48),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _done
                ? Column(
                    key: const ValueKey('done_text'),
                    children: [
                      Text(
                        'Plano gerado! 🎉',
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.white),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Seu cronograma personalizado está pronto.\nBoa sorte nos estudos!',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey),
                            fontSize: 15,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('loading_text'),
                    children: [
                      Text(
                        'Gerando seu plano...',
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.white),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Distribuindo matérias, calculando\npesos e montando seu cronograma.',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey),
                            fontSize: 15,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// --------------------------------------------------------------------------
class _GamifiedTip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _GamifiedTip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: (Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Button
// ---------------------------------------------------------------------------
class _ContinueButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const _ContinueButton({
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
