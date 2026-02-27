import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference get _geminiConfig => _db.collection(AppConstants.colConfigs).doc('gemini_settings');

  Future<void> saveGeminiApiKey(String key) async {
    await _geminiConfig.set({
      'apiKey': key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<String?> watchGeminiApiKey() {
    return _geminiConfig.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>?;
      return data?['apiKey'] as String?;
    });
  }
}
