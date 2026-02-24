import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/question_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/subject_model.dart';
import '../widgets/question_form_modal.dart';
import '../core/theme/app_theme.dart';

class QuestionBankScreen extends ConsumerWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final questionsAsync = ref.watch(questionsProvider);
    final selectedSubjectId = ref.watch(selectedQuestionSubjectIdProvider);

    final subjects = subjectsAsync.valueOrNull ?? [];
    final activeSubjectId =
        selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (activeSubjectId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cadastre matérias primeiro.')),
            );
            return;
          }
          final subject = subjects.firstWhere((s) => s.id == activeSubjectId);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => QuestionFormModal(
              subjectId: subject.id,
              goalId: ref.read(activeGoalIdProvider),
              onSave: (question) {
                final user = ref.read(authStateProvider).valueOrNull;
                if (user != null) {
                  ref.read(questionServiceProvider).saveQuestion(
                        question.copyWith(ownerId: user.uid),
                      );
                }
              },
            ),
          ).then((_) {
            // Refresh questions after modal closes
            ref.invalidate(questionsProvider);
          });
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Questão'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Banco de Questões',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Gerencie simulados e exercícios',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (subjects.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeSubjectId,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary),
                        dropdownColor: AppTheme.bg2,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        items: subjects.map((Subject s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.name),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ref
                                .read(
                                    selectedQuestionSubjectIdProvider.notifier)
                                .state = newValue;
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // List
            Expanded(
              child: questionsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (questions) {
                  if (questions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.source_outlined,
                              color: AppTheme.textMuted, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma questão encontrada',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Adicione novas questões para praticar\nou crie simulados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.separated(
                      itemCount: questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final question = questions[i];
                        final activeSubject = subjects.firstWhere(
                            (s) => s.id == question.subjectId,
                            orElse: () => const Subject(
                                id: '',
                                userId: '',
                                name: '',
                                color: '',
                                priority: 1,
                                weight: 1,
                                difficulty: 3));

                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.bg2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            activeSubject.name.isNotEmpty
                                                ? activeSubject.name
                                                : 'Matéria',
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Dificuldade: ${question.difficulty}',
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12),
                                        ),
                                        const Spacer(),
                                        if (question.tags.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            children: question.tags.map((tag) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.bg0,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: AppTheme.border),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: const TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      question.text,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (question.options.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(
                                          question.options.length,
                                          (idx) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  idx ==
                                                          question
                                                              .correctOptionIndex
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: idx ==
                                                          question
                                                              .correctOptionIndex
                                                      ? AppTheme.accent
                                                      : AppTheme.textMuted,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    question.options[idx],
                                                    style: TextStyle(
                                                      color: idx ==
                                                              question
                                                                  .correctOptionIndex
                                                          ? AppTheme.textPrimary
                                                          : AppTheme
                                                              .textSecondary,
                                                      fontSize: 13,
                                                      fontWeight: idx ==
                                                              question
                                                                  .correctOptionIndex
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
