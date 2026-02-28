import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  GoogleSignIn? _googleSignInInstance;

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      clientId:
          '379727416390-po7ijsos4c45i6k9c547mtct9smjl496.apps.googleusercontent.com',
    );
    return _googleSignInInstance!;
  }

  // Helper to check if Google Sign-In is configured on Web
  bool get isGoogleSignInConfigured {
    // This is a simplified check. In a real app, we might check if a meta tag exists
    // or if the configuration was passed. For now, we'll try to prevent the crash.
    return true;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (cred.user != null) {
      await _userService.syncUser(cred.user!);
    }
    return cred;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (cred.user != null) {
      await _userService.syncUser(cred.user!);
    }
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await _userService.syncUser(cred.user!);
      }
      return cred;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('account-exists-with-different-credential')) {
        // This is a common case when a user has an email/password account and tries to login with Google
        // For a seamless experience with "One account per email", we would ideally link them.
        // But linking requires the user to sign in with the old provider first.
        // A simpler "Guarantee" is to tell the user to use their existing method,
        // OR we can try to facilitate the connection.
        throw 'Já existe uma conta com este e-mail vinculada a outro método (ex: E-mail/Senha). Por favor, entre com o método original primeiro.';
      }
      if (errorStr.contains('ClientID not set')) {
        throw 'Google Sign-In não configurado para Web. Por favor, adicione o Client ID no index.html.';
      }
      if (errorStr.contains('People API') || errorStr.contains('403')) {
        throw 'A "People API" precisa ser ativada no Google Cloud Console para este projeto. Acesse o link no log do console para ativar e tente novamente.';
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final futures = <Future>[_auth.signOut()];
    if (_googleSignInInstance != null) {
      futures.add(_googleSignInInstance!.signOut());
    }
    await Future.wait(futures);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
