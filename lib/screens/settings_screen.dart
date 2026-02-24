import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/pomodoro_settings_controller.dart';
import '../controllers/goal_controller.dart';
import '../models/study_plan_model.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedDuration = 30;
  double _dailyHours = 3.0;
  String? _loadedPlanId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final activePlan = ref.watch(activePlanProvider).valueOrNull;
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final activeGoalId = ref.watch(activeGoalIdProvider);
    final planCtrl = ref.read(studyPlanControllerProvider.notifier);
    final planState = ref.watch(studyPlanControllerProvider);

    // Only update local state if a DIFFERENT plan is loaded
    if (activePlan != null && activePlan.id != _loadedPlanId) {
      _selectedDuration = activePlan.durationDays;
      _dailyHours = activePlan.dailyHours;
      _loadedPlanId = activePlan.id;
    }

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Account section
              const _SectionHeader(title: 'Conta'),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        user?.displayName ?? 'Usuário',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded,
                          color: AppTheme.error),
                      title: const Text('Sair da conta',
                          style: TextStyle(color: AppTheme.error)),
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Study plan section
              const _SectionHeader(title: 'Plano de Estudo'),
              if (activePlan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.accent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Plano ativo: ${activePlan.durationDays} dias • ${activePlan.dailyHours}h/dia',
                          style: const TextStyle(
                              color: AppTheme.accent, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              _SettingsCard(
                child: StatefulBuilder(builder: (ctx, setS) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration
                      const Text(
                        'Duração do plano',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.planDurations.map((d) {
                          final selected = _selectedDuration == d;
                          return ChoiceChip(
                            label: Text('$d dias'),
                            selected: selected,
                            onSelected: (_) =>
                                setS(() => _selectedDuration = d),
                            selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Daily hours
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Horas de estudo por dia',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          Text(
                            '${_dailyHours.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _dailyHours,
                        min: 1,
                        max: 12,
                        divisions: 22,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setS(() => _dailyHours = v),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: planState.isLoading || subjects.isEmpty
                              ? null
                              : () async {
                                  if (user == null || activeGoalId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Erro: Crie um Objetivo primeiro.')),
                                    );
                                    return;
                                  }
                                  final plan = StudyPlan(
                                    id: '',
                                    userId: user.uid,
                                    goalId: activeGoalId,
                                    startDate: DateTime.now(),
                                    durationDays: _selectedDuration,
                                    dailyHours: _dailyHours,
                                  );
                                  await planCtrl.createPlanAndGenerate(plan);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '✅ Cronograma gerado com sucesso!'),
                                      ),
                                    );
                                  }
                                },
                          icon: planState.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.auto_awesome_rounded,
                                  size: 16),
                          label: Text(
                            subjects.isEmpty
                                ? 'Cadastre matérias primeiro'
                                : activePlan != null
                                    ? 'Regenerar Cronograma'
                                    : 'Criar Plano de Estudo',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (subjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Vá em Matérias para cadastrar as matérias e tópicos antes de criar o plano.',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Pomodoro section
              const _SectionHeader(title: 'Pomodoro'),
              Consumer(builder: (context, ref, _) {
                final settingsAsync = ref.watch(pomodoroSettingsProvider);
                final settings = settingsAsync.valueOrNull;

                if (settingsAsync.hasError) {
                  return const _SettingsCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Erro ao carregar configurações',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ),
                  );
                }

                if (settings == null) {
                  return const _SettingsCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                return _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.timer_rounded,
                            color: AppTheme.primary),
                        title: const Text('Duração do foco',
                            style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${settings.workMinutes} min',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.workMinutes.toDouble(),
                            min: 5,
                            max: 90,
                            divisions: 17,
                            activeColor: AppTheme.primary,
                            onChanged: (v) => ref
                                .read(pomodoroSettingsProvider.notifier)
                                .updateSettings(
                                    v.toInt(), settings.breakMinutes),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.coffee_rounded,
                            color: AppTheme.accent),
                        title: const Text('Pausa curta',
                            style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${settings.breakMinutes} min',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.breakMinutes.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            activeColor: AppTheme.accent,
                            onChanged: (v) => ref
                                .read(pomodoroSettingsProvider.notifier)
                                .updateSettings(
                                    settings.workMinutes, v.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
