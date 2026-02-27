import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/error_note_model.dart';
import '../services/error_notebook_service.dart';
import 'auth_controller.dart';
import 'goal_controller.dart';

final errorNotebookServiceProvider =
    Provider<ErrorNotebookService>((ref) => ErrorNotebookService());

final errorNotesProvider = StreamProvider<List<ErrorNote>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final goalId = ref.watch(activeGoalIdProvider);
  return ref
      .watch(errorNotebookServiceProvider)
      .watchAllNotes(user.uid, goalId: goalId);
});

final dueTodayNotesProvider = FutureProvider<List<ErrorNote>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  final goalId = ref.watch(activeGoalIdProvider);
  return ref
      .watch(errorNotebookServiceProvider)
      .getDueToday(user.uid, goalId: goalId);
});

class ErrorNotebookController extends AsyncNotifier<void> {
  ErrorNotebookService get _service => ref.read(errorNotebookServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> createNote(ErrorNote note) async {
    await _service.createNote(note);
  }

  Future<void> updateNote(ErrorNote note) async {
    await _service.updateNote(note);
  }

  Future<void> deleteNote(String noteId) async {
    await _service.deleteNote(noteId);
  }

  Future<void> markReviewed(ErrorNote note) async {
    await _service.markReviewed(note);
    // Invalidate due-today cache
    ref.invalidate(dueTodayNotesProvider);
  }
}

final errorNotebookControllerProvider =
    AsyncNotifierProvider<ErrorNotebookController, void>(
        ErrorNotebookController.new);
