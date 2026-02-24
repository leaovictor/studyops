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

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  String? _expandedSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final controller = ref.read(subjectControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Matéria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matérias',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${subjects.length} matéria(s) cadastrada(s)',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: subjects.isEmpty
                  ? _EmptySubjects()
                  : AnimationLimiter(
                      child: ListView.separated(
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final subject = subjects[i];
                          final isExpanded = _expandedSubjectId == subject.id;
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
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Excluir Matéria'),
                                        content: Text(
                                            'Excluir "${subject.name}" e todos os seus tópicos?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              controller
                                                  .deleteSubject(subject.id);
                                              if (ctx.mounted) {
                                                Navigator.pop(ctx);
                                              }
                                            },
                                            style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.error),
                                            child: const Text('Excluir'),
                                          ),
                                        ],
                                      ),
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

  Future<void> _showTopicDialog(
      BuildContext context, String subjectId, Topic? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    int difficulty = existing?.difficulty ?? 3;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text(existing == null ? 'Novo Tópico' : 'Editar Tópico'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nome do Tópico'),
                  validator: (v) =>
                      (v?.isNotEmpty ?? false) ? null : 'Obrigatório',
                ),
                const SizedBox(height: 16),
                Text(
                    'Dificuldade: ${AppConstants.difficultyLabels[difficulty - 1]}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final user = ref.read(authStateProvider).valueOrNull;
                if (user == null) return;

                final topic = Topic(
                  id: existing?.id ?? '',
                  userId: user.uid,
                  subjectId: subjectId,
                  name: nameCtrl.text.trim(),
                  difficulty: difficulty,
                );
                final controller = ref.read(subjectControllerProvider.notifier);
                if (existing == null) {
                  controller.createTopic(topic);
                } else {
                  controller.updateTopic(topic);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Criar' : 'Salvar'),
            ),
          ],
        );
      }),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? color.withValues(alpha: 0.4) : AppTheme.border,
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
              child: Row(
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
                            Text(
                              subject.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
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
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Prioridade ${subject.priority} • Peso ${subject.weight} • ${topics.length} tópico(s)',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.textMuted),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
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
                        onEdit: () {
                          (context.findAncestorStateOfType<
                                  _SubjectsScreenState>())!
                              ._showTopicDialog(context, subject.id, t);
                        },
                        onDelete: () => ref
                            .read(subjectControllerProvider.notifier)
                            .deleteTopic(t.id),
                      )),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: onAddTopic,
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Adicionar Tópico',
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicRow({
    required this.topic,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record_rounded,
              size: 6, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              topic.name,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
          Text(
            AppConstants.difficultyLabels[topic.difficulty - 1],
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 14, color: AppTheme.textMuted),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 14, color: AppTheme.textMuted),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
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
      title: Text(widget.existing == null ? 'Nova Matéria' : 'Editar Matéria'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome da Matéria'),
                validator: (v) =>
                    (v?.isNotEmpty ?? false) ? null : 'Obrigatório',
              ),
              const SizedBox(height: 16),
              // Color picker
              const Text('Cor',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
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
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
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
          onPressed: () {
            if (user == null) return;
            if (!_formKey.currentState!.validate()) return;
            final subject = Subject(
              id: widget.existing?.id ?? '',
              userId: user.uid,
              name: _nameCtrl.text.trim(),
              color: _selectedColor,
              priority: _priority,
              weight: _weight,
              difficulty: widget.existing?.difficulty ?? 3,
            );
            final controller = ref.read(subjectControllerProvider.notifier);
            if (widget.existing == null) {
              controller.createSubject(subject);
            } else {
              controller.updateSubject(subject);
            }
            Navigator.pop(context);
          },
          child: Text(widget.existing == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, color: AppTheme.textMuted, size: 48),
          SizedBox(height: 16),
          Text(
            'Nenhuma matéria cadastrada',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Comece adicionando suas matérias\npara gerar seu cronograma.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
