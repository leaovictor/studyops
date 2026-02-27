import 'dart:convert';
import 'package:crypto/crypto.dart';

class SharedQuestion {
  final String id;
  final String statement;
  final Map<String, String> options; // e.g., {"A": "Text", "B": "..."}
  final String correctAnswer;
  final String? subjectName;
  final String? source; // e.g., "Prova PRF 2021"
  final String textHash; // Used to prevent duplicates
  final bool isApproved;

  const SharedQuestion({
    required this.id,
    required this.statement,
    required this.options,
    required this.correctAnswer,
    this.subjectName,
    this.source,
    required this.textHash,
    this.isApproved = false,
  });

  static String generateHash(String statement, Map<String, String> options) {
    // Normalize text: lowercase and remove all whitespace
    final normalized = (statement + options.values.join())
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  Map<String, dynamic> toMap() => {
        'statement': statement,
        'options': options,
        'correctAnswer': correctAnswer,
        'subjectName': subjectName,
        'source': source,
        'textHash': textHash,
        'isApproved': isApproved,
      };

  factory SharedQuestion.fromMap(String id, Map<String, dynamic> map) => SharedQuestion(
        id: id,
        statement: map['statement'] ?? '',
        options: Map<String, String>.from(map['options'] ?? {}),
        correctAnswer: map['correctAnswer'] ?? '',
        subjectName: map['subjectName'],
        source: map['source'],
        textHash: map['textHash'] ?? '',
        isApproved: map['isApproved'] as bool? ?? false,
      );
}
