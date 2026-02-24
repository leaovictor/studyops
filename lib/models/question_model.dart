import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String text; // Markdown
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String subjectId;
  final String? goalId;
  final String banca;
  final int ano;
  final int difficulty; // 1-5
  final List<String> tags;
  final String ownerId; // "admin" or userId

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.subjectId,
    this.goalId,
    required this.banca,
    required this.ano,
    required this.difficulty,
    required this.tags,
    required this.ownerId,
  });

  bool get isOfficial => ownerId == 'admin';

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    String? subjectId,
    String? goalId,
    String? banca,
    int? ano,
    int? difficulty,
    List<String>? tags,
    String? ownerId,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      subjectId: subjectId ?? this.subjectId,
      goalId: goalId ?? this.goalId,
      banca: banca ?? this.banca,
      ano: ano ?? this.ano,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'subjectId': subjectId,
      'goalId': goalId,
      'banca': banca,
      'ano': ano,
      'difficulty': difficulty,
      'tags': tags,
      'ownerId': ownerId,
    };
  }

  factory Question.fromMap(String id, Map<String, dynamic> map) {
    return Question(
      id: id,
      text: map['text'] as String? ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      goalId: map['goalId'] as String?,
      banca: map['banca'] as String? ?? '',
      ano: (map['ano'] as num?)?.toInt() ?? 2024,
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      tags: List<String>.from(map['tags'] ?? []),
      ownerId: map['ownerId'] as String? ?? 'admin',
    );
  }

  factory Question.fromDoc(DocumentSnapshot doc) {
    return Question.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}
