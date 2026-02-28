import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class UsageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> logAIUsage(String userId, String feature) async {
    await _db.collection(AppConstants.colUsage).add({
      'userId': userId,
      'feature': feature,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'ai_call',
    });
  }

  Stream<int> watchTotalAICalls() {
    return _db
        .collection(AppConstants.colUsage)
        .where('type', isEqualTo: 'ai_call')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
