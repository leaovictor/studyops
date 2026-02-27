import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import '../controllers/error_notebook_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/flashcard_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/goal_controller.dart';
import '../models/error_note_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../models/flashcard_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../services/ai_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ErrorNotebookScreen extends ConsumerStatefulWidget {
  const ErrorNotebookScreen({super.key});

  @override
  ConsumerState<ErrorNotebookScreen> createState() => _ErrorNotebookScreenState();
}

class _ErrorNotebookScreenState extends ConsumerState<ErrorNotebookScreen> {
  bool _showDueOnly = false;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(errorNotesProvider);
    ref.invalidate(dueTodayNotesProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(allTopicsProvider);
    try { await ref.read(errorNotesProvider.future); } catch (_) {}
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Caderno de Erros', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
                      Text('Revisão espaçada inteligente', style: TextStyle(color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey), fontSize: 13)),
                    ],
                  ),
                ),
                dueAsync.when(
                  data: (due) => due.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4))),
                          child: Text('${due.length} p/ revisão', style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600)),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [FilterChip(label: const Text('Somente revisões de hoje'), selected: _showDueOnly, onSelected: (v) => setState(() => _showDueOnly = v), selectedColor: AppTheme.primary.withValues(alpha: 0.2), checkmarkColor: AppTheme.primary)]),
            const SizedBox(height: 16),
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                header: const WaterDropMaterialHeader(backgroundColor: AppTheme.primary),
                child: notesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
                  error: (e, _) => SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Center(child: Text('Erro: $e'))),
                  data: (notes) {
                    final filtered = _showDueOnly ? notes.where((n) => n.isDueToday).toList() : notes;
                    if (filtered.isEmpty) return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: _EmptyNotes(showDueOnly: _showDueOnly));
                    return AnimationLimiter(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final note = filtered[i];
                          return AnimationConfiguration.staggeredList(
                            position: i,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _NoteCard(
                                  key: ValueKey(note.id),
                                  note: note,
                                  subject: subjectMap[note.subjectId],
                                  topicName: topicMap[note.topicId]?.name ?? 'Tópico',
                                  onMarkReviewed: () => ref.read(errorNotebookControllerProvider.notifier).markReviewed(note),
                                  onEdit: () => _showNoteDialog(context, note, subjects, allTopics),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Excluir Erro'), content: const Text('Tem certeza que deseja excluir este erro?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(style: FilledButton.styleFrom(backgroundColor: AppTheme.error), onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
                                    if (confirm == true) ref.read(errorNotebookControllerProvider.notifier).deleteNote(note.id);
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

  Future<void> _showNoteDialog(BuildContext context, ErrorNote? existing, List<Subject> subjects, List<Topic> allTopics) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final activeGoalId = ref.read(activeGoalIdProvider);
    if (user == null || subjects.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre matérias primeiro'))); return; }
    await showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (ctx) => _NoteDialogContent(existing: existing, subjects: subjects, allTopics: allTopics, activeGoalId: activeGoalId, userId: user.uid));
  }
}

class _NoteCard extends StatefulWidget {
  final ErrorNote note;
  final Subject? subject;
  final String topicName;
  final VoidCallback onMarkReviewed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _NoteCard({super.key, required this.note, required this.subject, required this.topicName, required this.onMarkReviewed, required this.onEdit, required this.onDelete});
  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _isExpanded = false;
  bool _isGenerating = false;
  bool _isExplaining = false;
  String? _explanation;

  Color get _subjectColor => widget.subject != null ? Color(int.parse('FF${widget.subject!.color.replaceAll('#', '')}', radix: 16)) : AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor;
    final isDue = widget.note.isDueToday;
    return Consumer(builder: (context, ref, child) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDue ? AppTheme.warning.withValues(alpha: 0.5) : (_isExpanded ? color.withValues(alpha: 0.4) : Theme.of(context).dividerColor))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(onTap: () => setState(() => _isExpanded = !_isExpanded), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(widget.subject?.name ?? 'Matéria', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.topicName, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isDue) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: const Text('Revisar hoje', style: TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w600))),
              const SizedBox(width: 4),
              Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
            ]),
            if (widget.note.question.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(widget.note.question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: _isExpanded ? null : 2, overflow: _isExpanded ? null : TextOverflow.ellipsis)),
          ])),
          if (_isExpanded) ...[
            const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
            if (widget.note.correctAnswer.isNotEmpty) ...[const Text('RESPOSTA CORRETA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 4), Text(widget.note.correctAnswer, style: const TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w600)), const SizedBox(height: 12)],
            if (widget.note.errorReason.isNotEmpty) ...[const Text('POR QUE ERREI?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 4), Text(widget.note.errorReason, style: const TextStyle(fontSize: 13),), const SizedBox(height: 16)],
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: _isGenerating ? null : () => _generateFlashcards(ref), icon: _isGenerating ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 14), label: const Text('Gerar Flashcards IA', style: TextStyle(fontSize: 12)), style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 12))),
              OutlinedButton.icon(onPressed: _isExplaining ? null : () => _explainWithAI(ref), icon: _isExplaining ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lightbulb_outline_rounded, size: 14), label: const Text('Explicar com IA', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary), padding: const EdgeInsets.symmetric(horizontal: 12))),
            ]),
            if (_isExplaining || _explanation != null) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1))), child: _isExplaining ? const Center(child: CircularProgressIndicator(strokeWidth: 2)) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.psychology_outlined, size: 16, color: AppTheme.primary), SizedBox(width: 8), Text('EXPLICAÇÃO DO MENTOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary))]), const SizedBox(height: 8), Text(_explanation!, style: const TextStyle(fontSize: 13, height: 1.5))]))],
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('Próxima revisão: ${AppDateUtils.displayDate(widget.note.nextReview)}', style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isDue) TextButton.icon(onPressed: widget.onMarkReviewed, icon: const Icon(Icons.check_rounded, size: 14), label: const Text('Revisado', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 10))),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey), onPressed: widget.onEdit, visualDensity: VisualDensity.compact),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.grey), onPressed: widget.onDelete, visualDensity: VisualDensity.compact),
          ]),
        ]),
      );
    });
  }

  Future<void> _generateFlashcards(WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() => _isGenerating = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      if (aiService == null) { throw Exception("Gemini API Key não configurada."); }
      final cards = await aiService.generateFlashcardsFromError(user.uid, widget.note.question, widget.note.correctAnswer, widget.note.errorReason);
      if (!mounted) return;
      final bool? confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Row(children: [Icon(Icons.auto_awesome_rounded, color: AppTheme.accent), SizedBox(width: 12), Text('Flashcards Sugeridos')]), content: SizedBox(width: double.maxFinite, child: ListView.separated(shrinkWrap: true, itemCount: cards.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Frente: ${cards[i]['front']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text('Verso: ${cards[i]['back']}', style: const TextStyle(fontSize: 12))]))), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Adicionar Todos'))]));
      if (confirm == true && mounted) {
        final flashcardCtrl = ref.read(flashcardControllerProvider.notifier);
        for (final cardData in cards) {
          await flashcardCtrl.create(Flashcard(id: '', userId: user.uid, goalId: widget.note.goalId, subjectId: widget.note.subjectId, topicId: widget.note.topicId, front: cardData['front']!, back: cardData['back']!, fsrsCard: fsrs.Card(cardId: 1).toMap(), due: DateTime.now(), createdAt: DateTime.now()));
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flashcards criados!')));
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'))); }
    finally { if (mounted) setState(() => _isGenerating = false); }
  }

  Future<void> _explainWithAI(WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    setState(() { _isExplaining = true; _explanation = null; });
    try {
      final aiService = ref.read(aiServiceProvider);
      if (aiService == null) { throw Exception("Gemini API Key não configurada."); }
      final result = await aiService.explainQuestion(userId: user.uid, question: widget.note.question, correctAnswer: widget.note.correctAnswer);
      if (mounted) setState(() { _explanation = result; _isExplaining = false; });
    } catch (e) { if (mounted) setState(() { _explanation = 'Erro: $e'; _isExplaining = false; }); }
  }
}

class _NoteDialogContent extends StatefulWidget {
  final ErrorNote? existing; final List<Subject> subjects; final List<Topic> allTopics; final String? activeGoalId; final String userId;
  const _NoteDialogContent({required this.existing, required this.subjects, required this.allTopics, required this.activeGoalId, required this.userId});
  @override
  State<_NoteDialogContent> createState() => _NoteDialogContentState();
}

class _NoteDialogContentState extends State<_NoteDialogContent> {
  late TextEditingController questionCtrl; late TextEditingController answerCtrl; late TextEditingController reasonCtrl; Subject? selectedSubject; Topic? selectedTopic;
  @override
  void initState() {
    super.initState();
    questionCtrl = TextEditingController(text: widget.existing?.question ?? '');
    answerCtrl = TextEditingController(text: widget.existing?.correctAnswer ?? '');
    reasonCtrl = TextEditingController(text: widget.existing?.errorReason ?? '');
    selectedSubject = widget.subjects.firstWhere((s) => s.id == (widget.existing?.subjectId ?? widget.subjects.first.id), orElse: () => widget.subjects.first);
  }
  @override
  void dispose() { questionCtrl.dispose(); answerCtrl.dispose(); reasonCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final filteredTopics = widget.allTopics.where((t) => t.subjectId == selectedSubject?.id).toList();
    if (selectedTopic == null && filteredTopics.isNotEmpty && widget.existing == null) { selectedTopic = filteredTopics.first; }
    else if (widget.existing != null && selectedTopic == null) { for (final t in filteredTopics) { if (t.id == widget.existing!.topicId) { selectedTopic = t; break; } } if (selectedTopic == null && filteredTopics.isNotEmpty) selectedTopic = filteredTopics.first; }
    return Consumer(builder: (context, ref, child) {
      return Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text(widget.existing == null ? 'Novo Erro' : 'Editar Erro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white))),
        const SizedBox(height: 20),
        DropdownButtonFormField<Subject>(initialValue: selectedSubject, decoration: const InputDecoration(labelText: 'Matéria'), items: widget.subjects.map((s) => DropdownMenuItem<Subject>(value: s, child: Text(s.name))).toList(), onChanged: (s) => setState(() { selectedSubject = s; selectedTopic = null; })),
        const SizedBox(height: 12),
        if (filteredTopics.isNotEmpty) DropdownButtonFormField<Topic>(initialValue: selectedTopic, decoration: const InputDecoration(labelText: 'Tópico'), items: filteredTopics.map((t) => DropdownMenuItem<Topic>(value: t, child: Text(t.name))).toList(), onChanged: (t) => setState(() => selectedTopic = t)),
        const SizedBox(height: 12),
        TextField(controller: questionCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Questão / Enunciado')),
        const SizedBox(height: 12),
        TextField(controller: answerCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Resposta correta')),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Por que errei?')),
        const SizedBox(height: 20),
        FilledButton(onPressed: () {
          if (selectedSubject == null) return;
          final note = ErrorNote(id: widget.existing?.id ?? const Uuid().v4(), userId: widget.userId, goalId: widget.existing?.goalId ?? widget.activeGoalId, subjectId: selectedSubject!.id, topicId: selectedTopic?.id ?? '', question: questionCtrl.text, correctAnswer: answerCtrl.text, errorReason: reasonCtrl.text, nextReview: widget.existing?.nextReview ?? DateTime.now().add(const Duration(days: 1)), reviewStage: widget.existing?.reviewStage ?? 0);
          if (widget.existing == null) { ref.read(errorNotebookControllerProvider.notifier).createNote(note); } else { ref.read(errorNotebookControllerProvider.notifier).updateNote(note); }
          Navigator.pop(context);
        }, child: Text(widget.existing == null ? 'Salvar Erro' : 'Atualizar')),
      ])));
    });
  }
}

class _EmptyNotes extends StatelessWidget {
  final bool showDueOnly;
  const _EmptyNotes({required this.showDueOnly});
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.book_outlined, color: Colors.grey, size: 48),
      const SizedBox(height: 16),
      Text(showDueOnly ? 'Nenhuma revisão pendente hoje 🎉' : 'Nenhum erro cadastrado ainda', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Adicione erros de questões para\npraticar a revisão espaçada.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
    ]));
  }
}
