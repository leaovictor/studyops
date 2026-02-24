import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../controllers/auth_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/study_plan_model.dart';
import '../models/subject_model.dart';
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
    this.objective = '',
    required this.deadline,
    this.dailyHours = 3.0,
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
    if (_currentPage < 3) {
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

    // Filter valid subjects
    final validSubjects =
        _data.subjects.where((s) => s.name.trim().isNotEmpty).toList();

    // Save subjects first (and create a default "Geral" topic for each)
    final controller = ref.read(subjectControllerProvider.notifier);
    for (final s in validSubjects) {
      final subject = Subject(
        id: s.id,
        userId: user.uid,
        name: s.name.trim(),
        color: s.color,
        priority: s.priority,
        weight: s.priority, // default weight = priority
      );
      await controller.createSubjectWithId(subject);
      await controller.createDefaultTopic(s.id);
    }

    // Create study plan
    final durationDays =
        _data.deadline.difference(DateTime.now()).inDays.clamp(7, 365);
    final plan = StudyPlan(
      id: '',
      userId: user.uid,
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
      backgroundColor: AppTheme.bg0,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppTheme.textSecondary),
                visualDensity: VisualDensity.compact,
              )
            else
              const SizedBox(width: 40),
            const Spacer(),
            // Logo
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Study',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
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
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (currentPage + 1) / totalPages),
            duration: const Duration(milliseconds: 400),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ),
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
        const Text(
          '🎯 Qual é o seu objetivo?',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Isso vai guiar toda a sua estratégia de estudos.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _ctrl,
          onChanged: (v) => widget.data.objective = v,
          decoration: const InputDecoration(
            labelText: 'Ex: ENEM 2025, Concurso INSS, OAB...',
            prefixIcon: Icon(Icons.flag_rounded),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 20),
        // Deadline picker
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.bg3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prazo (data da prova)',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        '${widget.data.deadline.day.toString().padLeft(2, '0')}/'
                        '${widget.data.deadline.month.toString().padLeft(2, '0')}/'
                        '${widget.data.deadline.year}',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.data.deadline.difference(DateTime.now()).inDays} dias até o prazo',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
        const Text(
          '⏰ Quantas horas por dia?',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seja realista — consistência vale mais que volume.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
              const Text(
                'por dia',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30 min',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            Text('12h',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 24),
        // Recomendations
        _RecommendationChips(
          hours: data.dailyHours,
          onTap: (v) => setState(() => data.dailyHours = v),
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
          selectedColor: AppTheme.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
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
class _Step3Subjects extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final validCount =
        data.subjects.where((s) => s.name.trim().isNotEmpty).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Suas matérias',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adicione as matérias do seu estudo. Você pode editar depois.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: data.subjects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              if (i == data.subjects.length) {
                return TextButton.icon(
                  onPressed: () => setState(() {
                    data.subjects.add(_OnboardingSubject(
                      id: const Uuid().v4(),
                      color: AppConstants.defaultSubjectColors[
                          data.subjects.length %
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
              final s = data.subjects[i];
              return _SubjectRow(
                subject: s,
                onNameChanged: (v) => s.name = v,
                onColorChanged: (c) => setState(() => s.color = c),
                onPriorityChanged: (p) => setState(() => s.priority = p),
                onDelete: data.subjects.length > 1
                    ? () => setState(() => data.subjects.removeAt(i))
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _ContinueButton(
          onPressed: validCount > 0 ? onNext : null,
          label: 'Gerar meu plano →',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: onSkip,
            child: const Text(
              'Pular esta etapa',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
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
                    color: Colors.white.withOpacity(0.3), width: 1.5),
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
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppTheme.textMuted),
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
                      ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)]
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
                      color: AppTheme.accent.withOpacity(0.15),
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
                        color: AppTheme.primary.withOpacity(0.15),
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
                ? const Column(
                    key: ValueKey('done_text'),
                    children: [
                      Text(
                        'Plano gerado! 🎉',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Seu cronograma personalizado está pronto.\nBoa sorte nos estudos!',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : const Column(
                    key: ValueKey('loading_text'),
                    children: [
                      Text(
                        'Gerando seu plano...',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Distribuindo matérias, calculando\npesos e montando seu cronograma.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
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
