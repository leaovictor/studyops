import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_tokens.dart';
import '../core/design_system/typography_scale.dart';
import '../core/design_system/spacing_system.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/study_journal_model.dart';
import '../core/constants/app_constants.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _journalCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection(AppConstants.colStudyJournals);
});

/// Fetches the last 30 journal entries for the current user, newest first.
final journalEntriesProvider =
    FutureProvider.autoDispose<List<StudyJournal>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final col = ref.read(_journalCollectionProvider);
  final snap = await col
      .where('userId', isEqualTo: user.uid)
      .orderBy('date', descending: true)
      .limit(30)
      .get();

  return snap.docs.map((d) => StudyJournal.fromDoc(d)).toList();
});

// ─── Journal Service ──────────────────────────────────────────────────────────

class _JournalService {
  final CollectionReference _col;
  _JournalService(this._col);

  Future<StudyJournal?> getEntry(String userId, String dateKey) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dateKey)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return StudyJournal.fromDoc(snap.docs.first);
  }

  Future<void> save(StudyJournal entry) async {
    await _col.doc('${entry.userId}_${entry.date}').set(entry.toMap());
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  ConsumerState<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends ConsumerState<DailyJournalScreen> {
  // Today's entry state
  int _mood = 3;
  final _studiedCtrl = TextEditingController();
  final _struggledCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingToday = true;
  bool _savedToday = false;
  String? _aiReflection;
  bool _isGeneratingAI = false;

  late final _JournalService _service;
  late final String _todayKey;

  static const _moodLabels = ['Péssimo', 'Difícil', 'Ok', 'Bem', 'Excelente'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadToday());
  }

  @override
  void dispose() {
    _studiedCtrl.dispose();
    _struggledCtrl.dispose();
    _tomorrowCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _isLoadingToday = false);
      return;
    }
    final col = ref.read(_journalCollectionProvider);
    _service = _JournalService(col);

    final entry = await _service.getEntry(user.uid, _todayKey);
    if (mounted && entry != null) {
      setState(() {
        _mood = entry.mood;
        _studiedCtrl.text = entry.studiedToday;
        _struggledCtrl.text = entry.struggled;
        _tomorrowCtrl.text = entry.tomorrowFocus;
        _aiReflection = entry.aiReflection;
        _savedToday = true;
      });
    }
    if (mounted) setState(() => _isLoadingToday = false);
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final goals = ref.read(goalsProvider).valueOrNull ?? [];
      final activeGoalId = ref.read(activeGoalIdProvider);
      final goal = goals.cast<dynamic>().firstWhere(
            (g) => g.id == activeGoalId,
            orElse: () => null,
          );

      final entry = StudyJournal(
        id: '${user.uid}_$_todayKey',
        userId: user.uid,
        goalId: goal?.id,
        date: _todayKey,
        mood: _mood,
        studiedToday: _studiedCtrl.text.trim(),
        struggled: _struggledCtrl.text.trim(),
        tomorrowFocus: _tomorrowCtrl.text.trim(),
        aiReflection: _aiReflection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _service.save(entry);
      ref.invalidate(journalEntriesProvider);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _savedToday = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reflexão salva!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  Future<void> _generateAIReflection() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isGeneratingAI = true);
    try {
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception('IA não configurada');

      final goals = ref.read(goalsProvider).valueOrNull ?? [];
      final activeGoalId = ref.read(activeGoalIdProvider);
      final goalName = goals
              .cast<dynamic>()
              .firstWhere((g) => g.id == activeGoalId, orElse: () => null)
              ?.name ??
          'Concurso Público';

      final moodLabel = _moodLabels[_mood - 1];
      final studied = _studiedCtrl.text.trim();
      final struggled = _struggledCtrl.text.trim();
      final tomorrow = _tomorrowCtrl.text.trim();

      final prompt =
          'O aluno registrou sua reflexão de hoje para o objetivo "$goalName".\n\n'
          'Humor: $moodLabel\n'
          'O que estudei: ${studied.isEmpty ? "(não preenchido)" : studied}\n'
          'O que foi difícil: ${struggled.isEmpty ? "(não preenchido)" : struggled}\n'
          'Foco de amanhã: ${tomorrow.isEmpty ? "(não preenchido)" : tomorrow}\n\n'
          'Com base nessa reflexão, escreva um comentário curto (máximo 2 frases) como um mentor empático e motivador. '
          'Elogie o esforço, reconheça a dificuldade se houver, e dê um conselho prático concreto para amanhã. '
          'Fale em Português do Brasil. Seja genuíno, não genérico.';

      final reply = await aiService.mentorChat(
        userId: user.uid,
        history: [
          {'role': 'user', 'content': prompt}
        ],
        objective: goalName,
      );

      if (mounted) {
        setState(() {
          _aiReflection = reply;
          _isGeneratingAI = false;
        });
        // Auto-save with the AI reflection
        await _save();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro IA: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(journalEntriesProvider);

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBg1 : DesignTokens.lightBg1,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '📓 Reflexão Diária',
          style: AppTypography.headingSm.copyWith(
            color: isDark
                ? DesignTokens.darkTextPrimary
                : DesignTokens.lightTextPrimary,
          ),
        ),
      ),
      body: _isLoadingToday
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg, vertical: Spacing.md),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 350),
                    childAnimationBuilder: (w) => SlideAnimation(
                      verticalOffset: 20,
                      child: FadeInAnimation(child: w),
                    ),
                    children: [
                      // ── Today's entry card ─────────────────────────────
                      _TodayCard(
                        isDark: isDark,
                        mood: _mood,
                        onMoodChanged: (m) => setState(() => _mood = m),
                        studiedCtrl: _studiedCtrl,
                        struggledCtrl: _struggledCtrl,
                        tomorrowCtrl: _tomorrowCtrl,
                        isSaving: _isSaving,
                        savedToday: _savedToday,
                        aiReflection: _aiReflection,
                        isGeneratingAI: _isGeneratingAI,
                        onSave: _save,
                        onGenerateAI: _generateAIReflection,
                      ),
                      const SizedBox(height: Spacing.xl),

                      // ── Timeline header ────────────────────────────────
                      Text(
                        'Histórico de Reflexões',
                        style: AppTypography.labelMd.copyWith(
                          color: isDark
                              ? DesignTokens.darkTextPrimary
                              : DesignTokens.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),

                      // ── Timeline entries ───────────────────────────────
                      entriesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erro: $e'),
                        data: (entries) {
                          // Filter out today (shown in card above)
                          final past = entries
                              .where((e) => e.date != _todayKey)
                              .toList();
                          if (past.isEmpty) {
                            return _EmptyTimeline(isDark: isDark);
                          }
                          return Column(
                            children: past.asMap().entries.map((entry) {
                              return _JournalTile(
                                journal: entry.value,
                                isDark: isDark,
                                isLast: entry.key == past.length - 1,
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: Spacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ─── Today's Card ─────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.isDark,
    required this.mood,
    required this.onMoodChanged,
    required this.studiedCtrl,
    required this.struggledCtrl,
    required this.tomorrowCtrl,
    required this.isSaving,
    required this.savedToday,
    required this.aiReflection,
    required this.isGeneratingAI,
    required this.onSave,
    required this.onGenerateAI,
  });

  final bool isDark;
  final int mood;
  final void Function(int) onMoodChanged;
  final TextEditingController studiedCtrl;
  final TextEditingController struggledCtrl;
  final TextEditingController tomorrowCtrl;
  final bool isSaving;
  final bool savedToday;
  final String? aiReflection;
  final bool isGeneratingAI;
  final VoidCallback onSave;
  final VoidCallback onGenerateAI;

  static const _moods = ['😞', '😕', '😐', '🙂', '😄'];
  static const _moodLabels = ['Péssimo', 'Difícil', 'Ok', 'Bem', 'Excelente'];
  static const _moodColors = [
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFB300),
    Color(0xFF43A047),
    Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final moodColor = _moodColors[mood - 1];

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
        borderRadius: DesignTokens.brLg,
        boxShadow: DesignTokens.elevationLow,
        border: savedToday
            ? Border.all(color: DesignTokens.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: DesignTokens.brSm,
                ),
                child: Text(
                  'HOJE · $dateStr',
                  style: AppTypography.overline.copyWith(
                    color: DesignTokens.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (savedToday) ...[
                const SizedBox(width: Spacing.xs),
                const Icon(Icons.check_circle_rounded,
                    color: DesignTokens.primary, size: 14),
              ]
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Mood picker
          Text(
            'Como foi seu dia de hoje?',
            style: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: List.generate(5, (i) {
              final isSelected = mood == i + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onMoodChanged(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _moodColors[i].withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: DesignTokens.brMd,
                      border: Border.all(
                        color: isSelected
                            ? _moodColors[i]
                            : (isDark
                                ? DesignTokens.darkBg3
                                : const Color(0xFFDDE3EC)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(_moods[i],
                            style: TextStyle(fontSize: isSelected ? 26 : 22)),
                        const SizedBox(height: 2),
                        Text(
                          _moodLabels[i],
                          style: AppTypography.overline.copyWith(
                            fontSize: 8,
                            color: isSelected
                                ? _moodColors[i]
                                : (isDark
                                    ? DesignTokens.darkTextMuted
                                    : DesignTokens.lightTextMuted),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.lg),

          // Reflection fields
          _ReflectionField(
            icon: Icons.book_rounded,
            color: DesignTokens.primary,
            label: 'O que estudei hoje?',
            hint: 'Ex: Direito Constitucional — Princípios fundamentais',
            controller: studiedCtrl,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.md),
          _ReflectionField(
            icon: Icons.psychology_rounded,
            color: DesignTokens.warning,
            label: 'O que achei difícil?',
            hint: 'Ex: Fiquei confuso com o art. 5° e suas incisos',
            controller: struggledCtrl,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.md),
          _ReflectionField(
            icon: Icons.arrow_forward_rounded,
            color: DesignTokens.secondary,
            label: 'Foco de amanhã',
            hint: 'Ex: Continuar revisão de Administrativo + simulado',
            controller: tomorrowCtrl,
            isDark: isDark,
          ),
          const SizedBox(height: Spacing.lg),

          // AI Reflection block (if exists)
          if (aiReflection != null) ...[
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.primary.withValues(alpha: 0.08),
                    DesignTokens.secondary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: DesignTokens.brMd,
                border: Border.all(
                    color: DesignTokens.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_rounded,
                          color: DesignTokens.primary, size: 14),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        'REFLEXÃO DO MENTOR',
                        style: AppTypography.overline.copyWith(
                          color: DesignTokens.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    aiReflection!,
                    style: AppTypography.bodySm.copyWith(
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.lightTextPrimary,
                      height: 1.6,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(savedToday ? 'Atualizar' : 'Salvar Reflexão'),
                  style: FilledButton.styleFrom(
                    backgroundColor: moodColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              OutlinedButton.icon(
                onPressed: isGeneratingAI ? null : onGenerateAI,
                icon: isGeneratingAI
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded, size: 14),
                label: const Text('Insight IA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.primary,
                  side: const BorderSide(color: DesignTokens.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reflection Field ─────────────────────────────────────────────────────────

class _ReflectionField extends StatelessWidget {
  const _ReflectionField({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
    required this.controller,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: Spacing.xs),
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.lightTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          style: AppTypography.bodySm.copyWith(
            color: isDark
                ? DesignTokens.darkTextPrimary
                : DesignTokens.lightTextPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySm.copyWith(
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
              fontSize: 12,
            ),
            filled: true,
            fillColor: isDark ? DesignTokens.darkBg3 : DesignTokens.lightBg1,
            border: OutlineInputBorder(
              borderRadius: DesignTokens.brMd,
              borderSide: BorderSide(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignTokens.brMd,
              borderSide: BorderSide(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignTokens.brMd,
              borderSide: BorderSide(color: color),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
          ),
        ),
      ],
    );
  }
}

// ─── Journal Timeline Tile ────────────────────────────────────────────────────

class _JournalTile extends StatelessWidget {
  const _JournalTile({
    required this.journal,
    required this.isDark,
    required this.isLast,
  });
  final StudyJournal journal;
  final bool isDark;
  final bool isLast;

  static const _moods = ['😞', '😕', '😐', '🙂', '😄'];
  static const _moodColors = [
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFB300),
    Color(0xFF43A047),
    Color(0xFF00ACC1),
  ];

  String _formatDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final moodIndex = (journal.mood - 1).clamp(0, 4);
    final moodColor = _moodColors[moodIndex];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: moodColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: moodColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: (isDark
                              ? DesignTokens.darkBg3
                              : const Color(0xFFDDE3EC))
                          .withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(left: Spacing.sm, bottom: Spacing.md),
              child: Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: isDark ? DesignTokens.darkBg2 : DesignTokens.lightBg2,
                  borderRadius: DesignTokens.brMd,
                  boxShadow: DesignTokens.elevationLow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + mood
                    Row(
                      children: [
                        Text(
                          _formatDate(journal.date),
                          style: AppTypography.overline.copyWith(
                            color: isDark
                                ? DesignTokens.darkTextMuted
                                : DesignTokens.lightTextMuted,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Text(_moods[moodIndex],
                            style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                    if (journal.studiedToday.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      _TileRow(
                        icon: Icons.book_rounded,
                        color: DesignTokens.primary,
                        text: journal.studiedToday,
                        isDark: isDark,
                      ),
                    ],
                    if (journal.struggled.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _TileRow(
                        icon: Icons.psychology_rounded,
                        color: DesignTokens.warning,
                        text: journal.struggled,
                        isDark: isDark,
                      ),
                    ],
                    if (journal.tomorrowFocus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _TileRow(
                        icon: Icons.arrow_forward_rounded,
                        color: DesignTokens.secondary,
                        text: journal.tomorrowFocus,
                        isDark: isDark,
                      ),
                    ],
                    if (journal.aiReflection != null &&
                        journal.aiReflection!.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Container(
                        padding: const EdgeInsets.all(Spacing.sm),
                        decoration: BoxDecoration(
                          color: DesignTokens.primary.withValues(alpha: 0.06),
                          borderRadius: DesignTokens.brSm,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.psychology_rounded,
                                color: DesignTokens.primary, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                journal.aiReflection!,
                                style: AppTypography.overline.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? DesignTokens.darkTextSecondary
                                      : DesignTokens.lightTextSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.lightTextPrimary,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Empty Timeline ───────────────────────────────────────────────────────────

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 40,
              color: isDark
                  ? DesignTokens.darkTextMuted
                  : DesignTokens.lightTextMuted,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Nenhuma reflexão anterior',
              style: AppTypography.bodySm.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
              ),
            ),
            Text(
              'Comece hoje e construa seu diário! 📖',
              style: AppTypography.overline.copyWith(
                color: isDark
                    ? DesignTokens.darkTextMuted
                    : DesignTokens.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
