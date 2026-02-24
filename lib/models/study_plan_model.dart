import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPlan {
  final String id;
  final String userId;
  final String goalId;
  final DateTime startDate;
  final int durationDays; // 30, 60, or 90
  final double dailyHours;

  const StudyPlan({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.startDate,
    required this.durationDays,
    required this.dailyHours,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays - 1));

  StudyPlan copyWith({
    String? id,
    String? userId,
    String? goalId,
    DateTime? startDate,
    int? durationDays,
    double? dailyHours,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      dailyHours: dailyHours ?? this.dailyHours,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'goalId': goalId,
        'startDate': Timestamp.fromDate(startDate),
        'durationDays': durationDays,
        'dailyHours': dailyHours,
      };

  factory StudyPlan.fromMap(String id, Map<String, dynamic> map) {
    DateTime start;
    final raw = map['startDate'];
    if (raw is Timestamp) {
      start = raw.toDate();
    } else if (raw is String) {
      start = DateTime.parse(raw);
    } else {
      start = DateTime.now();
    }

    return StudyPlan(
      id: id,
      userId: map['userId'] as String? ?? '',
      goalId: map['goalId'] as String? ?? '',
      startDate: start,
      durationDays: (map['durationDays'] as num?)?.toInt() ?? 30,
      dailyHours: (map['dailyHours'] as num?)?.toDouble() ?? 3.0,
    );
  }

  factory StudyPlan.fromDoc(DocumentSnapshot doc) =>
      StudyPlan.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}
