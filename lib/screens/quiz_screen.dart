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
import '../controllers/subject_controller.dart';
import '../controllers/flashcard_controller.dart';
import '../models/flashcard_model.dart';
import 'package:fsrs/fsrs.dart' as fsrs_pkg;
// AI professor logic uses aiServiceProvider internally

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final PageController _pageController = PageController();
  int _hits = 0;
  int _misses = 0;

  void _recordResult(bool isCorrect) {
    setState(() {
      if (isCorrect)
        _hits++;
      else
        _misses++;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(sharedQuestionsProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final selectedSubject = ref.watch(selectedQuizSubjectProvider);
    final selectedTopic = ref.watch(selectedQuizTopicProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulado (Banco Global)'),
        elevation: 0,
        actions: [
          if (_hits + _misses > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  'Precisão: ${((_hits / (_hits + _misses)) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.accent),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedSubject,
                          hint: const Text("Filtrar Matéria",
                              style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text("Todas as Matérias",
                                    style: TextStyle(fontSize: 13))),
                            ...subjects.map((s) => DropdownMenuItem(
                                value: s.name,
                                child: Text(s.name,
                                    style: TextStyle(fontSize: 13)))),
                          ],
                          onChanged: (val) {
                            ref
                                .read(selectedQuizSubjectProvider.notifier)
                                .state = val;
                            ref.read(selectedQuizTopicProvider.notifier).state =
                                null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: ref.watch(availableQuizTopicsProvider).when(
                              data: (topics) => DropdownButton<String>(
                                isExpanded: true,
                                value: (selectedTopic != null &&
                                        topics.contains(selectedTopic))
                                    ? selectedTopic
                                    : null,
                                hint: const Text("Filtrar Tópico",
                                    style: TextStyle(fontSize: 13)),
                                items: [
                                  const DropdownMenuItem(
                                      value: null,
                                      child: Text("Todos os Tópicos",
                                          style: TextStyle(fontSize: 13))),
                                  ...topics.map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t,
                                          style: TextStyle(fontSize: 13)))),
                                ],
                                onChanged: (val) => ref
                                    .read(selectedQuizTopicProvider.notifier)
                                    .state = val,
                              ),
                              loading: () => const Center(
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              error: (_, __) => const Text("Erro"),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Session Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        label: 'Acertos', value: '$_hits', color: Colors.green),
                    _StatItem(
                        label: 'Erros', value: '$_misses', color: Colors.red),
                    _StatItem(
                        label: 'Total',
                        value: '${_hits + _misses}',
                        color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma questão encontrada.\nTente usar os botões na aba Desempenho!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return _QuestionPage(
                      question: question,
                      questionIndex: index,
                      totalQuestions: questions.length,
                      onResult: _recordResult,
                      onNext: () {
                        if (index < questions.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Fim do Simulado! 🎉')),
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
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _QuestionPage extends ConsumerStatefulWidget {
  final SharedQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final Function(bool) onResult;
  final VoidCallback onNext;

  const _QuestionPage({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.onResult,
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

    widget.onResult(_isCorrect);

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

    // Show loading dialog and store its navigator state
    bool dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Professor IA pensando...')),
          ],
        ),
      ),
    ).then((_) => dialogShowing = false);

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
        // Safe pop of loading dialog
        if (dialogShowing) {
          Navigator.of(context, rootNavigator: true).pop();
        }

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
        if (dialogShowing) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
      }
    }
  }

  void _createFlashcard() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoadingFlashcard = true);
    try {
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception("IA não configurada.");

      final flashcardData = await aiService.generateFlashcardFromQuestion(
        question: widget.question.statement,
        answer: widget.question.options[widget.question.correctAnswer] ?? "",
      );

      // Attempt to find the real subject ID from user's subjects
      final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
      String subjectId = 'GLOBAL_BANK';

      if (widget.question.subjectName != null &&
          widget.question.subjectName!.isNotEmpty) {
        try {
          final matchedSubject = subjects.firstWhere(
            (s) =>
                s.name.toLowerCase() ==
                widget.question.subjectName!.toLowerCase(),
          );
          subjectId = matchedSubject.id;
        } catch (_) {
          // If no match by name, and we have a selected subject in the filter, use that as a bias
          final selectedSubject = ref.read(selectedQuizSubjectProvider);
          if (selectedSubject != null) {
            subjectId = selectedSubject;
          }
        }
      }

      final flashcard = Flashcard(
        id: const Uuid().v4(),
        userId: user.uid,
        goalId: ref.read(activeGoalIdProvider),
        subjectId: subjectId,
        topicId:
            widget.question.topicName ?? widget.question.subjectName ?? 'Geral',
        front: flashcardData['front'] ?? widget.question.statement,
        back: flashcardData['back'] ??
            widget.question.options[widget.question.correctAnswer]!,
        fsrsCard: fsrs_pkg.Card(cardId: 1).toMap(),
        due: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(flashcardControllerProvider.notifier).create(flashcard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flashcard criado com sucesso! 🗂️')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar flashcard: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingFlashcard = false);
    }
  }

  bool _isLoadingFlashcard = false;

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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: OutlinedButton.icon(
                    onPressed: _showAIExplanation,
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.primary, size: 18),
                    label: const Text('Explicação IA',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingFlashcard ? null : _createFlashcard,
                    icon: _isLoadingFlashcard
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.style_rounded,
                            color: Colors.orange, size: 18),
                    label: const Text('Criar Flashcard',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onNext,
                    child: const Text('Próxima Questão'),
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
