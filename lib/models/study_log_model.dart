import 'package:cloud_firestore/cloud_firestore.dart';

class StudyLog {
  final String id;
  final String userId;
  final String date; // "yyyy-MM-dd"
  final String subjectId;
  final int minutes;

  const StudyLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.subjectId,
    required this.minutes,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'date': date,
        'subjectId': subjectId,
        'minutes': minutes,
      };

  factory StudyLog.fromMap(String id, Map<String, dynamic> map) => StudyLog(
        id: id,
        userId: map['userId'] as String? ?? '',
        date: map['date'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        minutes: (map['minutes'] as num?)?.toInt() ?? 0,
      );

  factory StudyLog.fromDoc(DocumentSnapshot doc) =>
      StudyLog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
