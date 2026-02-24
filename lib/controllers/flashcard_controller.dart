import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart';
import '../models/flashcard_model.dart';
import '../services/flashcard_service.dart';
import 'auth_controller.dart';
import 'goal_controller.dart';

final flashcardServiceProvider =
    Provider<FlashcardService>((ref) => FlashcardService());

/// All flashcards for the current user.
final flashcardsProvider = StreamProvider<List<Flashcard>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final goalId = ref.watch(activeGoalIdProvider);
  return ref.watch(flashcardServiceProvider).watchAll(user.uid, goalId: goalId);
});

/// Only cards due today (or overdue).
final dueFlashcardsProvider = StreamProvider<List<Flashcard>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final goalId = ref.watch(activeGoalIdProvider);
  return ref
      .watch(flashcardServiceProvider)
      .watchDueToday(user.uid, goalId: goalId);
});

/// Cards due today grouped by subjectId.
final dueBySubjectProvider = Provider<Map<String, List<Flashcard>>>((ref) {
  final due = ref.watch(dueFlashcardsProvider).valueOrNull ?? [];
  final map = <String, List<Flashcard>>{};
  for (final card in due) {
    map.putIfAbsent(card.subjectId, () => []).add(card);
  }
  return map;
});

class FlashcardController extends AsyncNotifier<void> {
  FlashcardService get _service => ref.read(flashcardServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> create(Flashcard card) async {
    await _service.create(card);
  }

  Future<void> updateCard(Flashcard card) async {
    await _service.update(card);
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
  }

  Future<Flashcard> rate(Flashcard card, Rating rating) async {
    return _service.rateCard(card, rating);
  }
}

final flashcardControllerProvider =
    AsyncNotifierProvider<FlashcardController, void>(FlashcardController.new);
