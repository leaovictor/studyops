import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

final userSessionProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
});

class AuthController extends AsyncNotifier<User?> {
  AuthService get _service => ref.read(authServiceProvider);
  UserService get _userService => UserService();

  @override
  User? build() {
    return _service.currentUser;
  }

  Future<void> updatePersonalContext(String context) async {
    final user = state.valueOrNull;
    if (user == null) return;
    await _userService.updatePersonalContext(user.uid, context);
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
