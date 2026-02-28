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

    // UID not found, check if a document with the same email exists
    final emailQuery = await _db
        .collection(AppConstants.colUsers)
        .where('email', isEqualTo: firebaseUser.email)
        .limit(1)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      // Existing email with different UID found!
      final existingDoc = emailQuery.docs.first;
      // Option: Migrate UID or just link them. For now, since Firebase "One account per email"
      // is active, this case is rare but can happen during transitions.
      // We'll update the existing document to also include this UID or just log it.
      // Better: Update the existing document's timestamp and info.
      await existingDoc.reference.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'id': firebaseUser.uid, // Update ID to current UID
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
