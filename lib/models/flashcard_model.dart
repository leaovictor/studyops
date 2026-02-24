import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String id;
  final String userId;
  final String? goalId; // New field
  final String subjectId;
  final String topicId;
  final String front;
  final String back;

  /// Serialized FSRS Card state (Card.toMap()) — persists the algorithm internals.
  final Map<String, dynamic> fsrsCard;

  /// Next review date, mirrors card.due from FSRS.
  final DateTime due;
  final DateTime createdAt;

  const Flashcard({
    required this.id,
    required this.userId,
    this.goalId,
    required this.subjectId,
    required this.topicId,
    required this.front,
    required this.back,
    required this.fsrsCard,
    required this.due,
    required this.createdAt,
  });

  bool get isDueToday {
    final now = DateTime.now();
    return due.isBefore(DateTime(now.year, now.month, now.day + 1));
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? subjectId,
    String? topicId,
    String? front,
    String? back,
    Map<String, dynamic>? fsrsCard,
    DateTime? due,
    DateTime? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      front: front ?? this.front,
      back: back ?? this.back,
      fsrsCard: fsrsCard ?? this.fsrsCard,
      due: due ?? this.due,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'subjectId': subjectId,
        'topicId': topicId,
        'front': front,
        'back': back,
        'fsrsCard': fsrsCard,
        'due': Timestamp.fromDate(due),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Flashcard.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }

    return Flashcard(
      id: id,
      userId: map['userId'] as String? ?? '',
      goalId: map['goalId'] as String?,
      subjectId: map['subjectId'] as String? ?? '',
      topicId: map['topicId'] as String? ?? '',
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
      fsrsCard: (map['fsrsCard'] as Map<String, dynamic>?) ?? {},
      due: parseDate(map['due']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory Flashcard.fromDoc(DocumentSnapshot doc) =>
      Flashcard.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
