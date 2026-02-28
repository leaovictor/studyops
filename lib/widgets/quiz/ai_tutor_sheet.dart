import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyops/core/theme/app_theme.dart';
import 'package:studyops/controllers/auth_controller.dart';
import 'package:studyops/controllers/subject_controller.dart';
import 'package:studyops/services/ai_service.dart';

class AITutorSheet extends ConsumerStatefulWidget {
  final String questionStatement;
  final Map<String, String> options;
  final String correctAnswer;
  final Function(List<String>) onAlternativesEliminated;

  const AITutorSheet({
    super.key,
    required this.questionStatement,
    required this.options,
    required this.correctAnswer,
    required this.onAlternativesEliminated,
  });

  @override
  ConsumerState<AITutorSheet> createState() => _AITutorSheetState();
}

class _AITutorSheetState extends ConsumerState<AITutorSheet> {
  bool _isLoading = false;
  String? _content;

  Future<void> _handleAction(String mode) async {
    setState(() {
      _isLoading = true;
      _content = null;
    });

    try {
      final AIService? aiService = await ref.read(aiServiceProvider.future);
      final user = ref.read(authStateProvider).valueOrNull;

      if (aiService == null || user == null) return;

      if (mode == 'hint') {
        final hint = await aiService.getQuickHint(
          userId: user.uid,
          question: widget.questionStatement,
          options: widget.options.values.toList(),
        );
        setState(() => _content = hint);
      } else if (mode == 'concept') {
        final concept = await aiService.explainConcept(
          userId: user.uid,
          question: widget.questionStatement,
        );
        setState(() => _content = concept);
      } else if (mode == 'eliminate') {
        final eliminated = await aiService.eliminateAlternatives(
          userId: user.uid,
          question: widget.questionStatement,
          options: widget.options,
          correctAnswer: widget.correctAnswer,
        );
        widget.onAlternativesEliminated(eliminated);
        setState(() => _content =
            "Eliminei duas alternativas para você! Foco nas que sobraram.");
      }
    } catch (e) {
      setState(() => _content = "Erro ao contatar o tutor: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF151A2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tutor IA Contextual',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_content != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                _content!,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                _buildOption(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Me dê uma dica rápida',
                  subtitle: 'Um empurrãozinho para você pensar.',
                  onTap: () => _handleAction('hint'),
                ),
                const SizedBox(height: 12),
                _buildOption(
                  icon: Icons.psychology_outlined,
                  title: 'Explique o conceito',
                  subtitle: 'Entenda a teoria por trás da questão.',
                  onTap: () => _handleAction('concept'),
                ),
                const SizedBox(height: 12),
                _buildOption(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Eliminar 2 alternativas',
                  subtitle: 'Aumente suas chances de acerto.',
                  onTap: () => _handleAction('eliminate'),
                ),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
