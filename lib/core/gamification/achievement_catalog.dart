import 'package:flutter/material.dart';

/// Unique ID for every achievement in the catalog.
enum AchievementId {
  // Streak milestones
  streak3,
  streak7,
  streak14,
  streak30,

  // Study volume milestones
  firstSession,
  tenHours,
  fiftyHours,
  hundredHours,

  // Quiz performance
  firstQuiz,
  accuracy80,
  accuracy90,
  questionsHundred,

  // Syllabus coverage
  firstTopicDone,
  tenTopicsDone,
  halfSyllabus,
  fullSyllabus,

  // Flashcards
  firstFlashcard,
  flashcardsHundred,

  // Level milestones
  level5,
  level10,
  level25,

  // Consistency
  sevenDayConsistency,
  thirtyDayConsistency,

  // Score milestones
  score500,
  score800,
  score1000,
}

/// A single achievement definition.
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpReward,
    this.rarity = AchievementRarity.common,
  });

  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int xpReward;
  final AchievementRarity rarity;
}

enum AchievementRarity { common, rare, epic, legendary }

/// Full catalog of all achievements.
abstract final class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDef> all = [
    // ─── Streak ──────────────────────────────────────────────
    AchievementDef(
      id: AchievementId.streak3,
      title: 'Consistente',
      description: 'Estudou 3 dias seguidos.',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF6B35),
      xpReward: 50,
    ),
    AchievementDef(
      id: AchievementId.streak7,
      title: 'Uma Semana Sólida',
      description: 'Manteve 7 dias de streak.',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF6B35),
      xpReward: 150,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.streak14,
      title: 'Quinze Dias de Fogo',
      description: 'Manteve 14 dias de streak.',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFFF4500),
      xpReward: 300,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.streak30,
      title: 'Mês Épico',
      description: '30 dias de streak consecutivos.',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFD700),
      xpReward: 750,
      rarity: AchievementRarity.epic,
    ),

    // ─── Study Volume ─────────────────────────────────────────
    AchievementDef(
      id: AchievementId.firstSession,
      title: 'Primeiro Passo',
      description: 'Registrou sua primeira sessão de estudo.',
      icon: Icons.play_circle_rounded,
      color: Color(0xFF7C6FFF),
      xpReward: 25,
    ),
    AchievementDef(
      id: AchievementId.tenHours,
      title: '10 Horas de Dedicação',
      description: 'Acumulou 10 horas de estudo.',
      icon: Icons.timer_rounded,
      color: Color(0xFF7C6FFF),
      xpReward: 100,
    ),
    AchievementDef(
      id: AchievementId.fiftyHours,
      title: 'Meio Centenário',
      description: 'Acumulou 50 horas de estudo.',
      icon: Icons.timer_rounded,
      color: Color(0xFF00D9AA),
      xpReward: 300,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.hundredHours,
      title: 'Centurião',
      description: '100 horas de estudo registradas!',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFFFD700),
      xpReward: 750,
      rarity: AchievementRarity.epic,
    ),

    // ─── Quiz Performance ─────────────────────────────────────
    AchievementDef(
      id: AchievementId.firstQuiz,
      title: 'Primeira Questão',
      description: 'Respondeu sua primeira questão.',
      icon: Icons.quiz_rounded,
      color: Color(0xFF00B4D8),
      xpReward: 25,
    ),
    AchievementDef(
      id: AchievementId.accuracy80,
      title: 'Precisão 80%',
      description: 'Atingiu 80% de acerto geral.',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFF00D9AA),
      xpReward: 200,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.accuracy90,
      title: 'Atirador de Elite',
      description: 'Atingiu 90% de acerto geral.',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFFFFD700),
      xpReward: 500,
      rarity: AchievementRarity.epic,
    ),
    AchievementDef(
      id: AchievementId.questionsHundred,
      title: 'Centenário das Questões',
      description: 'Respondeu 100 questões.',
      icon: Icons.format_list_numbered_rounded,
      color: Color(0xFF00B4D8),
      xpReward: 150,
    ),

    // ─── Syllabus Coverage ────────────────────────────────────
    AchievementDef(
      id: AchievementId.firstTopicDone,
      title: 'Tópico Completo',
      description: 'Completou teoria + revisão + exercícios de um tópico.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF00D9AA),
      xpReward: 50,
    ),
    AchievementDef(
      id: AchievementId.tenTopicsDone,
      title: 'Dez Tópicos',
      description: 'Completou 10 tópicos do edital.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF00D9AA),
      xpReward: 200,
    ),
    AchievementDef(
      id: AchievementId.halfSyllabus,
      title: 'Meio Edital',
      description: 'Completou 50% do edital.',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF7C6FFF),
      xpReward: 400,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.fullSyllabus,
      title: 'Edital Concluído',
      description: 'Completou 100% do edital! Lenda.',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFFFD700),
      xpReward: 1000,
      rarity: AchievementRarity.legendary,
    ),

    // ─── Flashcards ──────────────────────────────────────────
    AchievementDef(
      id: AchievementId.firstFlashcard,
      title: 'Primeiro Flashcard',
      description: 'Revisou seu primeiro flashcard.',
      icon: Icons.style_rounded,
      color: Color(0xFFFF6B9D),
      xpReward: 25,
    ),
    AchievementDef(
      id: AchievementId.flashcardsHundred,
      title: '100 Flashcards',
      description: 'Revisou 100 flashcards.',
      icon: Icons.style_rounded,
      color: Color(0xFFFF6B9D),
      xpReward: 200,
    ),

    // ─── Level Milestones ─────────────────────────────────────
    AchievementDef(
      id: AchievementId.level5,
      title: 'Nível 5',
      description: 'Chegou ao nível 5.',
      icon: Icons.star_rounded,
      color: Color(0xFFFFD700),
      xpReward: 0, // XP awarded separately by level-up
    ),
    AchievementDef(
      id: AchievementId.level10,
      title: 'Nível 10',
      description: 'Chegou ao nível 10. Impressionante!',
      icon: Icons.star_rounded,
      color: Color(0xFFFFD700),
      xpReward: 0,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.level25,
      title: 'Nível 25 — Elite',
      description: 'Top 5% dos estudantes. Você é Elite.',
      icon: Icons.diamond_rounded,
      color: Color(0xFFB5B9FF),
      xpReward: 0,
      rarity: AchievementRarity.epic,
    ),

    // ─── Consistency ─────────────────────────────────────────
    AchievementDef(
      id: AchievementId.sevenDayConsistency,
      title: 'Semana Perfeita',
      description: 'Estudou todos os 7 dias de uma semana.',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF7C6FFF),
      xpReward: 100,
    ),
    AchievementDef(
      id: AchievementId.thirtyDayConsistency,
      title: 'Mês Consistente',
      description: 'Estudou em 25+ dias em um único mês.',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFFFD700),
      xpReward: 500,
      rarity: AchievementRarity.epic,
    ),

    // ─── Study Score ──────────────────────────────────────────
    AchievementDef(
      id: AchievementId.score500,
      title: 'Score 500',
      description: 'Atingiu 500 pontos no Study Score.',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF7C6FFF),
      xpReward: 100,
    ),
    AchievementDef(
      id: AchievementId.score800,
      title: 'Score 800',
      description: 'Atingiu 800 pontos no Study Score.',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF00D9AA),
      xpReward: 300,
      rarity: AchievementRarity.rare,
    ),
    AchievementDef(
      id: AchievementId.score1000,
      title: 'Score Perfeito',
      description: '1000 pontos! Você é uma lenda.',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFD700),
      xpReward: 750,
      rarity: AchievementRarity.legendary,
    ),
  ];

  static AchievementDef? byId(AchievementId id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
