import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../controllers/pomodoro_settings_controller.dart';
import 'package:animations/animations.dart';
import '../services/focus_service.dart';

final focusServiceProvider = Provider<FocusService>((ref) => FocusService());

enum PomodoroPhase { work, shortBreak }

class PomodoroState {
  final PomodoroPhase phase;
  final int secondsLeft;
  final bool running;
  final int completedSessions;
  final int currentSessionMinutes;

  const PomodoroState({
    required this.phase,
    required this.secondsLeft,
    required this.running,
    required this.completedSessions,
    this.currentSessionMinutes = 0,
  });

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? secondsLeft,
    bool? running,
    int? completedSessions,
    int? currentSessionMinutes,
  }) =>
      PomodoroState(
        phase: phase ?? this.phase,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        running: running ?? this.running,
        completedSessions: completedSessions ?? this.completedSessions,
        currentSessionMinutes:
            currentSessionMinutes ?? this.currentSessionMinutes,
      );

  factory PomodoroState.initial(int workMins) => PomodoroState(
        phase: PomodoroPhase.work,
        secondsLeft: workMins * 60,
        running: false,
        completedSessions: 0,
        currentSessionMinutes: workMins,
      );
}

class PomodoroNotifier extends StateNotifier<PomodoroState>
    with WidgetsBindingObserver {
  Timer? _timer;
  int workMins;
  int breakMins;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FocusService _focusService;

  // Event stream for showing UI alerts
  final _eventController = StreamController<String>.broadcast();
  Stream<String> get events => _eventController.stream;

  PomodoroNotifier({
    required FocusService focusService,
    this.workMins = 25,
    this.breakMins = 5,
  })  : _focusService = focusService,
        super(PomodoroState.initial(workMins)) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive ||
        appState == AppLifecycleState.hidden) {
      if (state.running) {
        _stopTimer();
        _eventController
            .add('Modo Hardcore: O timer foi pausado por sair do aplicativo!');
      }
    }
  }

  void updateDurations(int work, int breakM) {
    if (workMins == work && breakMins == breakM) return;

    workMins = work;
    breakMins = breakM;

    // Only update secondsLeft if the timer is not running
    // If it's running, we let the current session finish with old duration
    if (!state.running) {
      if (state.phase == PomodoroPhase.work) {
        state = state.copyWith(
          secondsLeft: workMins * 60,
          currentSessionMinutes: workMins,
        );
      } else {
        state = state.copyWith(
          secondsLeft: breakMins * 60,
          currentSessionMinutes: breakMins,
        );
      }
    }
  }

  void toggle() {
    if (state.running) {
      _stopTimer();
    } else {
      final sessionMins =
          state.phase == PomodoroPhase.work ? workMins : breakMins;
      state = state.copyWith(
        running: true,
        currentSessionMinutes: sessionMins,
      );
      _focusService.enableWakeLock();
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _focusService.disableWakeLock();
    state = state.copyWith(running: false);
  }

  void reset() {
    _stopTimer();
    state = PomodoroState.initial(workMins);
  }

  void _tick(Timer t) {
    if (state.secondsLeft <= 1) {
      _timer?.cancel();
      _playSound();
      if (state.phase == PomodoroPhase.work) {
        final completed = state.completedSessions + 1;
        state = PomodoroState(
          phase: PomodoroPhase.shortBreak,
          secondsLeft: breakMins * 60,
          running: false,
          completedSessions: completed,
          currentSessionMinutes: breakMins,
        );
      } else {
        state = PomodoroState(
          phase: PomodoroPhase.work,
          secondsLeft: workMins * 60,
          running: false,
          completedSessions: state.completedSessions,
          currentSessionMinutes: workMins,
        );
      }
      _focusService.disableWakeLock();
    } else {
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    }
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource(
          'song/freesound_community-winner-bell-game-show-91932.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _eventController.close();
    _focusService.disableWakeLock();
    _audioPlayer.dispose();
    super.dispose();
  }
}

final pomodoroProvider = StateNotifierProvider<PomodoroNotifier, PomodoroState>(
  (ref) {
    final focusService = ref.watch(focusServiceProvider);
    final notifier = PomodoroNotifier(focusService: focusService);

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
  const PomodoroTimer({super.key});

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
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openBuilder: (context, _) => const _FocusModeScreen(),
      closedBuilder: (context, openContainer) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
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
                  Icon(Icons.fullscreen_rounded,
                      color: (Theme.of(context).textTheme.labelSmall?.color ??
                          Colors.grey),
                      size: 16),
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
                      backgroundColor: Theme.of(context).dividerColor,
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeWidth: 5,
                    ),
                    Center(
                      child: Text(
                        AppDateUtils.formatCountdown(state.secondsLeft),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color:
                              (Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.white),
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
                    onPressed: () {
                      final wasRunning = state.running;
                      notifier.toggle();
                      if (!wasRunning) {
                        openContainer();
                      }
                    },
                    icon: Icon(
                      state.running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: color,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: notifier.reset,
                    icon: Icon(Icons.refresh_rounded,
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey)),
                    style: IconButton.styleFrom(
                      backgroundColor: (Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface),
                    ),
                  ),
                ],
              ),
              if (state.completedSessions > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${state.completedSessions} sessão(ões) concluída(s)',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.labelSmall?.color ??
                          Colors.grey),
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

class _FocusModeScreen extends ConsumerStatefulWidget {
  const _FocusModeScreen();

  @override
  ConsumerState<_FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<_FocusModeScreen> {
  late ConfettiController _confettiController;
  StreamSubscription<String>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Listen to Anti-AFK events from notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(pomodoroProvider.notifier);
      _eventSubscription = notifier.events.listen((message) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🛑 $message'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isWork = state.phase == PomodoroPhase.work;
    final color = isWork ? AppTheme.primary : AppTheme.accent;
    final total = isWork ? notifier.workMins * 60 : notifier.breakMins * 60;
    final progress = 1 - (state.secondsLeft / total);

    ref.listen<PomodoroState>(pomodoroProvider, (previous, next) {
      if (previous != null) {
        final wasWork = previous.phase == PomodoroPhase.work;
        final isNowWork = next.phase == PomodoroPhase.work;
        if (wasWork && !isNowWork && next.secondsLeft > 0) {
          _confettiController.play();
        }
      }
    });

    return PopScope(
        canPop: !state.running,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Pause o temporizador antes de sair do modo Foco.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!state.running)
                              IconButton(
                                icon: Icon(Icons.settings_rounded,
                                    color: (Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        Colors.grey),
                                    size: 28),
                                onPressed: () =>
                                    _showSettings(context, ref, notifier),
                                tooltip: 'Configurações do Pomodoro',
                              ),
                            IconButton(
                              icon: Icon(Icons.fullscreen_exit_rounded,
                                  color: (Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color ??
                                      Colors.grey),
                                  size: 32),
                              onPressed: () => Navigator.maybePop(context),
                              tooltip: 'Sair do modo foco',
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isWork ? 'EM FOCO' : 'HORA DO DESCANSO',
                        style: TextStyle(
                          color: color,
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
                              value: progress,
                              backgroundColor: Theme.of(context).dividerColor,
                              valueColor: AlwaysStoppedAnimation(color),
                              strokeWidth: 8,
                            ),
                            Center(
                              child: Text(
                                AppDateUtils.formatCountdown(state.secondsLeft),
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: (Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color ??
                                      Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      _MotivationalQuote(
                          isWork: isWork, secondsLeft: state.secondsLeft),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.large(
                            onPressed: notifier.toggle,
                            backgroundColor: color,
                            child: Icon(
                              state.running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 32),
                          FloatingActionButton(
                            onPressed: notifier.reset,
                            backgroundColor:
                                (Theme.of(context).cardTheme.color ??
                                    Theme.of(context).colorScheme.surface),
                            child: Icon(Icons.refresh_rounded,
                                color: (Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color ??
                                    Colors.grey)),
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
        ));
  }

  void _showSettings(
      BuildContext context, WidgetRef ref, PomodoroNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(builder: (context, ref, _) {
        final settings = ref.watch(pomodoroSettingsProvider).valueOrNull;
        if (settings == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustar Temporizador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              _DurationSlider(
                label: 'Foco',
                icon: Icons.timer_rounded,
                color: AppTheme.primary,
                value: settings.workMinutes.toDouble(),
                min: 5,
                max: 90,
                divisions: 17,
                onChanged: (v) => ref
                    .read(pomodoroSettingsProvider.notifier)
                    .updateSettings(v.toInt(), settings.breakMinutes),
              ),
              const SizedBox(height: 16),
              _DurationSlider(
                label: 'Pausa',
                icon: Icons.coffee_rounded,
                color: AppTheme.accent,
                value: settings.breakMinutes.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (v) => ref
                    .read(pomodoroSettingsProvider.notifier)
                    .updateSettings(settings.workMinutes, v.toInt()),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white))),
            const Spacer(),
            Text('${value.toInt()} min',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
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
        style: TextStyle(
          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
          fontSize: 18,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
