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

  /// Returns the total count of AI calls using Firestore aggregation query,
  /// avoiding a full collection scan on the client.
  Future<int> getTotalAICalls() async {
    final agg = await _db
        .collection(AppConstants.colUsage)
        .where('type', isEqualTo: 'ai_call')
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Returns the count of AI calls made by a specific user in the last hour.
  /// Used for client-side throttling display (server enforcement via Cloud Functions).
  Future<int> getUserAICallsLastHour(String userId) async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final agg = await _db
        .collection(AppConstants.colUsage)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'ai_call')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneHourAgo))
        .count()
        .get();
    return agg.count ?? 0;
  }
}
