import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../controllers/question_controller.dart';
import '../controllers/subject_controller.dart';

class QuestionFilterScreen extends ConsumerStatefulWidget {
  const QuestionFilterScreen({super.key});

  @override
  ConsumerState<QuestionFilterScreen> createState() =>
      _QuestionFilterScreenState();
}

class _QuestionFilterScreenState extends ConsumerState<QuestionFilterScreen> {
  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final filter = ref.watch(questionFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        title: const Text('Filtros de Treino',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background blobs for glassmorphism
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Matéria'),
                      const SizedBox(height: 12),
                      _buildSubjectSelector(subjects, filter),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Banca'),
                      const SizedBox(height: 12),
                      _buildBancaInput(filter),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ano Mínimo'),
                      const SizedBox(height: 12),
                      _buildAnoSlider(filter),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Quantidade de Questões'),
                      const SizedBox(height: 12),
                      _buildLimitSlider(filter),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _startTraining(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Treino',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubjectSelector(List<dynamic> subjects, QuestionFilter filter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: subjects.map((s) {
        final isSelected = filter.subjectId == s.id;
        final color =
            Color(int.parse('FF${s.color.replaceAll('#', '')}', radix: 16));

        return ChoiceChip(
          label: Text(s.name),
          selected: isSelected,
          onSelected: (val) {
            ref.read(questionFilterProvider.notifier).update(
                  (filterState) =>
                      filterState.copyWith(subjectId: val ? s.id : null),
                );
          },
          selectedColor: color.withValues(alpha: 0.2),
          side: BorderSide(color: isSelected ? color : AppTheme.border),
          backgroundColor: AppTheme.bg1,
          labelStyle: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBancaInput(QuestionFilter filter) {
    final bancas = ['CESGRANRIO', 'FGV', 'FCC', 'CEBRASPE'];
    return Wrap(
      spacing: 8,
      children: bancas.map((b) {
        final isSelected = filter.banca == b;
        return ChoiceChip(
          label: Text(b),
          selected: isSelected,
          onSelected: (val) {
            ref.read(questionFilterProvider.notifier).update(
                  (s) => s.copyWith(banca: val ? b : null),
                );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAnoSlider(QuestionFilter filter) {
    return Column(
      children: [
        Slider(
          value: (filter.ano ?? 2020).toDouble(),
          min: 2018,
          max: 2025,
          divisions: 7,
          label: filter.ano?.toString() ?? 'Todos',
          onChanged: (val) {
            ref.read(questionFilterProvider.notifier).update(
                  (s) => s.copyWith(ano: val.toInt()),
                );
          },
        ),
        Text('A partir de ${filter.ano ?? 2020}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildLimitSlider(QuestionFilter filter) {
    return Slider(
      value: filter.limit.toDouble(),
      min: 5,
      max: 50,
      divisions: 9,
      label: filter.limit.toString(),
      onChanged: (val) {
        ref.read(questionFilterProvider.notifier).update(
              (s) => s.copyWith(limit: val.toInt()),
            );
      },
    );
  }

  void _startTraining(BuildContext context) {
    // Navigate back or to questions list with current filters
    Navigator.pop(context);
    // The questionsProvider will automatically react to the filter update
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
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
