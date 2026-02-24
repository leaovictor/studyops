import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../controllers/question_controller.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';

class QuestionPracticeScreen extends ConsumerStatefulWidget {
  final List<Question> questions;

  const QuestionPracticeScreen({super.key, required this.questions});

  @override
  ConsumerState<QuestionPracticeScreen> createState() =>
      _QuestionPracticeScreenState();
}

class _QuestionPracticeScreenState
    extends ConsumerState<QuestionPracticeScreen> {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _hasAnswered = false;
  int _correctAnswers = 0;
  bool _isFinished = false;

  void _handleOptionSelect(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      if (index == widget.questions[_currentIndex].correctOptionIndex) {
        _correctAnswers++;
      } else {
        // Automatically register wrong answer in Error Notebook
        _registerError();
      }
    });
  }

  Future<void> _registerError() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final question = widget.questions[_currentIndex];
    await ref.read(questionServiceProvider).registerWrongAnswer(
          userId: user.uid,
          question: question,
          givenAnswerText: question.options[_selectedOption!],
        );
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildSummary();
    if (widget.questions.isEmpty) return _buildEmpty();

    final question = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        title: Text('Questão ${_currentIndex + 1}/${widget.questions.length}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Acertos: $_correctAnswers',
                  style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Visual Blobs
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildTag(question.banca),
                                  const SizedBox(width: 8),
                                  _buildTag(question.ano.toString()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                question.text,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(question.options.length, (i) {
                          return _OptionTile(
                            text: question.options[i],
                            index: i,
                            isSelected: _selectedOption == i,
                            isCorrect: question.correctOptionIndex == i,
                            showFeedback: _hasAnswered,
                            onTap: () => _handleOptionSelect(i),
                          );
                        }),
                        if (_hasAnswered) ...[
                          const SizedBox(height: 24),
                          _GlassCard(
                            color: AppTheme.bg2.withValues(alpha: 0.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline,
                                        color: AppTheme.accent, size: 20),
                                    SizedBox(width: 8),
                                    Text('Explicação',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.accent)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question.explanation.isNotEmpty
                                      ? question.explanation
                                      : 'Sem explicação disponível para esta questão.',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_hasAnswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _currentIndex < widget.questions.length - 1
                              ? 'Próxima Questão'
                              : 'Ver Resultado',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSummary() {
    final perc = (widget.questions.isEmpty)
        ? 0
        : (_correctAnswers / widget.questions.length * 100).toInt();

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 80, color: AppTheme.accent),
              const SizedBox(height: 24),
              const Text('Treino Finalizado!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _GlassCard(
                child: Column(
                  children: [
                    Text('$perc%',
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent)),
                    const Text('Aproveitamento',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryStat(
                            label: 'Total',
                            value: widget.questions.length.toString()),
                        _SummaryStat(
                            label: 'Acertos',
                            value: _correctAnswers.toString(),
                            color: Colors.green),
                        _SummaryStat(
                            label: 'Erros',
                            value: (widget.questions.length - _correctAnswers)
                                .toString(),
                            color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Voltar ao Banco',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: const Center(
          child: Text('Nenhuma questão encontrada com estes filtros.')),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.border;
    Color bgColor = Colors.transparent;
    IconData? icon;

    if (showFeedback) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        icon = Icons.check_circle;
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        icon = Icons.cancel;
      }
    } else if (isSelected) {
      borderColor = AppTheme.primary;
      bgColor = AppTheme.primary.withValues(alpha: 0.05);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: borderColor,
              width: isSelected || (showFeedback && isCorrect) ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
                color: isSelected ? borderColor : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: showFeedback && isCorrect
                      ? Colors.green
                      : AppTheme.textPrimary,
                  fontWeight: isSelected || (showFeedback && isCorrect)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (icon != null) Icon(icon, color: borderColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _GlassCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
