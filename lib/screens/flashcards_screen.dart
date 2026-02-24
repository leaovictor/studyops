import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/auth_controller.dart';
import '../controllers/flashcard_controller.dart';
import '../controllers/subject_controller.dart';
import '../models/flashcard_model.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _filterSubjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            backgroundColor: AppTheme.bg0,
            pinned: true,
            title: const Text(
              'Flashcards',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(text: 'Revisar Hoje'),
                Tab(text: 'Todos'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ReviewTab(),
            _AllCardsTab(
              filterSubjectId: _filterSubjectId,
              onFilterChanged: (id) => setState(() => _filterSubjectId = id),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardModal(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo card'),
      ),
    );
  }

  void _showAddCardModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddCardSheet(ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Review Tab — decks grouped by subject
// ---------------------------------------------------------------------------
class _ReviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueAsync = ref.watch(dueFlashcardsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return dueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (due) {
        final subjects = subjectsAsync.valueOrNull ?? [];
        final bySubject = <String, List<Flashcard>>{};
        for (final c in due) {
          bySubject.putIfAbsent(c.subjectId, () => []).add(c);
        }

        if (bySubject.isEmpty) {
          return const _EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'Tudo em dia!',
            subtitle: 'Nenhum card para revisar hoje.',
          );
        }

        return AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                _SummaryBanner(
                  totalDue: due.length,
                  onStudyAll: () => context.push('/flashcards/study'),
                ),
                const SizedBox(height: 16),
                ...bySubject.entries.map((e) {
                  final subject = subjects.firstWhere(
                    (s) => s.id == e.key,
                    orElse: () => Subject(
                        id: e.key,
                        userId: '',
                        name: 'Matéria',
                        color: '#7C6FFF',
                        priority: 1,
                        weight: 1,
                        difficulty: 3),
                  );
                  return _DeckCard(
                    subject: subject,
                    count: e.value.length,
                    onStudy: () => context
                        .push('/flashcards/study?subjectId=${subject.id}'),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int totalDue;
  final VoidCallback onStudyAll;
  const _SummaryBanner({required this.totalDue, required this.onStudyAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppTheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalDue cards para revisar',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Mantenha sua sequência de estudos!',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStudyAll,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Estudar Tudo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Subject subject;
  final int count;
  final VoidCallback onStudy;

  const _DeckCard({
    required this.subject,
    required this.count,
    required this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        Color(int.parse('FF${subject.color.replaceAll('#', '')}', radix: 16));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.style_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$count card${count != 1 ? 's' : ''} para revisar',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onStudy,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Estudar', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All Cards Tab
// ---------------------------------------------------------------------------
class _AllCardsTab extends ConsumerWidget {
  final String? filterSubjectId;
  final void Function(String?) onFilterChanged;

  const _AllCardsTab({
    required this.filterSubjectId,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(flashcardsProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (all) {
        final filtered = filterSubjectId == null
            ? all
            : all.where((c) => c.subjectId == filterSubjectId).toList();

        return Column(
          children: [
            // Filter chips
            if (subjects.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'Todas',
                      selected: filterSubjectId == null,
                      color: AppTheme.primary,
                      onTap: () => onFilterChanged(null),
                    ),
                    ...subjects.map((s) {
                      final color = Color(int.parse(
                          'FF${s.color.replaceAll('#', '')}',
                          radix: 16));
                      return _FilterChip(
                        label: s.name,
                        selected: filterSubjectId == s.id,
                        color: color,
                        onTap: () => onFilterChanged(
                            filterSubjectId == s.id ? null : s.id),
                      );
                    }),
                  ],
                ),
              ),

            if (filtered.isEmpty)
              const Expanded(
                child: _EmptyState(
                  icon: Icons.style_outlined,
                  title: 'Nenhum flashcard',
                  subtitle: 'Crie seu primeiro card clicando em "+ Novo card".',
                ),
              )
            else
              Expanded(
                child: AnimationLimiter(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final subject = subjects.firstWhere(
                        (s) => s.id == c.subjectId,
                        orElse: () => const Subject(
                            id: '',
                            userId: '',
                            name: 'Matéria',
                            color: '#7C6FFF',
                            priority: 1,
                            weight: 1,
                            difficulty: 3),
                      );
                      return AnimationConfiguration.staggeredList(
                        position: i,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _FlashcardListTile(
                              card: c,
                              subject: subject,
                              onDelete: () => ref
                                  .read(flashcardControllerProvider.notifier)
                                  .delete(c.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppTheme.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FlashcardListTile extends StatelessWidget {
  final Flashcard card;
  final Subject subject;
  final VoidCallback onDelete;

  const _FlashcardListTile({
    required this.card,
    required this.subject,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        Color(int.parse('FF${subject.color.replaceAll('#', '')}', radix: 16));
    final isDue = card.isDueToday;

    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  isDue ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.front,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Próxima revisão: ${AppDateUtils.formatRelativeDate(card.due)}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isDue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Revisar',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Card Modal
// ---------------------------------------------------------------------------
class _AddCardSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddCardSheet({required this.ref});

  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  final _frontCtrl = TextEditingController();
  final _backCtrl = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedTopicId;
  bool _saving = false;

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final topics = _selectedSubjectId != null
        ? (ref
                .watch(topicsForSubjectProvider(_selectedSubjectId!))
                .valueOrNull ??
            [])
        : <Topic>[];

    final canSave = _frontCtrl.text.trim().isNotEmpty &&
        _backCtrl.text.trim().isNotEmpty &&
        _selectedSubjectId != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Novo flashcard',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _frontCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Frente (pergunta)',
              prefixIcon: Icon(Icons.help_outline_rounded),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _backCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Verso (resposta)',
              prefixIcon: Icon(Icons.lightbulb_outline_rounded),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId,
            hint: const Text('Matéria',
                style: TextStyle(color: AppTheme.textMuted)),
            dropdownColor: AppTheme.bg2,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.book_rounded),
            ),
            items: subjects.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text(s.name,
                    style: const TextStyle(color: AppTheme.textPrimary)),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _selectedSubjectId = v;
              _selectedTopicId = null;
            }),
          ),
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedTopicId,
              hint: const Text('Tópico (opcional)',
                  style: TextStyle(color: AppTheme.textMuted)),
              dropdownColor: AppTheme.bg2,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.topic_rounded),
              ),
              items: topics.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(t.name,
                      style: const TextStyle(color: AppTheme.textPrimary)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedTopicId = v),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canSave && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar card'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final card = Flashcard(
      id: '',
      userId: user.uid,
      subjectId: _selectedSubjectId!,
      topicId: _selectedTopicId ?? '',
      front: _frontCtrl.text.trim(),
      back: _backCtrl.text.trim(),
      fsrsCard: const {},
      due: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await ref.read(flashcardControllerProvider.notifier).create(card);

    if (mounted) Navigator.pop(context);
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
