import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import '../controllers/flashcard_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/flashcard_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';

class FlashcardStudyScreen extends ConsumerStatefulWidget {
  final String? subjectId; // null = all due cards

  const FlashcardStudyScreen({super.key, this.subjectId});

  @override
  ConsumerState<FlashcardStudyScreen> createState() =>
      _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends ConsumerState<FlashcardStudyScreen> {
  int _currentIndex = 0;
  bool _flipped = false;
  bool _rated = false;
  int _correct = 0;
  int _incorrect = 0;
  bool _sessionDone = false;
  late ConfettiController _confettiController;

  List<Flashcard> _cards = [];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCards());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadCards() {
    final due = ref.read(dueFlashcardsProvider).valueOrNull ?? [];
    final filtered = widget.subjectId != null
        ? due.where((c) => c.subjectId == widget.subjectId).toList()
        : due;
    setState(() {
      _cards = filtered;
      _sessionDone = filtered.isEmpty;
    });
  }

  Future<void> _rate(fsrs.Rating rating) async {
    if (_rated) return;
    setState(() => _rated = true);

    final card = _cards[_currentIndex];
    await ref.read(flashcardControllerProvider.notifier).rate(card, rating);

    if (rating == fsrs.Rating.again) {
      setState(() => _incorrect++);
    } else {
      setState(() => _correct++);
    }

    await Future.delayed(const Duration(milliseconds: 350));

    if (_currentIndex + 1 >= _cards.length) {
      setState(() => _sessionDone = true);
      _confettiController.play();
    } else {
      setState(() {
        _currentIndex++;
        _flipped = false;
        _rated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      appBar: AppBar(
        backgroundColor: AppTheme.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: _sessionDone || _cards.isEmpty
            ? null
            : _ProgressBar(current: _currentIndex + 1, total: _cards.length),
      ),
      body: Stack(
        children: [
          _sessionDone || _cards.isEmpty
              ? _DonePanel(correct: _correct, incorrect: _incorrect)
              : _StudyPanel(
                  card: _cards[_currentIndex],
                  flipped: _flipped,
                  rated: _rated,
                  onFlip: () => setState(() => _flipped = true),
                  onRate: _rate,
                ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primary,
                AppTheme.accent,
                Colors.orange,
                Colors.pink,
                Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$current / $total',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: current / total),
            duration: const Duration(milliseconds: 400),
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Study panel — flip card + buttons
// ---------------------------------------------------------------------------
class _StudyPanel extends ConsumerWidget {
  final Flashcard card;
  final bool flipped;
  final bool rated;
  final VoidCallback onFlip;
  final Future<void> Function(fsrs.Rating) onRate;

  const _StudyPanel({
    required this.card,
    required this.flipped,
    required this.rated,
    required this.onFlip,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final subjectColor = subjects.isEmpty
        ? AppTheme.primary
        : () {
            try {
              final s = subjects.firstWhere((s) => s.id == card.subjectId);
              return Color(
                  int.parse('FF${s.color.replaceAll('#', '')}', radix: 16));
            } catch (_) {
              return AppTheme.primary;
            }
          }();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Flip card with 3D animation
          GestureDetector(
            onTap: flipped ? null : onFlip,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: flipped ? pi : 0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              builder: (_, angle, __) {
                final showBack = angle > pi / 2;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: Transform(
                    transform: showBack
                        ? (Matrix4.identity()..rotateY(pi))
                        : Matrix4.identity(),
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 300,
                      child: showBack
                          ? _CardFace(
                              label: 'RESPOSTA',
                              text: card.back,
                              color: subjectColor,
                            )
                          : _CardFace(
                              label: 'PERGUNTA',
                              text: card.front,
                              color: subjectColor,
                              hint: 'Toque para revelar a resposta',
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (!flipped)
            TextButton.icon(
              onPressed: onFlip,
              icon: const Icon(Icons.flip_rounded, size: 16),
              label: const Text('Revelar resposta'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            )
          else if (!rated)
            _RatingButtons(card: card, onRate: onRate)
          else
            const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final String? hint;

  const _CardFace({
    required this.label,
    required this.text,
    required this.color,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 20),
            Text(
              hint!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _RatingButtons extends StatelessWidget {
  final Flashcard card;
  final Future<void> Function(fsrs.Rating) onRate;
  const _RatingButtons({required this.card, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final scheduler = fsrs.Scheduler();
    final fsrsCard = card.fsrsCard.isEmpty
        ? fsrs.Card(cardId: 1)
        : fsrs.Card.fromMap(card.fsrsCard);

    String getInterval(fsrs.Rating rating) {
      final res = scheduler.reviewCard(fsrsCard, rating);
      return AppDateUtils.formatFsrsInterval(res.card.due);
    }

    return Row(
      children: [
        Expanded(
          child: _RatingBtn(
            label: 'Errei',
            interval: getInterval(fsrs.Rating.again),
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => onRate(fsrs.Rating.again),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingBtn(
            label: 'Difícil',
            interval: getInterval(fsrs.Rating.hard),
            icon: Icons.sentiment_neutral_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => onRate(fsrs.Rating.hard),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingBtn(
            label: 'Bom',
            interval: getInterval(fsrs.Rating.good),
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: AppTheme.primary,
            onTap: () => onRate(fsrs.Rating.good),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RatingBtn(
            label: 'Fácil',
            interval: getInterval(fsrs.Rating.easy),
            icon: Icons.check_rounded,
            color: const Color(0xFF10B981),
            onTap: () => onRate(fsrs.Rating.easy),
          ),
        ),
      ],
    );
  }
}

class _RatingBtn extends StatelessWidget {
  final String label;
  final String interval;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RatingBtn({
    required this.label,
    required this.interval,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interval,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Done panel
// ---------------------------------------------------------------------------
class _DonePanel extends StatelessWidget {
  final int correct;
  final int incorrect;

  const _DonePanel({required this.correct, required this.incorrect});

  @override
  Widget build(BuildContext context) {
    final total = correct + incorrect;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.celebration_rounded,
                  color: AppTheme.accent, size: 56),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sessão concluída!',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (total == 0)
              const Text(
                'Nenhum card para revisar hoje.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              )
            else ...[
              Text(
                '$total cards revisados',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Stat(
                      value: correct,
                      label: 'Acertos',
                      color: const Color(0xFF10B981)),
                  const SizedBox(width: 32),
                  _Stat(
                      value: incorrect,
                      label: 'Erros',
                      color: const Color(0xFFEF4444)),
                ],
              ),
            ],
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
