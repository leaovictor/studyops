import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference get _groqConfig =>
      _db.collection(AppConstants.colConfigs).doc('groq_settings');

  Future<void> saveGroqApiKey(String key) async {
    await _groqConfig.set({
      'apiKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String?> watchGroqApiKey() {
    return _groqConfig.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>?;
      return data?['apiKey'] as String?;
    });
  }
}
