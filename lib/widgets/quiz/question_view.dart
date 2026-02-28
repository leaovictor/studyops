import 'package:flutter/material.dart';
import '../../models/shared_question_model.dart';
import '../../core/theme/app_theme.dart';

class QuestionView extends StatelessWidget {
  final SharedQuestion question;
  final String? selectedOption;
  final bool hasAnswered;
  final Function(String) onOptionSelected;
  final List<String> eliminatedOptions;
  final double fontSizeDelta;

  const QuestionView({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.hasAnswered,
    required this.onOptionSelected,
    this.eliminatedOptions = const [],
    this.fontSizeDelta = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          if (question.subjectName != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                  question.subjectName!.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            question.statement,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 + fontSizeDelta,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          ...question.options.entries.map((entry) {
            final optionKey = entry.key;
            final optionValue = entry.value;
            final isSelected = selectedOption == optionKey;
            final isCorrect = optionKey == question.correctAnswer;
            final isEliminated = eliminatedOptions.contains(optionKey);

            Color borderColor = Colors.white.withOpacity(0.1);
            Color bgColor = const Color(0xFF151A2C);
            Color textColor = Colors.white.withOpacity(0.9);

            if (hasAnswered) {
              if (isCorrect) {
                borderColor = const Color(0xFF4ADE80);
                bgColor = const Color(0xFF4ADE80).withOpacity(0.1);
              } else if (isSelected) {
                borderColor = const Color(0xFFFB7185);
                bgColor = const Color(0xFFFB7185).withOpacity(0.1);
              }
            } else if (isEliminated) {
              textColor = Colors.white.withOpacity(0.2);
              bgColor = bgColor.withOpacity(0.5);
            } else if (isSelected) {
              borderColor = const Color(0xFF00A3FF);
              bgColor = const Color(0xFF00A3FF).withOpacity(0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: isEliminated && !hasAnswered ? 0.3 : 1.0,
                child: InkWell(
                  onTap: (hasAnswered || isEliminated)
                      ? null
                      : () => onOptionSelected(optionKey),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || (hasAnswered && isCorrect) ? 2 : 1,
                      ),
                      boxShadow: isSelected && !hasAnswered
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00A3FF).withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected || (hasAnswered && isCorrect)
                                ? (hasAnswered
                                    ? (isCorrect
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFFB7185))
                                    : const Color(0xFF00A3FF))
                                : Colors.white.withOpacity(0.05),
                          ),
                          child: Center(
                            child: Text(
                              optionKey,
                              style: TextStyle(
                                color: isSelected || (hasAnswered && isCorrect)
                                    ? Colors.white
                                    : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 14 + fontSizeDelta * 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            optionValue,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15 + fontSizeDelta,
                              height: 1.4,
                              decoration: isEliminated && !hasAnswered
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (hasAnswered && isCorrect)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4ADE80), size: 22)
                        else if (hasAnswered && isSelected && !isCorrect)
                          const Icon(Icons.cancel_rounded,
                              color: Color(0xFFFB7185), size: 22)
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
