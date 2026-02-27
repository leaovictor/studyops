import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../services/subject_service.dart';
import '../services/ai_service.dart';
import 'auth_controller.dart';
import 'goal_controller.dart';

import '../services/usage_service.dart';
import 'admin_controller.dart';

final subjectServiceProvider =
    Provider<SubjectService>((ref) => SubjectService());

final aiServiceProvider = Provider<AIService?>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider).valueOrNull;
  if (apiKey == null || apiKey.isEmpty) return null;

  return AIService(
    apiKey: apiKey,
    usageService: UsageService(),
  );
});

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
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(subjectServiceProvider).watchTopics(user.uid, subjectId);
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

  Future<void> createMultipleSubjectsAndTopics(
      List<Subject> subjects, List<Topic> topics) async {
    state = const AsyncLoading();
    try {
      for (final subject in subjects) {
        // 1. Create subject
        final createdSubject = await _service.createSubject(subject);
        
        // 2. Create topics for this subject
        final subjectTopics = topics.where((t) => t.subjectId == subject.id);
        for (final topic in subjectTopics) {
          await _service.createTopic(topic.copyWith(subjectId: createdSubject.id));
        }
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createSubject(Subject subject) async {
    state = const AsyncLoading();
    try {
      await _service.createSubject(subject);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createSubjectWithId(Subject subject) async {
    state = const AsyncLoading();
    try {
      await _service.createSubjectWithId(subject);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createDefaultTopic(String subjectId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');
      await _service.createDefaultTopic(user.uid, subjectId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    state = const AsyncLoading();
    try {
      await _service.updateSubject(subject);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');
      await _service.deleteSubject(user.uid, subjectId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> createTopic(Topic topic) async {
    state = const AsyncLoading();
    try {
      await _service.createTopic(topic);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateTopic(Topic topic) async {
    state = const AsyncLoading();
    try {
      await _service.updateTopic(topic);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteTopic(String topicId) async {
    state = const AsyncLoading();
    try {
      await _service.deleteTopic(topicId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final subjectControllerProvider =
    AsyncNotifierProvider<SubjectController, void>(SubjectController.new);
