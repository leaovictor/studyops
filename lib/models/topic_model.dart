import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String id;
  final String userId;
  final String subjectId;
  final String name;
  final int difficulty; // 1–5

  const Topic({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.name,
    required this.difficulty,
  });

  Topic copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? name,
    int? difficulty,
  }) {
    return Topic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subjectId': subjectId,
        'name': name,
        'difficulty': difficulty,
      };

  factory Topic.fromMap(String id, Map<String, dynamic> map) => Topic(
        id: id,
        userId: map['userId'] as String? ?? '',
        subjectId: map['subjectId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      );

  factory Topic.fromDoc(DocumentSnapshot doc) =>
      Topic.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
