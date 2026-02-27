import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_plan_model.dart';
import '../services/study_plan_service.dart';
import '../services/subject_service.dart';
import 'auth_controller.dart';
import 'subject_controller.dart';
import 'goal_controller.dart';

final studyPlanServiceProvider =
    Provider<StudyPlanService>((ref) => StudyPlanService());

final activePlanProvider = StreamProvider<StudyPlan?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  final activeGoalId = ref.watch(activeGoalIdProvider);
  return ref
      .watch(studyPlanServiceProvider)
      .watchActivePlan(user.uid, goalId: activeGoalId);
});

class StudyPlanController extends AsyncNotifier<void> {
  StudyPlanService get _planService => ref.read(studyPlanServiceProvider);
  SubjectService get _subjectService => ref.read(subjectServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> createPlanAndGenerate(StudyPlan plan,
      {String? routineContext}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      StudyPlan saved;
      if (plan.id.isNotEmpty) {
        await _planService.updatePlan(plan);
        saved = plan;
      } else {
        saved = await _planService.createPlan(plan);
      }

      final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
      final topics = await _subjectService.getTopicsForSubjects(
        user.uid,
        subjects.map((s) => s.id).toList(),
      );

      final aiService = await ref.read(aiServiceProvider.future);

      await _planService.generateAndSaveTasks(
        plan: saved,
        subjects: subjects,
        topics: topics,
        aiService: aiService,
        routineContext: routineContext,
      );
    });
  }

  Future<void> regenerateTasks(StudyPlan plan, {String? routineContext}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Usuário não autenticado');

      final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
      final topics = await _subjectService.getTopicsForSubjects(
        user.uid,
        subjects.map((s) => s.id).toList(),
      );

      final aiService = await ref.read(aiServiceProvider.future);

      await _planService.generateAndSaveTasks(
        plan: plan,
        subjects: subjects,
        topics: topics,
        aiService: aiService,
        routineContext: routineContext,
      );
    });
  }

  Future<void> deletePlan(String planId) async {
    await _planService.deletePlan(planId);
  }
}

final studyPlanControllerProvider =
    AsyncNotifierProvider<StudyPlanController, void>(StudyPlanController.new);
