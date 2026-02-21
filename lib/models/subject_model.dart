import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String userId;
  final String name;
  final String color; // hex string e.g. "#7C6FFF"
  final int priority; // 1–5
  final int weight; // 1–10

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.priority,
    required this.weight,
  });

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    int? priority,
    int? weight,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'color': color,
        'priority': priority,
        'weight': weight,
      };

  factory Subject.fromMap(String id, Map<String, dynamic> map) => Subject(
        id: id,
        userId: map['userId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        color: map['color'] as String? ?? '#7C6FFF',
        priority: (map['priority'] as num?)?.toInt() ?? 1,
        weight: (map['weight'] as num?)?.toInt() ?? 1,
      );

  factory Subject.fromDoc(DocumentSnapshot doc) =>
      Subject.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
