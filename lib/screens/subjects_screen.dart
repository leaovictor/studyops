import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/subject_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:el_tooltip/el_tooltip.dart';
import '../models/subject_model.dart';
import '../widgets/relevance_tooltip.dart';
import '../models/topic_model.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../controllers/goal_controller.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String? _expandedSubjectId;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(subjectsProvider);
    try {
      await ref.read(subjectsProvider.future);
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
    final subjectsAsync = ref.watch(subjectsProvider);
    final controller = ref.read(subjectControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('MatÃ©ria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MatÃ©rias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAIImportDialog(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Importar com IA'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                ),
              ],
            ),
            const SizedBox(height: 4),
            subjectsAsync.maybeWhen(
              data: (subjects) => Text(
                '${subjects.length} matÃ©ria(s) cadastrada(s)',
                style: TextStyle(
                    color: (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontSize: 13),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                header: const WaterDropMaterialHeader(
                  backgroundColor: AppTheme.primary,
                ),
                child: subjectsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                  )),
                  error: (e, _) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppTheme.error, size: 48),
                          const SizedBox(height: 16),
                          const Text('Erro ao carregar matÃ©rias',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(e.toString(),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.color ??
                                      Colors.grey))),
                          const SizedBox(height: 16),
                          TextButton(
                              onPressed: _onRefresh,
                              child: const Text('Tentar novamente')),
                        ],
                      ),
                    ),
                  ),
                  data: (subjects) => subjects.isEmpty
                      ? SingleChildScrollView(child: _EmptySubjects())
                      : AnimationLimiter(
                          child: ListView.separated(
                            itemCount: subjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final subject = subjects[i];
                              final isExpanded =
                                  _expandedSubjectId == subject.id;
                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _SubjectCard(
                                      key: ValueKey(subject.id),
                                      subject: subject,
                                      isExpanded: isExpanded,
                                      onExpand: () => setState(() {
                                        _expandedSubjectId =
                                            isExpanded ? null : subject.id;
                                      }),
                                      onEdit: () =>
                                          _showSubjectDialog(context, subject),
                                      onDelete: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            bool isDeleting = false;
                                            return StatefulBuilder(
                                              builder: (ctx, setS) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Excluir MatÃ©ria'),
                                                  content: Text(
                                                      'Excluir "${subject.name}" e todos os seus tÃ³picos?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: isDeleting
                                                          ? null
                                                          : () => Navigator.pop(
                                                              ctx),
                                                      child: const Text(
                                                          'Cancelar'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: isDeleting
                                                          ? null
                                                          : () async {
                                                              setS(() =>
                                                                  isDeleting =
                                                                      true);
                                                              try {
                                                                await controller
                                                                    .deleteSubject(
                                                                        subject
                                                                            .id);
                                                                if (ctx
                                                                    .mounted) {
                                                                  Navigator.pop(
                                                                      ctx);
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                        content:
                                                                            Text('MatÃ©ria excluÃ­da')),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                if (ctx
                                                                    .mounted) {
                                                                  setS(() =>
                                                                      isDeleting =
                                                                          false);
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                        content:
                                                                            Text('Erro ao excluir: $e')),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                      style: FilledButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .error),
                                                      child: isDeleting
                                                          ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor:
                                                                    AlwaysStoppedAnimation(
                                                                        Colors
                                                                            .white),
                                                              ),
                                                            )
                                                          : const Text(
                                                              'Excluir'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      onAddTopic: () => _showTopicDialog(
                                          context, subject.id, null),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSubjectDialog(
      BuildContext context, Subject? existing) async {
    await showDialog(
      context: context,
      builder: (ctx) => _SubjectDialog(existing: existing),
    );
  }

  Future<void> _showAIImportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => const _AIImportDialog(),
    );
  }

  Future<void> _showTopicDialog(
      BuildContext context, String subjectId, Topic? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int difficulty = existing?.difficulty ?? 3;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              title: Text(existing == null ? 'Novo TÃ³pico' : 'Editar TÃ³pico'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nome do TÃ³pico'),
                      validator: (v) =>
                          (v?.isNotEmpty ?? false) ? null : 'ObrigatÃ³rio',
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'Dificuldade: ${AppConstants.difficultyLabels[difficulty - 1]}',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey),
                            fontSize: 13)),
                    Slider(
                      value: difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppTheme.error,
                      onChanged: (v) => setS(() => difficulty = v.round()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final user = ref.read(authStateProvider).valueOrNull;
                          if (user == null) return;

                          setS(() => isLoading = true);

                          final topic = Topic(
                            id: existing?.id ?? '',
                            userId: user.uid,
                            subjectId: subjectId,
                            name: nameCtrl.text.trim(),
                            difficulty: difficulty,
                          );
                          final controller =
                              ref.read(subjectControllerProvider.notifier);
                          try {
                            if (existing == null) {
                              await controller.createTopic(topic);
                            } else {
                              await controller.updateTopic(topic);
                            }
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(existing == null
                                        ? 'TÃ³pico criado'
                                        : 'TÃ³pico atualizado')),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setS(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Erro ao salvar tÃ³pico: $e')),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(existing == null ? 'Criar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  final Subject subject;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddTopic;

  const _SubjectCard({
    super.key,
    required this.subject,
    required this.isExpanded,
    required this.onExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onAddTopic,
  });

  Color get _color {
    final hex = subject.color.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color;
    final topics =
        ref.watch(topicsForSubjectProvider(subject.id)).valueOrNull ?? [];

    double progress = 0;
    if (topics.isNotEmpty) {
      int totalTasks = topics.length * 3;
      int completedTasks = topics.fold(0, (sum, t) {
        int count = 0;
        if (t.isTheoryDone) count++;
        if (t.isReviewDone) count++;
        if (t.isExercisesDone) count++;
        return sum + count;
      });
      progress = completedTasks / totalTasks;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded
              ? color.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          // Subject header
          InkWell(
            onTap: onExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    subject.name,
                                    style: TextStyle(
                                      color: (Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color ??
                                          Colors.white),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElTooltip(
                                  position: ElTooltipPosition.topCenter,
                                  padding: EdgeInsets.zero,
                                  color: Colors.transparent,
                                  content: RelevanceTooltip(
                                    subject: subject,
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: (Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.color ??
                                        Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Prioridade ${subject.priority} â€¢ Peso ${subject.weight} â€¢ ${topics.length} tÃ³pico(s)',
                              style: TextStyle(
                                color: (Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.color ??
                                    Colors.grey),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 18,
                            color: (Theme.of(context).textTheme.bodySmall?.color ??
                                Colors.grey)),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: (Theme.of(context).textTheme.labelSmall?.color ??
                                Colors.grey)),
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                      ),
                    ],
                  ),
                  if (topics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: color.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Topics expanded panel
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ...topics.map((t) => _TopicRow(
                        topic: t,
                        subjectColor: color,
                        onEdit: () {
                          (context.findAncestorStateOfType<
                                  _SubjectsScreenState>())!
                              ._showTopicDialog(context, subject.id, t);
                        },
                        onDelete: () => ref
                            .read(subjectControllerProvider.notifier)
                            .deleteTopic(t.id),
                        onToggleTheory: () => ref
                            .read(subjectControllerProvider.notifier)
                            .updateTopic(t.copyWith(isTheoryDone: !t.isTheoryDone)),
                        onToggleReview: () => ref
                            .read(subjectControllerProvider.notifier)
                            .updateTopic(t.copyWith(isReviewDone: !t.isReviewDone)),
                        onToggleExercises: () => ref
                            .read(subjectControllerProvider.notifier)
                            .updateTopic(
                                t.copyWith(isExercisesDone: !t.isExercisesDone)),
                      )),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onAddTopic,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Adicionar TÃ³pico',
                        style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final Color subjectColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleTheory;
  final VoidCallback onToggleReview;
  final VoidCallback onToggleExercises;

  const _TopicRow({
    required this.topic,
    required this.subjectColor,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleTheory,
    required this.onToggleReview,
    required this.onToggleExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppConstants.difficultyLabels[topic.difficulty - 1],
                  style: TextStyle(
                      color: (Theme.of(context).textTheme.labelSmall?.color ??
                          Colors.grey),
                      fontSize: 10),
                ),
              ],
            ),
          ),
          _ProgressIcon(
            icon: Icons.menu_book_rounded,
            label: 'T',
            isActive: topic.isTheoryDone,
            color: subjectColor,
            onTap: onToggleTheory,
          ),
          const SizedBox(width: 4),
          _ProgressIcon(
            icon: Icons.refresh_rounded,
            label: 'R',
            isActive: topic.isReviewDone,
            color: subjectColor,
            onTap: onToggleReview,
          ),
          const SizedBox(width: 4),
          _ProgressIcon(
            icon: Icons.assignment_rounded,
            label: 'E',
            isActive: topic.isExercisesDone,
            color: subjectColor,
            onTap: onToggleExercises,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 16,
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey)),
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Editar', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppTheme.error),
                    SizedBox(width: 8),
                    Text('Excluir',
                        style: TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _ProgressIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == 'T'
          ? 'Teoria'
          : label == 'R'
              ? 'RevisÃ£o'
              : 'ExercÃ­cios',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: isActive ? Colors.white : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SubjectDialog extends ConsumerStatefulWidget {
  final Subject? existing;
  const _SubjectDialog({this.existing});

  @override
  ConsumerState<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends ConsumerState<_SubjectDialog> {
  late final TextEditingController _nameCtrl;
  late String _selectedColor;
  late int _priority;
  late int _weight;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor =
        widget.existing?.color ?? AppConstants.defaultSubjectColors.first;
    _priority = widget.existing?.priority ?? 3;
    _weight = widget.existing?.weight ?? 5;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authStateProvider).valueOrNull;

    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova MatÃ©ria' : 'Editar MatÃ©ria'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da MatÃ©ria'),
                validator: (v) =>
                    (v?.isNotEmpty ?? false) ? null : 'ObrigatÃ³rio',
              ),
              const SizedBox(height: 16),
              // Color picker
              Text('Cor',
                  style: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.defaultSubjectColors.map((hex) {
                  final color = Color(
                      int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                  final isSelected = hex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Priority
              StatefulBuilder(builder: (context, setStateSlider) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Prioridade: ${AppConstants.priorityLabels[_priority - 1]}',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey),
                            fontSize: 13)),
                    Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      activeColor: AppTheme.primary,
                      onChanged: (v) {
                        setStateSlider(() => _priority = v.round());
                        setState(() => _priority = v.round());
                      },
                    ),
                  ],
                );
              }),
              // Weight
              StatefulBuilder(builder: (context, setStateSlider) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peso na prova: $_weight',
                        style: TextStyle(
                            color:
                                (Theme.of(context).textTheme.bodySmall?.color ??
                                    Colors.grey),
                            fontSize: 13)),
                    Slider(
                      value: _weight.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: AppTheme.secondary,
                      onChanged: (v) {
                        setStateSlider(() => _weight = v.round());
                        setState(() => _weight = v.round());
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (user == null) return;
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  final subject = Subject(
                    id: widget.existing?.id ?? '',
                    userId: user.uid,
                    goalId: widget.existing?.goalId ??
                        ref.read(activeGoalIdProvider),
                    name: _nameCtrl.text.trim(),
                    color: _selectedColor,
                    priority: _priority,
                    weight: _weight,
                    difficulty: widget.existing?.difficulty ?? 3,
                  );
                  final controller =
                      ref.read(subjectControllerProvider.notifier);

                  try {
                    if (widget.existing == null) {
                      await controller.createSubject(subject);
                    } else {
                      await controller.updateSubject(subject);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(widget.existing == null
                                ? 'MatÃ©ria criada'
                                : 'MatÃ©ria atualizada')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao salvar: $e')),
                      );
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(widget.existing == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined,
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey),
              size: 48),
          const SizedBox(height: 16),
          Text(
            'Nenhuma matÃ©ria cadastrada',
            style: TextStyle(
                color: (Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece adicionando suas matÃ©rias\npara gerar seu cronograma.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}


class _AIImportDialog extends ConsumerStatefulWidget {
  const _AIImportDialog();

  @override
  ConsumerState<_AIImportDialog> createState() => _AIImportDialogState();
}

class _AIImportDialogState extends ConsumerState<_AIImportDialog> {
  final _textCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
          SizedBox(width: 12),
          Text("Importar com IA"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cole aqui o conteúdo programático do edital (matérias e tópicos). A IA irá organizar tudo para você.",
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: "Ex: PORTUGUÊS: 1. Compreensão de textos...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _import,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Processar Edital"),
        ),
      ],
    );
  }

  Future<void> _import() async {
    if (_textCtrl.text.trim().isEmpty) return;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      if (aiService == null) {
        throw Exception("Gemini API Key não configurada no Painel Admin.");
      }
      final activeGoalId = ref.read(activeGoalIdProvider);
      
      final result = await aiService.parseSyllabus(
        _textCtrl.text.trim(),
        user.uid,
        activeGoalId,
      );

      await ref.read(subjectControllerProvider.notifier).createMultipleSubjectsAndTopics(
        result.subjects,
        result.topics,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Edital importado com sucesso!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro na IA: $e")),
        );
      }
    }
  }
}
