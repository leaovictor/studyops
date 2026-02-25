import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/error_notebook_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../models/error_note_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../core/constants/app_constants.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ErrorNotebookScreen extends ConsumerStatefulWidget {
  const ErrorNotebookScreen({super.key});

  @override
  ConsumerState<ErrorNotebookScreen> createState() =>
      _ErrorNotebookScreenState();
}

class _ErrorNotebookScreenState extends ConsumerState<ErrorNotebookScreen> {
  bool _showDueOnly = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(errorNotesProvider);
    ref.invalidate(dueTodayNotesProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(allTopicsProvider);
    try {
      await ref.read(errorNotesProvider.future);
    } catch (_) {}
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(errorNotesProvider);
    final dueAsync = ref.watch(dueTodayNotesProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];
    final subjectMap = {for (final s in subjects) s.id: s};
    final topicMap = {for (final t in allTopics) t.id: t};

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context, null, subjects, allTopics),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Erro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Caderno de Erros',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Revisão espaçada inteligente',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Due today badge
                dueAsync.when(
                  data: (due) => due.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${due.length} p/ revisão',
                            style: const TextStyle(
                                color: AppTheme.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter chip
            Row(
              children: [
                FilterChip(
                  label: const Text('Somente revisões de hoje'),
                  selected: _showDueOnly,
                  onSelected: (v) => setState(() => _showDueOnly = v),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // List
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                header: const WaterDropMaterialHeader(
                  backgroundColor: AppTheme.primary,
                ),
                child: notesAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.primary))),
                  error: (e, _) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(child: Text('Erro: $e'))),
                  data: (notes) {
                    final filtered = _showDueOnly
                        ? notes.where((n) => n.isDueToday).toList()
                        : notes;

                    if (filtered.isEmpty) {
                      return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _EmptyNotes(showDueOnly: _showDueOnly));
                    }

                    return AnimationLimiter(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final note = filtered[i];
                          final subject = subjectMap[note.subjectId];
                          final topic = topicMap[note.topicId];
                          return AnimationConfiguration.staggeredList(
                            position: i,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _NoteCard(
                                  key: ValueKey(note.id),
                                  note: note,
                                  subject: subject,
                                  topicName: topic?.name ?? 'Tópico',
                                  onMarkReviewed: () => ref
                                      .read(errorNotebookControllerProvider
                                          .notifier)
                                      .markReviewed(note),
                                  onEdit: () => _showNoteDialog(
                                      context, note, subjects, allTopics),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Excluir Erro'),
                                        content: const Text(
                                            'Tem certeza que deseja excluir este erro?\nEsta ação não pode ser desfeita.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppTheme.error,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Excluir'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      ref
                                          .read(errorNotebookControllerProvider
                                              .notifier)
                                          .deleteNote(note.id);
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNoteDialog(
    BuildContext context,
    ErrorNote? existing,
    List<Subject> subjects,
    List<Topic> allTopics,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final activeGoalId = ref.read(activeGoalIdProvider);
    if (user == null || subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastre matérias primeiro')));
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _NoteDialogContent(
        existing: existing,
        subjects: subjects,
        allTopics: allTopics,
        activeGoalId: activeGoalId,
        userId: user.uid,
      ),
    );
  }
}

class _NoteDialogContent extends StatefulWidget {
  final ErrorNote? existing;
  final List<Subject> subjects;
  final List<Topic> allTopics;
  final String? activeGoalId;
  final String userId;

  const _NoteDialogContent({
    required this.existing,
    required this.subjects,
    required this.allTopics,
    required this.activeGoalId,
    required this.userId,
  });

  @override
  State<_NoteDialogContent> createState() => _NoteDialogContentState();
}

class _NoteDialogContentState extends State<_NoteDialogContent> {
  late TextEditingController questionCtrl;
  late TextEditingController answerCtrl;
  late TextEditingController reasonCtrl;
  Subject? selectedSubject;
  Topic? selectedTopic;

  @override
  void initState() {
    super.initState();
    questionCtrl = TextEditingController(text: widget.existing?.question ?? '');
    answerCtrl =
        TextEditingController(text: widget.existing?.correctAnswer ?? '');
    reasonCtrl =
        TextEditingController(text: widget.existing?.errorReason ?? '');

    selectedSubject = widget.subjects.firstWhere(
      (s) => s.id == (widget.existing?.subjectId ?? widget.subjects.first.id),
      orElse: () => widget.subjects.first,
    );
  }

  @override
  void dispose() {
    questionCtrl.dispose();
    answerCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTopics = widget.allTopics
        .where((t) => t.subjectId == selectedSubject?.id)
        .toList();

    if (selectedTopic == null &&
        filteredTopics.isNotEmpty &&
        widget.existing == null) {
      selectedTopic = filteredTopics.first;
    } else if (widget.existing != null && selectedTopic == null) {
      // Use iterable.where and firstOrNull if possible, or manual loop for safety
      for (final t in filteredTopics) {
        if (t.id == widget.existing!.topicId) {
          selectedTopic = t;
          break;
        }
      }
      if (selectedTopic == null && filteredTopics.isNotEmpty) {
        selectedTopic = filteredTopics.first;
      }
    }

    return Consumer(builder: (context, ref, child) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Novo Erro' : 'Editar Erro',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Subject>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: widget.subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (s) => setState(() {
                  selectedSubject = s;
                  selectedTopic = null;
                }),
              ),
              const SizedBox(height: 12),
              if (filteredTopics.isNotEmpty)
                DropdownButtonFormField<Topic>(
                  initialValue: selectedTopic,
                  decoration: const InputDecoration(labelText: 'Tópico'),
                  items: filteredTopics
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (t) => setState(() => selectedTopic = t),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: questionCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Questão / Enunciado'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Resposta correta'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Por que errei?'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (selectedSubject == null) return;
                  final note = ErrorNote(
                    id: widget.existing?.id ?? const Uuid().v4(),
                    userId: widget.userId,
                    goalId: widget.existing?.goalId ?? widget.activeGoalId,
                    subjectId: selectedSubject!.id,
                    topicId: selectedTopic?.id ?? '',
                    question: questionCtrl.text,
                    correctAnswer: answerCtrl.text,
                    errorReason: reasonCtrl.text,
                    nextReview: widget.existing?.nextReview ??
                        DateTime.now().add(const Duration(days: 1)),
                    reviewStage: widget.existing?.reviewStage ?? 0,
                  );
                  if (widget.existing == null) {
                    ref
                        .read(errorNotebookControllerProvider.notifier)
                        .createNote(note);
                  } else {
                    ref
                        .read(errorNotebookControllerProvider.notifier)
                        .updateNote(note);
                  }
                  Navigator.pop(context);
                },
                child:
                    Text(widget.existing == null ? 'Salvar Erro' : 'Atualizar'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _NoteCard extends StatelessWidget {
  final ErrorNote note;
  final Subject? subject;
  final String topicName;
  final VoidCallback onMarkReviewed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    super.key,
    required this.note,
    required this.subject,
    required this.topicName,
    required this.onMarkReviewed,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _subjectColor {
    if (subject == null) return AppTheme.primary;
    final hex = subject!.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor;
    final isDue = note.isDueToday;
    final stageLabel =
        'Estágio ${note.reviewStage + 1}/${AppConstants.spacedRepetitionIntervals.length}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDue ? AppTheme.warning.withValues(alpha: 0.5) : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subject?.name ?? 'Matéria',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                topicName,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              if (isDue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Revisar hoje',
                    style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                stageLabel,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          if (note.question.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note.question,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (note.correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '✅ ${note.correctAnswer}',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Próxima revisão: ${AppDateUtils.displayDate(note.nextReview)}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const Spacer(),
              if (isDue)
                TextButton.icon(
                  onPressed: onMarkReviewed,
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Revisado', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: AppTheme.textMuted),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppTheme.textMuted),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  final bool showDueOnly;
  const _EmptyNotes({required this.showDueOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.book_outlined, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            showDueOnly
                ? 'Nenhuma revisão pendente hoje 🎉'
                : 'Nenhum erro cadastrado ainda',
            style: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione erros de questões para\npraticar a revisão espaçada.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
