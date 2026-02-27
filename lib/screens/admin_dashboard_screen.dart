import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/admin_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/shared_question_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(adminControllerProvider.notifier).isAdmin;

    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('Acesso negado')));
    }

    final pendingAsync = ref.watch(pendingQuestionsProvider);
    final totalAI = ref.watch(totalAICallsProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Painel Administrativo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        title: 'Chamadas de IA (Total)',
                        value: totalAI.toString())),
              ],
            ),
            const SizedBox(height: 32),
            const _GroqConfigCard(),
            const SizedBox(height: 32),
            Text('Questões para Moderação',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white))),
            const SizedBox(height: 16),
            pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (questions) {
                final pending = questions.where((q) => !q.isApproved).toList();
                if (pending.isEmpty)
                  return const Center(child: Text('Nenhuma questão pendente.'));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) => _ModerationCard(question: pending[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroqConfigCard extends ConsumerStatefulWidget {
  const _GroqConfigCard();

  @override
  ConsumerState<_GroqConfigCard> createState() => _GroqConfigCardState();
}

class _GroqConfigCardState extends ConsumerState<_GroqConfigCard> {
  final _keyCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing key if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentKey = ref.read(groqApiKeyProvider).valueOrNull;
      if (currentKey != null) _keyCtrl.text = currentKey;
    });
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also listen for changes to update text field if needed
    ref.listen(groqApiKeyProvider, (prev, next) {
      if (next.hasValue && next.value != null && _keyCtrl.text.isEmpty) {
        _keyCtrl.text = next.value!;
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppTheme.accent, size: 20),
              SizedBox(width: 8),
              Text('Configuração Groq API (Llama 3.3)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Esta chave é usada para todas as funcionalidades de IA do app via Groq Cloud.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyCtrl,
            decoration: const InputDecoration(
              labelText: 'Groq API Key',
              hintText: 'gsk_...',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar Chave Groq'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(adminControllerProvider.notifier)
          .saveGroqApiKey(_keyCtrl.text.trim());
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chave Groq salva com sucesso!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _ModerationCard extends ConsumerWidget {
  final SharedQuestion question;
  const _ModerationCard({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.subjectName ?? 'Sem matéria',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.accent)),
          const SizedBox(height: 8),
          Text(question.statement,
              maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(adminControllerProvider.notifier)
                    .approveQuestion(question.id),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Aprovar'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => ref
                    .read(adminControllerProvider.notifier)
                    .rejectQuestion(question.id),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Rejeitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
