import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../controllers/subject_controller.dart';
import '../core/theme/app_theme.dart';

class RelevanceTooltip extends ConsumerStatefulWidget {
  final Subject subject;

  const RelevanceTooltip({
    super.key,
    required this.subject,
  });

  @override
  ConsumerState<RelevanceTooltip> createState() => _RelevanceTooltipState();
}

class _RelevanceTooltipState extends ConsumerState<RelevanceTooltip> {
  late int _priority;
  late int _difficulty;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _priority = widget.subject.priority;
    _difficulty = widget.subject.difficulty;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        final updated = widget.subject.copyWith(
          priority: _priority,
          difficulty: _difficulty,
        );
        ref.read(subjectControllerProvider.notifier).updateSubject(updated);
      }
    });
    HapticFeedback.lightImpact();
    setState(() {});
  }

  double get score =>
      _priority * widget.subject.weight * _difficulty.toDouble();

  Color get scoreColor {
    if (score > 100) return const Color(0xFFBC13FE); // Neon Purple
    if (score >= 50) return const Color(0xFF00FFFF); // Cyan
    return const Color(0xFF10B981); // Emerald/Green
  }

  String get legend {
    if (score > 100) return 'Foco Crítico 🚨';
    if (score >= 50) return 'Estudo Recomendado 📚';
    return 'Manutenção ✅';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Relevância',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _ScoreBadge(score: score, color: scoreColor),
                ],
              ),
              const SizedBox(height: 16),

              // Priority Selector
              _SelectorRow(
                label: 'Prioridade',
                value: _priority,
                max: 5,
                onChanged: (v) {
                  _priority = v;
                  _onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Difficulty Selector
              _SelectorRow(
                label: 'Dificuldade',
                value: _difficulty,
                max: 5,
                onChanged: (v) {
                  _difficulty = v;
                  _onChanged();
                },
              ),

              Divider(color: Theme.of(context).dividerColor, height: 32),

              Center(
                child: Text(
                  legend,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                          color: scoreColor.withValues(alpha: 0.5),
                          blurRadius: 10)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          );
        },
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _SelectorRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), fontSize: 11),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(max, (index) {
            final active = (index + 1) <= value;
            return GestureDetector(
              onTap: () => onChanged(index + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? AppTheme.primary : Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white) : (Theme.of(context).textTheme.labelSmall?.color ?? Colors.grey),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}