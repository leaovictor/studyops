import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> syncUser(auth.User firebaseUser) async {
    final userRef = _db.collection(AppConstants.colUsers).doc(firebaseUser.uid);
    final doc = await userRef.get();

    if (doc.exists) {
      // UID already exists, just update lastLogin
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'displayName': firebaseUser.displayName ?? doc.get('displayName'),
        'photoUrl': firebaseUser.photoURL ?? doc.get('photoUrl'),
      });
      return;
    }

    // UID not found — check if another document exists for the same email
    // (e.g. user registered with email/password AND Google for the same address)
    final emailQuery = await _db
        .collection(AppConstants.colUsers)
        .where('email', isEqualTo: firebaseUser.email)
        .limit(1)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      // There is already a profile for this email (possibly created by a
      // different auth provider). We create a NEW document keyed by the
      // current UID so that Firestore rules (uid == docId) are satisfied.
      // The old document is left intact so the other provider still works.
      final existingData = emailQuery.docs.first.data();
      await userRef.set({
        ...existingData,
        'id': firebaseUser.uid,
        'lastLogin': FieldValue.serverTimestamp(),
        'displayName': firebaseUser.displayName ?? existingData['displayName'],
        'photoUrl': firebaseUser.photoURL ?? existingData['photoUrl'],
      });
      return;
    }

    // Truly new user
    final newUser = UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
    await userRef.set(newUser.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updatePersonalContext(String uid, String context) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update({
      'personalContext': context,
    });
  }
}
