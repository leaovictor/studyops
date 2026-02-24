import 'package:wakelock_plus/wakelock_plus.dart';

class FocusService {
  /// Enables wake lock to keep the screen on.
  Future<void> enableWakeLock() async {
    await WakelockPlus.enable();
  }

  /// Disables wake lock allowing the screen to turn off.
  Future<void> disableWakeLock() async {
    await WakelockPlus.disable();
  }

  /// Returns true if wake lock is enabled.
  Future<bool> get isEnabled async => await WakelockPlus.enabled;
}
