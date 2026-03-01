import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/question_bank_controller.dart';
import '../../controllers/subject_controller.dart';

class QuizTopBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onExit;
  final double fontSizeDelta;
  final Function(double) onFontSizeChanged;
  final Duration? remainingTime;
  final bool isTimedMode;

  const QuizTopBar({
    super.key,
    required this.title,
    required this.onExit,
    required this.fontSizeDelta,
    required this.onFontSizeChanged,
    this.remainingTime,
    this.isTimedMode = false,
  });

  @override
  ConsumerState<QuizTopBar> createState() => _QuizTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _QuizTopBarState extends ConsumerState<QuizTopBar> {
  late Stopwatch _stopwatch;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const _FilterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B1220),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white70),
        onPressed: widget.onExit,
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // Filter button
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: AppTheme.primary),
          onPressed: _showFilterDialog,
          tooltip: 'Filtrar Questões',
        ),
        // Font size controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FontSizeButton(
              label: 'A-',
              onTap: () => widget.onFontSizeChanged(widget.fontSizeDelta - 2),
              enabled: widget.fontSizeDelta > -4,
            ),
            _FontSizeButton(
              label: 'A+',
              onTap: () => widget.onFontSizeChanged(widget.fontSizeDelta + 2),
              enabled: widget.fontSizeDelta < 8,
            ),
          ],
        ),
        const SizedBox(width: 4),
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isTimedMode &&
                    (widget.remainingTime?.inMinutes ?? 99) < 1
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isTimedMode &&
                      (widget.remainingTime?.inMinutes ?? 99) < 1
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isTimedMode
                    ? Icons.hourglass_bottom_rounded
                    : Icons.timer_outlined,
                size: 14,
                color: widget.isTimedMode &&
                        (widget.remainingTime?.inMinutes ?? 99) < 1
                    ? Colors.redAccent
                    : AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.isTimedMode
                    ? _formatDuration(widget.remainingTime ?? Duration.zero)
                    : _formatDuration(_stopwatch.elapsed),
                style: TextStyle(
                  color: widget.isTimedMode &&
                          (widget.remainingTime?.inMinutes ?? 99) < 1
                      ? Colors.redAccent
                      : Colors.white,
                  fontFamily: 'Monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterDialog extends ConsumerWidget {
  const _FilterDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final selectedSubject = ref.watch(selectedQuizSubjectProvider);
    final selectedTopic = ref.watch(selectedQuizTopicProvider);
    final topicsAsync = ref.watch(availableQuizTopicsProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF151A2C),
      title: const Text('Filtrar Simulado',
          style: TextStyle(color: Colors.white, fontSize: 18)),
      content: subjectsAsync.when(
        data: (subjects) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Matéria',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: selectedSubject,
              isExpanded: true,
              dropdownColor: const Color(0xFF151A2C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...subjects.map((s) =>
                    DropdownMenuItem(value: s.name, child: Text(s.name))),
              ],
              onChanged: (val) {
                ref.read(selectedQuizSubjectProvider.notifier).state = val;
                ref.read(selectedQuizTopicProvider.notifier).state = null;
              },
            ),
            if (selectedSubject != null) ...[
              const SizedBox(height: 20),
              const Text('Tópico',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              topicsAsync.when(
                data: (topics) => DropdownButtonFormField<String?>(
                  value: selectedTopic,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF151A2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...topics
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (val) {
                    ref.read(selectedQuizTopicProvider.notifier).state = val;
                  },
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (_, __) => const Text('Erro ao carregar tópicos',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro ao carregar matérias: $e',
            style: const TextStyle(color: Colors.red)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(selectedQuizSubjectProvider.notifier).state = null;
            ref.read(selectedQuizTopicProvider.notifier).state = null;
            Navigator.pop(context);
          },
          child: const Text('LIMPAR', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('APLICAR'),
        ),
      ],
    );
  }
}

class _FontSizeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _FontSizeButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white70 : Colors.white24,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
