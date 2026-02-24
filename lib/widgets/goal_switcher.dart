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

        return InkWell(
          onTap: () => _showGoalPicker(context, ref, goals),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Objetivo Ativo',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        activeGoal.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.unfold_more_rounded,
                    color: AppTheme.textSecondary, size: 18),
              ],
            ),
          ),
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
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppTheme.primary)
                            : null,
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

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Novo Objetivo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Medicina 2026, Concurso...',
          ),
          autofocus: true,
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
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
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
