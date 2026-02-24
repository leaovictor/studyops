import 'package:cloud_firestore/cloud_firestore.dart';

class DailyTask {
  final String id;
  final String userId;
  final String goalId;
  final String date; // "yyyy-MM-dd"
  final String subjectId;
  final String topicId;
  final int plannedMinutes;
  final bool done;
  final int actualMinutes;

  const DailyTask({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.date,
    required this.subjectId,
    required this.topicId,
    required this.plannedMinutes,
    required this.done,
    required this.actualMinutes,
  });

  DailyTask copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? date,
    String? subjectId,
    String? topicId,
    int? plannedMinutes,
    bool? done,
    int? actualMinutes,
  }) {
    return DailyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      done: done ?? this.done,
      actualMinutes: actualMinutes ?? this.actualMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'date': date,
        'subjectId': subjectId,
        'topicId': topicId,
        'plannedMinutes': plannedMinutes,
        'done': done,
        'actualMinutes': actualMinutes,
      };

  factory DailyTask.fromMap(String id, Map<String, dynamic> map) => DailyTask(
        id: id,
        userId: map['userId'] as String? ?? '',
        goalId: map['goalId'] as String? ?? '',
        date: map['date'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        topicId: map['topicId'] as String? ?? '',
        plannedMinutes: (map['plannedMinutes'] as num?)?.toInt() ?? 60,
        done: map['done'] as bool? ?? false,
        actualMinutes: (map['actualMinutes'] as num?)?.toInt() ?? 0,
      );

  factory DailyTask.fromDoc(DocumentSnapshot doc) =>
      DailyTask.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
