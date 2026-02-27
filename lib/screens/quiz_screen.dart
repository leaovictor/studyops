import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../controllers/question_bank_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/shared_question_model.dart';
import '../models/error_note_model.dart';
import '../core/theme/app_theme.dart';
import '../controllers/goal_controller.dart';
import '../controllers/subject_controller.dart' show aiServiceProvider;

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(sharedQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulado (Banco Global)'),
        elevation: 0,
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma questão encontrada.\\nTente enviar um PDF na aba Desempenho!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Only move on next/prev
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return _QuestionPage(
                question: question,
                questionIndex: index,
                totalQuestions: questions.length,
                onNext: () {
                  if (index < questions.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fim do Simulado! 🎉')),
                    );
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Erro: $e',
                style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

class _QuestionPage extends ConsumerStatefulWidget {
  final SharedQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final VoidCallback onNext;

  const _QuestionPage({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.onNext,
  });

  @override
  ConsumerState<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<_QuestionPage> {
  String? _selectedOption;
  bool _hasAnswered = false;
  bool _isCorrect = false;

  void _submitAnswer() {
    if (_selectedOption == null) return;

    setState(() {
      _hasAnswered = true;
      _isCorrect = _selectedOption == widget.question.correctAnswer;
    });

    if (!_isCorrect) {
      _saveToErrorNotebook();
    }
  }

  Future<void> _saveToErrorNotebook() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final activeGoalId = ref.read(activeGoalIdProvider);
    final errorCtrl = ref.read(errorNotebookControllerProvider.notifier);

    // Provide a dummy Subject/Topic if not mapped properly,
    // ideally the user would select this, but for the global bank we autogenerate for now.
    final note = ErrorNote(
      id: const Uuid().v4(),
      userId: user.uid,
      goalId: activeGoalId, // Can be null
      subjectId: 'GLOBAL_BANK', // Placeholder or match via subject name
      topicId: widget.question.subjectName ?? 'Tópico Geral',
      question: widget.question.statement,
      correctAnswer:
          'A resposta correta era: ${widget.question.correctAnswer} (${widget.question.options[widget.question.correctAnswer]}). Fonte: ${widget.question.source ?? "Banco Global"}',
      errorReason: 'Errei no simulado marcando a opção $_selectedOption.',
      nextReview: DateTime.now().add(const Duration(days: 1)),
      reviewStage: 0,
    );

    try {
      await errorCtrl.createNote(note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questão salva no Caderno de Erros! 📓'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar no caderno: $e");
    }
  }

  void _showAIExplanation() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Professor IA pensando...'),
          ],
        ),
      ),
    );

    try {
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception("IA não configurada.");

      final explanation = await aiService.explainQuestion(
        userId: user.uid,
        question: widget.question.statement +
            "\\nAlternativas:\\n" +
            widget.question.options.entries
                .map((e) => "${e.key}) ${e.value}")
                .join("\\n"),
        correctAnswer:
            "${widget.question.correctAnswer}) ${widget.question.options[widget.question.correctAnswer]}",
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Explicação IA'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(explanation, style: const TextStyle(fontSize: 14)),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendi')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Questão ${widget.questionIndex + 1} de ${widget.totalQuestions}',
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              if (widget.question.subjectName != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.question.subjectName!,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question.statement,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ...widget.question.options.entries.map((entry) {
                    final isSelected = _selectedOption == entry.key;
                    final isCorrectOption =
                        entry.key == widget.question.correctAnswer;

                    Color borderColor = Theme.of(context).dividerColor;
                    Color bgColor =
                        Theme.of(context).cardTheme.color ?? Colors.transparent;

                    if (_hasAnswered) {
                      if (isCorrectOption) {
                        borderColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.1);
                      } else if (isSelected && !isCorrectOption) {
                        borderColor = AppTheme.error;
                        bgColor = AppTheme.error.withValues(alpha: 0.1);
                      }
                    } else if (isSelected) {
                      borderColor = AppTheme.primary;
                      bgColor = AppTheme.primary.withValues(alpha: 0.1);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: _hasAnswered
                            ? null
                            : () => setState(() => _selectedOption = entry.key),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(
                                color: borderColor,
                                width: isSelected ||
                                        (_hasAnswered && isCorrectOption)
                                    ? 2
                                    : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _hasAnswered && isCorrectOption
                                      ? Colors.green
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(height: 1.4),
                                ),
                              ),
                              if (_hasAnswered && isCorrectOption)
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.green, size: 20)
                              else if (_hasAnswered &&
                                  isSelected &&
                                  !isCorrectOption)
                                const Icon(Icons.cancel_rounded,
                                    color: AppTheme.error, size: 20)
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          if (_hasAnswered) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAIExplanation,
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.primary),
                    label: const Text('Explicação IA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onNext,
                    child: const Text('Próxima'),
                  ),
                ),
              ],
            )
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _selectedOption == null ? null : _submitAnswer,
                child: const Text('Responder'),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
