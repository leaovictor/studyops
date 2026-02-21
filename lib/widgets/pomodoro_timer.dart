import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_date_utils.dart';

enum PomodoroPhase { work, shortBreak }

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsLeft;
  final bool running;
  final int completedSessions;

  const PomodoroState({
    required this.phase,
    required this.secondsLeft,
    required this.running,
    required this.completedSessions,
  });

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsLeft,
    bool? running,
    int? completedSessions,
  }) =>
      PomodoroState(
        phase: phase ?? this.phase,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        running: running ?? this.running,
        completedSessions: completedSessions ?? this.completedSessions,
      );

  factory PomodoroState.initial() => const PomodoroState(
        phase: PomodoroPhase.work,
        secondsLeft: AppConstants.pomodoroWorkMinutes * 60,
        running: false,
        completedSessions: 0,
      );
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  final void Function(int minutes)? onSessionComplete;

  PomodoroNotifier({this.onSessionComplete}) : super(PomodoroState.initial());

  void toggle() {
    if (state.running) {
      _timer?.cancel();
      state = state.copyWith(running: false);
    } else {
      state = state.copyWith(running: true);
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState.initial();
  }

  void _tick(Timer t) {
    if (state.secondsLeft <= 1) {
      _timer?.cancel();
      if (state.phase == PomodoroPhase.work) {
        final completed = state.completedSessions + 1;
        onSessionComplete?.call(AppConstants.pomodoroWorkMinutes);
        state = PomodoroState(
          phase: PomodoroPhase.shortBreak,
          secondsLeft: AppConstants.pomodoroBreakMinutes * 60,
          running: false,
          completedSessions: completed,
        );
      } else {
        state = PomodoroState(
          phase: PomodoroPhase.work,
          secondsLeft: AppConstants.pomodoroWorkMinutes * 60,
          running: false,
          completedSessions: state.completedSessions,
        );
      }
    } else {
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroProvider =
    StateNotifierProvider.autoDispose<PomodoroNotifier, PomodoroState>(
  (ref) => PomodoroNotifier(),
);

class PomodoroTimer extends ConsumerWidget {
  final void Function(int minutes)? onSessionComplete;

  const PomodoroTimer({super.key, this.onSessionComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);

    final isWork = state.phase == PomodoroPhase.work;
    final color = isWork ? AppTheme.primary : AppTheme.accent;
    final total = isWork
        ? AppConstants.pomodoroWorkMinutes * 60
        : AppConstants.pomodoroBreakMinutes * 60;
    final progress = 1 - (state.secondsLeft / total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bg3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isWork ? '🎯 Foco' : '☕ Pausa',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 5,
                ),
                Center(
                  child: Text(
                    AppDateUtils.formatCountdown(state.secondsLeft),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: notifier.toggle,
                icon: Icon(
                  state.running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: color,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: color.withOpacity(0.15),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: notifier.reset,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppTheme.textSecondary),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.bg2,
                ),
              ),
            ],
          ),
          if (state.completedSessions > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${state.completedSessions} sessão(ões) concluída(s)',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
