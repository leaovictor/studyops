import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a daily study journal entry.
class StudyJournal {
  final String id; // date key e.g. "2026-03-01"
  final String userId;
  final String? goalId;
  final String date; // "YYYY-MM-DD"
  final int mood; // 1-5
  final String studiedToday; // what I studied
  final String struggled; // what I found hard
  final String tomorrowFocus; // what I'll tackle next
  final String? aiReflection; // AI-generated insight (optional)
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyJournal({
    required this.id,
    required this.userId,
    this.goalId,
    required this.date,
    required this.mood,
    required this.studiedToday,
    required this.struggled,
    required this.tomorrowFocus,
    this.aiReflection,
    required this.createdAt,
    required this.updatedAt,
  });

  StudyJournal copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? date,
    int? mood,
    String? studiedToday,
    String? struggled,
    String? tomorrowFocus,
    String? aiReflection,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      StudyJournal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        goalId: goalId ?? this.goalId,
        date: date ?? this.date,
        mood: mood ?? this.mood,
        studiedToday: studiedToday ?? this.studiedToday,
        struggled: struggled ?? this.struggled,
        tomorrowFocus: tomorrowFocus ?? this.tomorrowFocus,
        aiReflection: aiReflection ?? this.aiReflection,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'date': date,
        'mood': mood,
        'studiedToday': studiedToday,
        'struggled': struggled,
        'tomorrowFocus': tomorrowFocus,
        'aiReflection': aiReflection,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory StudyJournal.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      return DateTime.now();
    }

    return StudyJournal(
      id: id,
      userId: map['userId'] as String? ?? '',
      goalId: map['goalId'] as String?,
      date: map['date'] as String? ?? '',
      mood: (map['mood'] as num?)?.toInt() ?? 3,
      studiedToday: map['studiedToday'] as String? ?? '',
      struggled: map['struggled'] as String? ?? '',
      tomorrowFocus: map['tomorrowFocus'] as String? ?? '',
      aiReflection: map['aiReflection'] as String?,
      createdAt: toDate(map['createdAt']),
      updatedAt: toDate(map['updatedAt']),
    );
  }

  factory StudyJournal.fromDoc(DocumentSnapshot doc) =>
      StudyJournal.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  factory StudyJournal.empty(String userId, String date, String? goalId) =>
      StudyJournal(
        id: date,
        userId: userId,
        goalId: goalId,
        date: date,
        mood: 3,
        studiedToday: '',
        struggled: '',
        tomorrowFocus: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
