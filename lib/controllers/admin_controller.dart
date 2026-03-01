import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_question_model.dart';
import '../services/usage_service.dart';
import '../services/config_service.dart';
import 'auth_controller.dart';
import 'performance_controller.dart';

final usageServiceProvider = Provider<UsageService>((ref) => UsageService());
final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final groqApiKeyProvider = StreamProvider<String?>((ref) {
  return ref.watch(configServiceProvider).watchGroqApiKey();
});

final pendingQuestionsProvider = StreamProvider<List<SharedQuestion>>((ref) {
  return ref
      .watch(questionBankServiceProvider)
      .watchSharedQuestions(onlyApproved: false);
});

final totalAICallsProvider = FutureProvider<int>((ref) {
  return ref.watch(usageServiceProvider).getTotalAICalls();
});

class AdminController extends AsyncNotifier<void> {
  static const adminUids = ['M9CWoXUk1HaW1e5CaxlarH6LxE83'];

  bool get isAdmin {
    final user = ref.read(authStateProvider).valueOrNull;
    return user != null && adminUids.contains(user.uid);
  }

  @override
  Future<void> build() async {}

  Future<void> saveGroqApiKey(String apiKey) async {
    await ref.read(configServiceProvider).saveGroqApiKey(apiKey);
  }

  Future<void> approveQuestion(String id) async {
    if (!isAdmin) return;
    await ref.read(questionBankServiceProvider).approveQuestion(id);
  }

  Future<void> rejectQuestion(String id) async {
    if (!isAdmin) return;
    await ref.read(questionBankServiceProvider).deleteQuestion(id);
  }
}

final adminControllerProvider =
    AsyncNotifierProvider<AdminController, void>(AdminController.new);
