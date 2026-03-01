import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../controllers/question_bank_controller.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/shared_question_model.dart';
import '../models/subject_model.dart';
import '../models/error_note_model.dart';
import '../core/theme/app_theme.dart';
import '../controllers/goal_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/performance_controller.dart';

// New Widgets
import '../widgets/quiz/quiz_top_bar.dart';
import '../widgets/quiz/quiz_progress_bar.dart';
import '../widgets/quiz/question_view.dart';
import '../widgets/quiz/ai_tutor_sheet.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _hits = 0;
  int _misses = 0;
  bool _isFocusMode = false;
  final Set<String> _flaggedForReview = {};
  double _fontSizeDelta = 0;

  // Timer state
  Duration? _timeLimit;
  Duration? _remainingTime;
  Timer? _countdownTimer;
  DateTime? _startTime;
  Duration? _totalTimeTaken;

  void _recordResult(bool isCorrect) {
    setState(() {
      if (isCorrect)
        _hits++;
      else
        _misses++;
    });
  }

  void _toggleFocusMode() {
    setState(() => _isFocusMode = !_isFocusMode);
  }

  void _toggleReviewFlag(String questionId) {
    setState(() {
      if (_flaggedForReview.contains(questionId)) {
        _flaggedForReview.remove(questionId);
      } else {
        _flaggedForReview.add(questionId);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Reset filters when starting a new quiz session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedQuizSubjectProvider.notifier).state = null;
      ref.read(selectedQuizTopicProvider.notifier).state = null;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimedExam(int minutes) {
    setState(() {
      _timeLimit = Duration(minutes: minutes);
      _remainingTime = _timeLimit;
      _startTime = DateTime.now();
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime!.inSeconds > 0) {
          _remainingTime = _remainingTime! - const Duration(seconds: 1);
        } else {
          timer.cancel();
          _handleTimeUp();
        }
      });
    });
  }

  void _handleTimeUp() {
    final questions = ref.read(sharedQuestionsProvider).valueOrNull ?? [];
    _showSummary(questions, isTimeUp: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sharedQuestionsProvider, (previous, next) {
      if (previous?.value != next.value) {
        setState(() {
          _currentIndex = 0;
          _hits = 0;
          _misses = 0;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    });

    final questionsAsync = ref.watch(sharedQuestionsProvider);

    return Material(
      color: const Color(0xFF0B1220),
      child: Column(
        children: [
          if (!_isFocusMode)
            QuizTopBar(
              title: _timeLimit != null
                  ? 'Simulado Cronometrado'
                  : 'Simulado Premium',
              fontSizeDelta: _fontSizeDelta,
              onFontSizeChanged: (val) => setState(() => _fontSizeDelta = val),
              remainingTime: _remainingTime,
              isTimedMode: _timeLimit != null,
              onExit: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma questão encontrada.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                // Show time limit selection if not set
                if (_timeLimit == null && _startTime == null) {
                  return _buildTimeSelection(context);
                }

                return Column(
                  children: [
                    if (!_isFocusMode) ...[
                      QuizProgressBar(
                        current: _currentIndex + 1,
                        total: questions.length,
                      ),
                    ],
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questions.length,
                        onPageChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _QuestionPage(
                            question: question,
                            questionIndex: index,
                            totalQuestions: questions.length,
                            onResult: _recordResult,
                            isFocusMode: _isFocusMode,
                            isFlagged: _flaggedForReview.contains(question.id),
                            onToggleReview: () =>
                                _toggleReviewFlag(question.id),
                            onToggleFocus: _toggleFocusMode,
                            fontSizeDelta: _fontSizeDelta,
                            onNext: () {
                              if (index < questions.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              } else {
                                _totalTimeTaken =
                                    DateTime.now().difference(_startTime!);
                                _showSummary(questions);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
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

  void _showSummary(List<SharedQuestion> questions, {bool isTimeUp = false}) {
    if (_countdownTimer != null) {
      _countdownTimer!.cancel();
    }

    // Calculate total time taken if not already set (e.g. from manual completion)
    if (_totalTimeTaken == null && _startTime != null) {
      _totalTimeTaken = DateTime.now().difference(_startTime!);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151A2C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _QuizSummarySheet(
        hits: _hits,
        misses: _misses,
        total: questions.length,
        flaggedCount: _flaggedForReview.length,
        totalTimeTaken: _totalTimeTaken ?? Duration.zero,
        isTimeUp: isTimeUp,
      ),
    );
  }

  Widget _buildTimeSelection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined,
                size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Modo de Simulado',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escolha como deseja realizar esta prova:',
            style: TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _TimeOption(
            title: 'Modo Livre',
            subtitle: 'Sem tempo limite. Foque no aprendizado.',
            icon: Icons.auto_awesome_rounded,
            color: Colors.cyan,
            onTap: () {
              setState(() {
                _startTime = DateTime.now();
                _timeLimit = null; // Ensure null for free mode
              });
            },
          ),
          const SizedBox(height: 16),
          _TimeOption(
            title: 'Simulado Real (15 min)',
            subtitle: 'Ideal para revisões rápidas.',
            icon: Icons.timer_rounded,
            color: Colors.orange,
            onTap: () => _startTimedExam(15),
          ),
          const SizedBox(height: 16),
          _TimeOption(
            title: 'Simulado Real (30 min)',
            subtitle: 'Para testar resistência média.',
            icon: Icons.timer_rounded,
            color: Colors.deepOrange,
            onTap: () => _startTimedExam(30),
          ),
          const SizedBox(height: 16),
          _TimeOption(
            title: 'Maratona (60 min)',
            subtitle: 'Experiência completa de concurso.',
            icon: Icons.hourglass_full_rounded,
            color: Colors.redAccent,
            onTap: () => _startTimedExam(60),
          ),
        ],
      ),
    );
  }
}

class _TimeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TimeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13)),
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

class _QuestionPage extends ConsumerStatefulWidget {
  final SharedQuestion question;
  final int questionIndex;
  final int totalQuestions;
  final Function(bool) onResult;
  final VoidCallback onNext;
  final bool isFocusMode;
  final bool isFlagged;
  final VoidCallback onToggleReview;
  final VoidCallback onToggleFocus;
  final double fontSizeDelta;

  const _QuestionPage({
    required this.question,
    required this.questionIndex,
    required this.totalQuestions,
    required this.onResult,
    required this.onNext,
    required this.isFocusMode,
    required this.isFlagged,
    required this.onToggleReview,
    required this.onToggleFocus,
    required this.fontSizeDelta,
  });

  @override
  ConsumerState<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends ConsumerState<_QuestionPage> {
  String? _selectedOption;
  bool _hasAnswered = false;
  bool _isCorrect = false;
  List<String> _eliminatedOptions = [];

  void _submitAnswer() {
    if (_selectedOption == null) return;

    setState(() {
      _hasAnswered = true;
      _isCorrect = _selectedOption == widget.question.correctAnswer;
    });

    widget.onResult(_isCorrect);

    _persistResult(_isCorrect);

    if (!_isCorrect) {
      _saveToErrorNotebook();
    }
  }

  Future<void> _persistResult(bool isCorrect) async {
    final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
    String subjectId = 'SIMULADO_GERAL'; // Default fallback

    if (widget.question.subjectName != null) {
      final match = subjects.firstWhere(
        (s) =>
            s.name.toLowerCase() == widget.question.subjectName!.toLowerCase(),
        orElse: () => subjects.firstWhere((s) => s.name == 'Geral',
            orElse: () => subjects.isNotEmpty
                ? subjects.first
                : Subject(
                    id: 'temp',
                    userId: '',
                    name: 'Geral',
                    color: '',
                    priority: 0,
                    weight: 0,
                    difficulty: 0)),
      );

      if (match.id != 'temp') {
        subjectId = match.id;
      }
    }

    try {
      await ref.read(questionControllerProvider.notifier).addLog(
            subjectId: subjectId,
            total: 1,
            correct: isCorrect ? 1 : 0,
          );
    } catch (e) {
      debugPrint('Erro ao persistir log de questão: $e');
    }
  }

  void _toggleElimination(String optionKey) {
    if (_hasAnswered) return;
    setState(() {
      if (_eliminatedOptions.contains(optionKey)) {
        _eliminatedOptions.remove(optionKey);
      } else {
        _eliminatedOptions.add(optionKey);
        if (_selectedOption == optionKey) {
          _selectedOption = null;
        }
      }
    });
  }

  Future<void> _saveToErrorNotebook() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final activeGoalId = ref.read(activeGoalIdProvider);
    final errorCtrl = ref.read(errorNotebookControllerProvider.notifier);

    final note = ErrorNote(
      id: const Uuid().v4(),
      userId: user.uid,
      goalId: activeGoalId,
      subjectId: 'GLOBAL_BANK',
      topicId: widget.question.subjectName ?? 'Tópico Geral',
      question: widget.question.statement,
      correctAnswer:
          'Correta: ${widget.question.correctAnswer}. ${widget.question.options[widget.question.correctAnswer]}',
      errorReason: 'Errei no simulado.',
      nextReview: DateTime.now().add(const Duration(days: 1)),
      reviewStage: 0,
    );

    await errorCtrl.createNote(note);
  }

  void _openAITutor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AITutorSheet(
        questionStatement: widget.question.statement,
        options: widget.question.options,
        correctAnswer: widget.question.correctAnswer,
        onAlternativesEliminated: (eliminated) {
          setState(() => _eliminatedOptions = eliminated);
        },
      ),
    );
  }

  void _showFullExplanation() async {
    final aiService = await ref.read(aiServiceProvider.future);
    final user = ref.read(authStateProvider).valueOrNull;

    if (aiService == null || user == null) return;

    showDialog(
      context: context,
      builder: (context) => FutureBuilder<String>(
          future: aiService.getDetailedExplanation(
            userId: user.uid,
            question: widget.question.statement,
            correctAnswer: widget.question.correctAnswer,
          ),
          builder: (context, snapshot) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151A2C),
              title: const Text('Explicação do Professor IA',
                  style: TextStyle(color: Colors.white)),
              content: snapshot.hasData
                  ? SingleChildScrollView(
                      child: Text(snapshot.data!,
                          style: const TextStyle(color: Colors.white)))
                  : const Center(child: CircularProgressIndicator()),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendi')),
              ],
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: QuestionView(
            question: widget.question,
            selectedOption: _selectedOption,
            hasAnswered: _hasAnswered,
            eliminatedOptions: _eliminatedOptions,
            onOptionSelected: (val) => setState(() => _selectedOption = val),
            onToggleElimination: _toggleElimination,
            fontSizeDelta: widget.fontSizeDelta,
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_hasAnswered) ...[
              Row(
                children: [
                  _IconButton(
                    icon: widget.isFlagged
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.isFlagged ? Colors.orange : Colors.white38,
                    onTap: widget.onToggleReview,
                  ),
                  const SizedBox(width: 12),
                  _IconButton(
                    icon: widget.isFocusMode
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    color: Colors.white38,
                    onTap: widget.onToggleFocus,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedOption == null ? null : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('RESPONDER',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openAITutor,
                  icon: const Icon(Icons.psychology_outlined, size: 20),
                  label: const Text('PEDIR DICA AO TUTOR IA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFullExplanation,
                      icon: const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: AppTheme.primary),
                      label: const Text('VER EXPLICAÇÃO'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('PRÓXIMA',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _QuizSummarySheet extends StatelessWidget {
  final int hits;
  final int misses;
  final int total;
  final int flaggedCount;
  final Duration totalTimeTaken;
  final bool isTimeUp;

  const _QuizSummarySheet({
    required this.hits,
    required this.misses,
    required this.total,
    required this.flaggedCount,
    required this.totalTimeTaken,
    required this.isTimeUp,
  });

  @override
  Widget build(BuildContext context) {
    double accuracy = total > 0 ? (hits / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isTimeUp ? 'Tempo Esgotado!' : 'Simulado Concluído!',
            style: TextStyle(
              color: isTimeUp ? Colors.redAccent : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                label: 'Acertos',
                value: '$hits',
                color: const Color(0xFF4ADE80),
              ),
              _SummaryItem(
                label: 'Erros',
                value: '$misses',
                color: const Color(0xFFFB7185),
              ),
              _SummaryItem(
                label: 'Precisão',
                value: '${accuracy.toStringAsFixed(0)}%',
                color: const Color(0xFF00A3FF),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                label: 'Tempo Total',
                value: _formatDuration(totalTimeTaken),
                color: Colors.white70,
              ),
              _SummaryItem(
                label: 'Média/Questão',
                value: _formatDuration(Duration(
                    seconds: total > 0
                        ? (totalTimeTaken.inSeconds / total).round()
                        : 0)),
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (isTimeUp) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_off_rounded, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O ciclo foi encerrado automaticamente pelo cronômetro.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (flaggedCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    'Você marcou $flaggedCount questões para revisão.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'VOLTAR AO INÍCIO',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
