import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ErrorNote {
  final String id;
  final String userId;
  final String? goalId; // New field
  final String subjectId;
  final String topicId;
  final String question;
  final String correctAnswer;
  final String errorReason;
  final DateTime nextReview;
  final int reviewStage; // 0–4 maps to spacedRepetitionIntervals

  const ErrorNote({
    required this.id,
    required this.userId,
    this.goalId,
    required this.subjectId,
    required this.topicId,
    required this.question,
    required this.correctAnswer,
    required this.errorReason,
    required this.nextReview,
    required this.reviewStage,
  });

  bool get isDueToday {
    final today = DateTime.now();
    return nextReview
        .isBefore(DateTime(today.year, today.month, today.day + 1));
  }

  /// Advance to the next review stage, returns updated copy
  ErrorNote advance() {
    final next = reviewStage < AppConstants.spacedRepetitionIntervals.length - 1
        ? reviewStage + 1
        : reviewStage;
    final intervalDays = AppConstants.spacedRepetitionIntervals[next];
    return copyWith(
      reviewStage: next,
      nextReview: DateTime.now().add(Duration(days: intervalDays)),
    );
  }

  ErrorNote copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? subjectId,
    String? topicId,
    String? question,
    String? correctAnswer,
    String? errorReason,
    DateTime? nextReview,
    int? reviewStage,
  }) {
    return ErrorNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      question: question ?? this.question,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      errorReason: errorReason ?? this.errorReason,
      nextReview: nextReview ?? this.nextReview,
      reviewStage: reviewStage ?? this.reviewStage,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'subjectId': subjectId,
        'topicId': topicId,
        'question': question,
        'correctAnswer': correctAnswer,
        'errorReason': errorReason,
        'nextReview': Timestamp.fromDate(nextReview),
        'reviewStage': reviewStage,
      };

  factory ErrorNote.fromMap(String id, Map<String, dynamic> map) {
    DateTime nextReview;
    final raw = map['nextReview'];
    if (raw is Timestamp) {
      nextReview = raw.toDate();
    } else {
      nextReview = DateTime.now().add(const Duration(days: 1));
    }
    return ErrorNote(
      id: id,
      userId: map['userId'] as String? ?? '',
      goalId: map['goalId'] as String?,
      subjectId: map['subjectId'] as String? ?? '',
      topicId: map['topicId'] as String? ?? '',
      question: map['question'] as String? ?? '',
      correctAnswer: map['correctAnswer'] as String? ?? '',
      errorReason: map['errorReason'] as String? ?? '',
      nextReview: nextReview,
      reviewStage: (map['reviewStage'] as num?)?.toInt() ?? 0,
    );
  }

  factory ErrorNote.fromDoc(DocumentSnapshot doc) =>
      ErrorNote.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
