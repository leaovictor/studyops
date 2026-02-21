import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthController extends AsyncNotifier<User?> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  Future<User?> build() async {
    return _service.currentUser;
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service
          .signInWithEmail(email, password)
          .then((_) => _service.currentUser),
    );
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service
          .signUpWithEmail(email, password)
          .then((_) => _service.currentUser),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.signInWithGoogle().then((_) => _service.currentUser),
    );
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
