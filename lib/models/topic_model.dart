import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String id;
  final String userId;
  final String subjectId;
  final String name;
  final int difficulty; // 1–5
  final bool isTheoryDone;
  final bool isReviewDone;
  final bool isExercisesDone;

  const Topic({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.name,
    required this.difficulty,
    this.isTheoryDone = false,
    this.isReviewDone = false,
    this.isExercisesDone = false,
  });

  Topic copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? name,
    int? difficulty,
    bool? isTheoryDone,
    bool? isReviewDone,
    bool? isExercisesDone,
  }) {
    return Topic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
      isTheoryDone: isTheoryDone ?? this.isTheoryDone,
      isReviewDone: isReviewDone ?? this.isReviewDone,
      isExercisesDone: isExercisesDone ?? this.isExercisesDone,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subjectId': subjectId,
        'name': name,
        'difficulty': difficulty,
        'isTheoryDone': isTheoryDone,
        'isReviewDone': isReviewDone,
        'isExercisesDone': isExercisesDone,
      };

  factory Topic.fromMap(String id, Map<String, dynamic> map) => Topic(
        id: id,
        userId: map['userId'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
        isTheoryDone: map['isTheoryDone'] as bool? ?? false,
        isReviewDone: map['isReviewDone'] as bool? ?? false,
        isExercisesDone: map['isExercisesDone'] as bool? ?? false,
      );

  factory Topic.fromDoc(DocumentSnapshot doc) =>
      Topic.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
