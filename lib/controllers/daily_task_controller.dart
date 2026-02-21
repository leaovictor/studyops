import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_task_model.dart';
import '../services/daily_task_service.dart';
import 'auth_controller.dart';
import '../core/utils/app_date_utils.dart';

final dailyTaskServiceProvider =
    Provider<DailyTaskService>((ref) => DailyTaskService());

/// Currently selected date for the checklist screen
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyTasksProvider = StreamProvider<List<DailyTask>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final date = ref.watch(selectedDateProvider);
  if (user == null) return Stream.value([]);
  final dateKey = AppDateUtils.toKey(date);
  return ref
      .watch(dailyTaskServiceProvider)
      .watchTasksForDate(user.uid, dateKey);
});

class DailyTaskController extends AsyncNotifier<void> {
  DailyTaskService get _service => ref.read(dailyTaskServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> markDone(DailyTask task, int actualMinutes) async {
    await _service.markDone(task, actualMinutes);
  }

  Future<void> markUndone(String taskId) async {
    await _service.markUndone(taskId);
  }

  Future<void> addManualTask(DailyTask task) async {
    await _service.addManualTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _service.deleteTask(taskId);
  }
}

final dailyTaskControllerProvider =
    AsyncNotifierProvider<DailyTaskController, void>(DailyTaskController.new);
