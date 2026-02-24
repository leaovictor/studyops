import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/goal_controller.dart';
import '../models/goal_model.dart';
import '../core/theme/app_theme.dart';

class GoalSwitcher extends ConsumerWidget {
  final bool compact;

  const GoalSwitcher({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final activeGoalId = ref.watch(activeGoalIdProvider);
    // Explicitly watch the controller to ensure build() (migration) runs
    ref.watch(goalControllerProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          if (compact) {
            return IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.primary),
              onPressed: () => _showAddGoalDialog(context, ref),
              tooltip: 'Adicionar Objetivo',
            );
          }
          return _AddGoalButton(
            onTap: () => _showAddGoalDialog(context, ref),
          );
        }

        final activeGoal = goals.firstWhere(
          (g) => g.id == activeGoalId,
          orElse: () => goals.first,
        );

        if (compact) {
          return IconButton(
            icon: const Icon(Icons.flag_rounded),
            onPressed: () => _showGoalPicker(context, ref, goals),
            tooltip: 'Objetivo: ${activeGoal.name}',
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _showGoalPicker(context, ref, goals),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'AMBIENTE ATIVO',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            activeGoal.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _AddGoalButton(
              onTap: () => _showAddGoalDialog(context, ref),
            ),
          ],
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref, List<Goal> goals) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione seu Objetivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isSelected =
                          goal.id == ref.read(activeGoalIdProvider);
                      return ListTile(
                        leading: Icon(
                          Icons.flag_rounded,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        title: Text(
                          goal.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (goals.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppTheme.textMuted),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showDeleteConfirmationDialog(
                                      context, ref, goal);
                                },
                                tooltip: 'Excluir Ambiente',
                              ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primary),
                          ],
                        ),
                        onTap: () {
                          ref
                              .read(goalControllerProvider.notifier)
                              .setActiveGoal(goal.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.add_rounded, color: AppTheme.primary),
                  title: const Text('Novo Objetivo',
                      style: TextStyle(color: AppTheme.primary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddGoalDialog(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, Goal goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.bg1,
          title: const Text('Excluir Ambiente?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: 'Esta ação é irreversível. Todas as ',
                        style: TextStyle(fontSize: 13)),
                    TextSpan(
                        text: 'matérias e tarefas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    TextSpan(
                        text: ' deste ambiente serão perdidas.',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                'Digite "${goal.name}" para confirmar:',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: goal.name,
                  fillColor: AppTheme.bg0,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final isMatch = value.text == goal.name;
                return ElevatedButton(
                  onPressed: isMatch
                      ? () {
                          ref
                              .read(goalControllerProvider.notifier)
                              .deleteGoal(goal.id);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.error.withOpacity(0.2),
                  ),
                  child: const Text('Excluir Definitivamente'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Novo Ambiente de Estudo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crie um ambiente separado para organizar seus estudos (ex: ENEM, Faculdade, Concursos).',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Nome do ambiente (ex: Residência Médica)',
              ),
              autofocus: true,
            ),
          ],
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

class _AddGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGoalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Adicionar Estudo',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
