import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
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
  late int _selectedDuration;
  late double _dailyHours;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.activePlan?.durationDays ?? 30;
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
      backgroundColor: AppTheme.bg1,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Defina como será a sua carga e período de estudos para gerarmos seu cronograma ideal.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Duration
              const Text(
                'Duração do Cronograma',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppConstants.planDurations.map((d) {
                  final selected = _selectedDuration == d;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDuration = d),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary.withOpacity(0.1)
                                : AppTheme.bg2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  selected ? AppTheme.primary : AppTheme.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$d dias',
                              style: TextStyle(
                                color: selected
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Daily Hours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Carga Horária Diária',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
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
              const SizedBox(height: 32),

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
                            id: widget.activePlan?.id ??
                                '', // reUSA se ja tiver ID? O controller faz upsert ou apaga antigo.
                            userId: user.uid,
                            goalId: activeGoalId,
                            startDate: DateTime.now(),
                            durationDays: _selectedDuration,
                            dailyHours: _dailyHours,
                          );

                          try {
                            await planCtrl.createPlanAndGenerate(plan);
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
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.warning, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vá em "Matérias" para cadastrar as matérias antes de criar o plano.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
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
