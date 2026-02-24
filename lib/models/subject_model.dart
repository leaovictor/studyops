import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String userId;
  final String? goalId; // New field
  final String name;
  final String color; // hex string e.g. "#7C6FFF"
  final int priority; // 1–5
  final int weight; // 1–10
  final int difficulty; // 1-5

  const Subject({
    required this.id,
    required this.userId,
    this.goalId,
    required this.name,
    required this.color,
    required this.priority,
    required this.weight,
    required this.difficulty,
  });

  Subject copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? name,
    String? color,
    int? priority,
    int? weight,
    int? difficulty,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      name: name ?? this.name,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'name': name,
        'color': color,
        'priority': priority,
        'weight': weight,
        'difficulty': difficulty,
      };

  factory Subject.fromMap(String id, Map<String, dynamic> map) => Subject(
        id: id,
        userId: map['userId'] as String? ?? '',
        goalId: map['goalId'] as String?,
        name: map['name'] as String? ?? '',
        color: map['color'] as String? ?? '#7C6FFF',
        priority: (map['priority'] as num?)?.toInt() ?? 1,
        weight: (map['weight'] as num?)?.toInt() ?? 1,
        difficulty: (map['difficulty'] as num?)?.toInt() ?? 3,
      );

  factory Subject.fromDoc(DocumentSnapshot doc) =>
      Subject.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
