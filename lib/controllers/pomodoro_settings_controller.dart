import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pomodoro_settings_model.dart';
import '../services/pomodoro_settings_service.dart';
import 'auth_controller.dart';

final pomodoroSettingsServiceProvider =
    Provider((ref) => PomodoroSettingsService());

final pomodoroSettingsProvider =
    AsyncNotifierProvider<PomodoroSettingsController, PomodoroSettings?>(
        PomodoroSettingsController.new);

class PomodoroSettingsController extends AsyncNotifier<PomodoroSettings?> {
  PomodoroSettingsService get _service =>
      ref.read(pomodoroSettingsServiceProvider);

  @override
  Future<PomodoroSettings?> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return null;

    final settings = await _service.getSettings(user.uid);
    return settings ?? PomodoroSettings.defaultFor(user.uid);
  }

  Future<void> updateSettings(int workMinutes, int breakMinutes) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _service.saveSettings(updated);
      return updated;
    });
  }
}
