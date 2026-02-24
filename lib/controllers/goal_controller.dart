import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../models/subject_model.dart';
import '../models/error_note_model.dart';
import '../services/goal_service.dart';
import '../services/subject_service.dart';
import '../services/error_notebook_service.dart';
import 'auth_controller.dart';

final goalServiceProvider = Provider<GoalService>((ref) => GoalService());

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(goalServiceProvider).watchGoals(user.uid);
});

// The active goal ID state
final activeGoalIdProvider = StateProvider<String?>((ref) => null);

// The active goal model (if any)
final activeGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  final activeId = ref.watch(activeGoalIdProvider);
  if (activeId == null) return null;

  try {
    return goals.firstWhere((g) => g.id == activeId);
  } catch (_) {
    return goals.isNotEmpty ? goals.first : null;
  }
});

class GoalController extends AsyncNotifier<void> {
  GoalService get _service => ref.read(goalServiceProvider);

  @override
  Future<void> build() async {
    // Check for legacy data on initialization
    await _handleLegacyData();
  }

  Future<void> _handleLegacyData() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final goals = await _service.getGoalsOnce(user.uid);
    Goal activeGoal;

    if (goals.isEmpty) {
      // Create a default "Geral" goal
      activeGoal = await _service.createGoal(Goal(
        id: '',
        userId: user.uid,
        name: 'Geral',
        createdAt: DateTime.now(),
      ));
    } else {
      activeGoal = goals.first;
    }

    // Set as active if none selected
    if (ref.read(activeGoalIdProvider) == null) {
      ref.read(activeGoalIdProvider.notifier).state = activeGoal.id;
    }

    // Check subjects without goalId
    final subjectService = SubjectService();
    final subjects = await _dbGetSubjectsOnce(user.uid);

    for (final subject in subjects) {
      if (subject.goalId == null) {
        await subjectService
            .updateSubject(subject.copyWith(goalId: activeGoal.id));
      }
    }

    // Check error notes without goalId
    final errorService = ErrorNotebookService();
    final notes = await _dbGetErrorNotesOnce(user.uid);

    for (final note in notes) {
      if (note.goalId == null) {
        await errorService.updateNote(note.copyWith(goalId: activeGoal.id));
      }
    }
  }

  Future<List<ErrorNote>> _dbGetErrorNotesOnce(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('error_notebook')
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map((d) => ErrorNote.fromDoc(d)).toList();
  }

  Future<List<Subject>> _dbGetSubjectsOnce(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('subjects')
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.map((d) => Subject.fromDoc(d)).toList();
  }

  Future<void> createGoal(String name) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final goal = Goal(
      id: '',
      userId: user.uid,
      name: name,
      createdAt: DateTime.now(),
    );
    final newGoal = await _service.createGoal(goal);
    ref.read(activeGoalIdProvider.notifier).state = newGoal.id;
  }

  Future<void> setActiveGoal(String goalId) async {
    ref.read(activeGoalIdProvider.notifier).state = goalId;
  }

  Future<void> deleteGoal(String goalId) async {
    await _service.deleteGoal(goalId);
    if (ref.read(activeGoalIdProvider) == goalId) {
      ref.read(activeGoalIdProvider.notifier).state = null;
    }
  }
}

final goalControllerProvider =
    AsyncNotifierProvider<GoalController, void>(GoalController.new);
