import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../controllers/pomodoro_settings_controller.dart';
import 'package:animations/animations.dart';

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

  factory PomodoroState.initial(int workMins) => PomodoroState(
        phase: PomodoroPhase.work,
        secondsLeft: workMins * 60,
        running: false,
        completedSessions: 0,
      );
}

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;
  void Function(int minutes)? onSessionComplete;
  int workMins;
  int breakMins;

  PomodoroNotifier({
    this.onSessionComplete,
    this.workMins = 25,
    this.breakMins = 5,
  }) : super(PomodoroState.initial(workMins));

  void updateDurations(int work, int breakM) {
    if (workMins == work && breakMins == breakM) return;

    workMins = work;
    breakMins = breakM;

    // Only update secondsLeft if the timer is not running
    // If it's running, we let the current session finish with old duration
    if (!state.running) {
      if (state.phase == PomodoroPhase.work) {
        state = state.copyWith(secondsLeft: workMins * 60);
      } else {
        state = state.copyWith(secondsLeft: breakMins * 60);
      }
    }
  }

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
    state = PomodoroState.initial(workMins);
  }

  void _tick(Timer t) {
    if (state.secondsLeft <= 1) {
      _timer?.cancel();
      if (state.phase == PomodoroPhase.work) {
        final completed = state.completedSessions + 1;
        onSessionComplete?.call(workMins);
        state = PomodoroState(
          phase: PomodoroPhase.shortBreak,
          secondsLeft: breakMins * 60,
          running: false,
          completedSessions: completed,
        );
      } else {
        state = PomodoroState(
          phase: PomodoroPhase.work,
          secondsLeft: workMins * 60,
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

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (ref) {
    final notifier = PomodoroNotifier();

    // Listen to settings changes to update durations without re-creating the notifier
    ref.listen(pomodoroSettingsProvider, (prev, next) {
      final settings = next.valueOrNull;
      if (settings != null) {
        notifier.updateDurations(settings.workMinutes, settings.breakMinutes);
      }
    }, fireImmediately: true);

    return notifier;
  },
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
    final total = isWork ? notifier.workMins * 60 : notifier.breakMins * 60;
    final progress = 1 - (state.secondsLeft / total);

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: AppTheme.bg0,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openBuilder: (context, _) => _FocusModeScreen(
        state: state,
        notifier: notifier,
        total: total,
        progress: progress,
        color: color,
      ),
      closedBuilder: (context, openContainer) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: InkWell(
          onTap: openContainer,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isWork ? '🎯 Foco' : '☕ Pausa',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.fullscreen_rounded,
                      color: AppTheme.textMuted, size: 16),
                ],
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
        ),
      ),
    );
  }
}

class _FocusModeScreen extends StatefulWidget {
  final PomodoroState state;
  final PomodoroNotifier notifier;
  final int total;
  final double progress;
  final Color color;

  const _FocusModeScreen({
    required this.state,
    required this.notifier,
    required this.total,
    required this.progress,
    required this.color,
  });

  @override
  State<_FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<_FocusModeScreen> {
  late ConfettiController _confettiController;
  bool _wasWork = true;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _wasWork = widget.state.phase == PomodoroPhase.work;
  }

  @override
  void didUpdateWidget(_FocusModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isWork = widget.state.phase == PomodoroPhase.work;
    if (_wasWork && !isWork && widget.state.secondsLeft > 0) {
      _confettiController.play();
    }
    _wasWork = isWork;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWork = widget.state.phase == PomodoroPhase.work;

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded,
                          color: AppTheme.textSecondary, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isWork ? 'EM FOCO' : 'HORA DO DESCANSO',
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: widget.progress,
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation(widget.color),
                          strokeWidth: 8,
                        ),
                        Center(
                          child: Text(
                            AppDateUtils.formatCountdown(
                                widget.state.secondsLeft),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  _MotivationalQuote(
                      isWork: isWork, secondsLeft: widget.state.secondsLeft),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.large(
                        onPressed: widget.notifier.toggle,
                        backgroundColor: widget.color,
                        child: Icon(
                          widget.state.running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 32),
                      FloatingActionButton(
                        onPressed: widget.notifier.reset,
                        backgroundColor: AppTheme.bg2,
                        child: const Icon(Icons.refresh_rounded,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
      ),
    );
  }
}

class _MotivationalQuote extends StatelessWidget {
  final bool isWork;
  final int secondsLeft;

  const _MotivationalQuote({required this.isWork, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    String quote = '';
    if (isWork) {
      if (secondsLeft > 1200) {
        quote = 'O começo é a parte mais importante do trabalho.';
      } else if (secondsLeft > 600) {
        quote = 'Mantenha a cabeça no jogo. Você está indo bem!';
      } else {
        quote = 'Quase lá! Termine o que você começou.';
      }
    } else {
      quote = 'Respire fundo. Recarregar é parte do progresso.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        quote,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 18,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
