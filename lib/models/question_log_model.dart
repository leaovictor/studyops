import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionLog {
  final String id;
  final String userId;
  final String subjectId;
  final String? topicId;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime date;

  const QuestionLog({
    required this.id,
    required this.userId,
    required this.subjectId,
    this.topicId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.date,
  });

  double get accuracy => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subjectId': subjectId,
        'topicId': topicId,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'date': Timestamp.fromDate(date),
      };

  factory QuestionLog.fromMap(String id, Map<String, dynamic> map) => QuestionLog(
        id: id,
        userId: map['userId'] ?? '',
        subjectId: map['subjectId'] ?? '',
        topicId: map['topicId'],
        totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
        correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
        date: (map['date'] as Timestamp).toDate(),
      );
}
