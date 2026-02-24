import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pomodoro_settings_model.dart';

class PomodoroSettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String colPomodoro = 'pomodoro_settings';

  Future<PomodoroSettings?> getSettings(String userId) async {
    final doc = await _db.collection(colPomodoro).doc(userId).get();
    if (!doc.exists) return null;
    return PomodoroSettings.fromMap(doc.data()!, userId);
  }

  Future<void> saveSettings(PomodoroSettings settings) async {
    await _db
        .collection(colPomodoro)
        .doc(settings.userId)
        .set(settings.toMap(), SetOptions(merge: true));
  }
}
