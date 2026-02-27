import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../models/study_plan_model.dart';

class StudyPlanWizardDialog extends ConsumerStatefulWidget {
  final StudyPlan? activePlan;

  const StudyPlanWizardDialog({
    super.key,
    this.activePlan,
  });

  @override
  ConsumerState<StudyPlanWizardDialog> createState() =>
      _StudyPlanWizardDialogState();
}

class _StudyPlanWizardDialogState extends ConsumerState<StudyPlanWizardDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late double _dailyHours;
  final TextEditingController _routineController = TextEditingController();
  bool _isSuggestingAI = false;

  Future<void> _suggestConfigWithAI(BuildContext context) async {
    if (_routineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Descreva sua rotina para a IA te ajudar.')),
      );
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    final activeGoal = ref.read(activeGoalProvider);
    if (user == null || activeGoal == null) return;

    setState(() => _isSuggestingAI = true);

    try {
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception('IA não configurada');

      final suggestion = await aiService.suggestStudyPlanConfig(
        userId: user.uid,
        objective: activeGoal.name,
        routineContext: _routineController.text,
      );

      final startDate = DateTime.parse(suggestion['startDate']);
      final duration = suggestion['durationDays'] as int;
      final hours = (suggestion['dailyHours'] as num).toDouble();
      final reason = suggestion['reasoning'] as String;

      setState(() {
        _startDate = startDate;
        _endDate = startDate.add(Duration(days: duration - 1));
        _dailyHours = hours;
        _isSuggestingAI = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Sugestão da IA: $reason'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSuggestingAI = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na IA: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startDate = widget.activePlan?.startDate ?? DateTime.now();
    _endDate = widget.activePlan?.endDate ??
        DateTime.now().add(const Duration(days: 29));
    _dailyHours = widget.activePlan?.dailyHours ?? 3.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final activeGoalId = ref.watch(activeGoalIdProvider);
    final planCtrl = ref.read(studyPlanControllerProvider.notifier);
    final planState = ref.watch(studyPlanControllerProvider);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.activePlan != null
                          ? 'Mudar Plano de Estudo'
                          : 'Novo Plano de Estudo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Defina como será a sua carga e período de estudos para gerarmos seu cronograma ideal.',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Date Range Selection
              Text(
                'Período do Cronograma',
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final initialRange =
                      DateTimeRange(start: _startDate, end: _endDate);
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: initialRange,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primary,
                                onPrimary: Colors.white,
                              ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (Theme.of(context).cardTheme.color ??
                        Theme.of(context).colorScheme.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppDateUtils.displayDate(_startDate)} — ${AppDateUtils.displayDate(_endDate)}',
                              style: TextStyle(
                                color: (Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.white),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${_endDate.difference(_startDate).inDays + 1} dias',
                              style: TextStyle(
                                color: (Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color ??
                                    Colors.grey),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded,
                          color:
                              (Theme.of(context).textTheme.labelSmall?.color ??
                                  Colors.grey),
                          size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Daily Hours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Carga Horária Diária',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_dailyHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primary,
                  inactiveTrackColor: AppTheme.primary.withOpacity(0.2),
                  thumbColor: AppTheme.primary,
                  overlayColor: AppTheme.primary.withOpacity(0.1),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _dailyHours,
                  min: 1,
                  max: 12,
                  divisions: 22,
                  onChanged: (v) => setState(() => _dailyHours = v),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sua Rotina (Opcional)',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isSuggestingAI
                        ? null
                        : () => _suggestConfigWithAI(context),
                    icon: _isSuggestingAI
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text('Sugerir com IA',
                        style: TextStyle(fontSize: 12)),
                    style:
                        TextButton.styleFrom(foregroundColor: AppTheme.accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routineController,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Ex: Trabalho das 8h às 18h. Posso estudar mais no FDS.',
                  hintStyle: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                  ),
                  filled: true,
                  fillColor: (Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: planState.isLoading || subjects.isEmpty
                      ? null
                      : () async {
                          if (user == null || activeGoalId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Erro: Crie um Objetivo primeiro.')),
                            );
                            return;
                          }

                          // Cria/atualiza plano
                          final plan = StudyPlan(
                            id: widget.activePlan?.id ?? '',
                            userId: user.uid,
                            goalId: activeGoalId,
                            startDate: _startDate,
                            durationDays:
                                _endDate.difference(_startDate).inDays + 1,
                            dailyHours: _dailyHours,
                          );

                          try {
                            await planCtrl.createPlanAndGenerate(
                              plan,
                              routineContext: _routineController.text,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('✨ Cronograma gerado com sucesso!'),
                                  backgroundColor: AppTheme.accent,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao gerar plano: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: planState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: Text(
                    subjects.isEmpty
                        ? 'Cadastre matérias primeiro'
                        : widget.activePlan != null
                            ? 'Regenerar Cronograma'
                            : 'Gerar Cronograma',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              if (subjects.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vá em "Matérias" para cadastrar as matérias antes de criar o plano.',
                          style: TextStyle(
                              color: (Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
