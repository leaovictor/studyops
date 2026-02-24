import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../services/subject_service.dart';
import 'auth_controller.dart';
import 'goal_controller.dart';

final subjectServiceProvider =
    Provider<SubjectService>((ref) => SubjectService());

final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final activeGoalId = ref.watch(activeGoalIdProvider);
  return ref
      .watch(subjectServiceProvider)
      .watchSubjects(user.uid, goalId: activeGoalId);
});

final topicsForSubjectProvider =
    StreamProvider.family<List<Topic>, String>((ref, subjectId) {
  return ref.watch(subjectServiceProvider).watchTopics(subjectId);
});

// All topics across all user subjects — used by schedule generator and selects
final allTopicsProvider = StreamProvider<List<Topic>>((ref) {
  final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
  final ids = subjects.map((s) => s.id).toList();
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null || ids.isEmpty) return Stream.value([]);
  return ref.watch(subjectServiceProvider).watchAllTopicsForUser(user.uid, ids);
});

class SubjectController extends AsyncNotifier<void> {
  SubjectService get _service => ref.read(subjectServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> createSubject(Subject subject) async {
    await _service.createSubject(subject);
  }

  Future<void> createSubjectWithId(Subject subject) async {
    await _service.createSubjectWithId(subject);
  }

  Future<void> createDefaultTopic(String subjectId) async {
    await _service.createDefaultTopic(subjectId);
  }

  Future<void> updateSubject(Subject subject) async {
    await _service.updateSubject(subject);
  }

  Future<void> deleteSubject(String subjectId) async {
    await _service.deleteSubject(subjectId);
  }

  Future<void> createTopic(Topic topic) async {
    await _service.createTopic(topic);
  }

  Future<void> updateTopic(Topic topic) async {
    await _service.updateTopic(topic);
  }

  Future<void> deleteTopic(String topicId) async {
    await _service.deleteTopic(topicId);
  }
}

final subjectControllerProvider =
    AsyncNotifierProvider<SubjectController, void>(SubjectController.new);
