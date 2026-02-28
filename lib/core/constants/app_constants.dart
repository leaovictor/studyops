class AppConstants {
  AppConstants._();

  // Firestore Collections
  static const String colSubjects = 'subjects';
  static const String colTopics = 'topics';
  static const String colStudyPlans = 'study_plans';
  static const String colDailyTasks = 'daily_tasks';
  static const String colStudyLogs = 'study_logs';
  static const String colErrorNotebook = 'error_notebook';
  static const String colFlashcards = 'flashcards';
  static const String colGoals = 'goals';
  static const String colQuestionLogs = 'question_logs';
  static const String colSharedQuestions = 'shared_questions';
  static const String colUsage = 'usage';
  static const String colConfigs = 'configs';
  static const String colUsers = 'users';

  // Plan durations
  static const List<int> planDurations = [30, 60, 90];

  // Spaced repetition intervals (days)
  static const List<int> spacedRepetitionIntervals = [1, 3, 7, 15, 30];

  // Pomodoro defaults (minutes)
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;

  // Priority levels
  static const List<String> priorityLabels = [
    'Baixa',
    'Média',
    'Alta',
    'Muito Alta',
    'Crítica'
  ];

  // Difficulty labels
  static const List<String> difficultyLabels = [
    'Muito Fácil',
    'Fácil',
    'Médio',
    'Difícil',
    'Muito Difícil'
  ];

  // Default subject colors (hex strings)
  static const List<String> defaultSubjectColors = [
    '#7C6FFF', // Indigo
    '#06B6D4', // Cyan
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#EC4899', // Pink
    '#8B5CF6', // Violet
    '#14B8A6', // Teal
    '#F97316', // Orange
    '#6366F1', // Indigo alt
  ];
}
