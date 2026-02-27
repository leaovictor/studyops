import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                  color: (Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                        color: AppTheme.primary.withValues(alpha: 0.1),
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
                          Text(
                            'AMBIENTE ATIVO',
                            style: TextStyle(
                              color: (Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  Colors.grey),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            activeGoal.name,
                            style: TextStyle(
                              color: (Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
                                  Colors.white),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more_rounded,
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                        size: 20),
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
      error: (e, st) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref, List<Goal> goals) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                Text(
                  'Selecione seu Objetivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
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
                              : (Theme.of(context).textTheme.bodySmall?.color ??
                                  Colors.grey),
                        ),
                        title: Text(
                          goal.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : (Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color ??
                                    Colors.white),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (goals.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    size: 20,
                                    color: (Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.color ??
                                        Colors.grey)),
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
                          context.go('/subjects');
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Excluir Ambiente?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                const TextSpan(
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
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey)),
              ),
              const SizedBox(height: 20),
              Text(
                'Digite "${goal.name}" para confirmar:',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: goal.name,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
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
                    disabledBackgroundColor:
                        AppTheme.error.withValues(alpha: 0.2),
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
    bool useAI = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 24),
              const SizedBox(width: 12),
              const Text('Novo Ambiente'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organize seus estudos em ambientes separados (ex: OAB, Residência, Concursos).',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nome do objetivo',
                  hintText: 'Ex: Concurso Auditor Fiscal',
                  prefixIcon: Icon(Icons.flag_rounded),
                ),
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              // AI Toggle
              InkWell(
                onTap: () => setState(() => useAI = !useAI),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: useAI
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: useAI
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        useAI
                            ? Icons.auto_awesome_rounded
                            : Icons.auto_awesome_outlined,
                        color: useAI ? AppTheme.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuração Inteligente',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: useAI ? AppTheme.primary : Colors.grey,
                              ),
                            ),
                            Text(
                              'Sugerir matérias e pesos automaticamente.',
                              style: TextStyle(
                                fontSize: 11,
                                color: useAI ? AppTheme.primary : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: useAI,
                        onChanged: (v) => setState(() => useAI = v),
                        activeThumbColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      final goal = await ref
                          .read(goalControllerProvider.notifier)
                          .createGoal(name);

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (useAI) {
                          // Se usar IA, leva para a tela de matérias com o prompt de sugestão
                          context.go('/subjects');
                          // Opcional: Mostrar uma dica de que a IA pode ser usada lá
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Clique no ícone ✨ para gerar as matérias!'),
                              backgroundColor: AppTheme.primary,
                            ),
                          );
                        } else {
                          context.go('/subjects');
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Criar Ambiente'),
            ),
          ],
        ),
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
