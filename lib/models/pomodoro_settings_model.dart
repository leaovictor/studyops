class PomodoroSettings {
  final String userId;
  final int workMinutes;
  final int breakMinutes;

  const PomodoroSettings({
    required this.userId,
    this.workMinutes = 25,
    this.breakMinutes = 5,
  });

  PomodoroSettings copyWith({
    String? userId,
    int? workMinutes,
    int? breakMinutes,
  }) =>
      PomodoroSettings(
        userId: userId ?? this.userId,
        workMinutes: workMinutes ?? this.workMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'workMinutes': workMinutes,
        'breakMinutes': breakMinutes,
      };

  factory PomodoroSettings.fromMap(Map<String, dynamic> map, String userId) =>
      PomodoroSettings(
        userId: userId,
        workMinutes: map['workMinutes'] ?? 25,
        breakMinutes: map['breakMinutes'] ?? 5,
      );

  factory PomodoroSettings.defaultFor(String userId) => PomodoroSettings(
        userId: userId,
        workMinutes: 25,
        breakMinutes: 5,
      );
}
