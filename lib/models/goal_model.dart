import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Goal.fromMap(String id, Map<String, dynamic> map) => Goal(
        id: id,
        userId: map['userId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory Goal.fromDoc(DocumentSnapshot doc) =>
      Goal.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
