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
        label: const Text('Matéria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matérias',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: (Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            subjectsAsync.maybeWhen(
              data: (subjects) => Text(
                '${subjects.length} matéria(s) cadastrada(s)',
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
                          const Text('Erro ao carregar matérias',
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
                                                      'Excluir Matéria'),
                                                  content: Text(
                                                      'Excluir "${subject.name}" e todos os seus tópicos?'),
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
                                                                            Text('Matéria excluída')),
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
                                        ? 'Tópico criado'
                                        : 'Tópico atualizado')),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setS(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Erro ao salvar tópico: $e')),
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
                          'Prioridade ${subject.priority} • Peso ${subject.weight} • ${topics.length} tópico(s)',
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
          Icon(Icons.fiber_manual_record_rounded,
              size: 6,
              color: (Theme.of(context).textTheme.labelSmall?.color ??
                  Colors.grey)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              topic.name,
              style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppConstants.difficultyLabels[topic.difficulty - 1],
            style: TextStyle(
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey),
                fontSize: 11),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 14,
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey)),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 14,
                color: (Theme.of(context).textTheme.labelSmall?.color ??
                    Colors.grey)),
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
                                ? 'Matéria criada'
                                : 'Matéria atualizada')),
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
            'Nenhuma matéria cadastrada',
            style: TextStyle(
                color: (Theme.of(context).textTheme.bodyLarge?.color ??
                    Colors.white),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece adicionando suas matérias\npara gerar seu cronograma.',
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
