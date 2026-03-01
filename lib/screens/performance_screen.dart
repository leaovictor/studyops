import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/study_plan_controller.dart';
import '../controllers/subject_controller.dart';
import '../controllers/performance_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/shared_question_model.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_charts.dart';
import '../widgets/performance_insight_card.dart';
import '../widgets/study_heatmap.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(dashboardProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(activePlanProvider);
    ref.invalidate(questionLogsProvider);
    try {
      await ref.read(dashboardProvider.future);
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
    final dashAsync = ref.watch(dashboardProvider);
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final activePlan = ref.watch(activePlanProvider).valueOrNull;
    final stats = ref.watch(performanceStatsProvider);
    final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? [];

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            header: const WaterDropMaterialHeader(
              backgroundColor: AppTheme.primary,
            ),
            child: dashAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary))),
              error: (e, _) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                      height: 300, child: Center(child: Text('Erro: $e')))),
              data: (data) {
                final subjectNameMap = {for (final s in subjects) s.id: s.name};
                final trend = data.weeklyTrend;

                // KPI computations
                final weekHours = data.weekMinutes / 60.0;
                final targetWeekHours = (activePlan?.dailyHours ?? 3.0) * 7;
                final productivity = targetWeekHours > 0
                    ? (weekHours / targetWeekHours).clamp(0.0, 1.0)
                    : 0.0;

                final String riskLabel;
                final Color riskColor;
                if (productivity >= 0.8) {
                  riskLabel = 'Baixo';
                  riskColor = AppTheme.accent;
                } else if (productivity >= 0.5) {
                  riskLabel = 'Médio';
                  riskColor = AppTheme.primary;
                } else {
                  riskLabel = 'Alto';
                  riskColor = Colors.redAccent;
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                        child: AnimationLimiter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 16,
                                  runSpacing: 12,
                                  children: [
                                    Text(
                                      'Performance',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: (Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color ??
                                            Colors.white),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showAIAnalysisDialog(context,
                                                  data, stats, subjectNameMap),
                                          icon: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 18),
                                          label: const Text('Analisar com IA',
                                              style: TextStyle(fontSize: 13)),
                                          style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.accent),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showGenerateAIDialog(context),
                                          icon: const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 18),
                                          label: const Text('Gerar com IA',
                                              style: TextStyle(fontSize: 13)),
                                          style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.accent),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Análise detalhada do seu desempenho de estudos',
                                  style: TextStyle(
                                      color: (Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color ??
                                          Colors.grey),
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 20),

                                // ── Performance Insight Card ──────────────────
                                const PerformanceInsightCard(),
                                const SizedBox(height: 20),

                                // KPI Row
                                if (MediaQuery.of(context).size.width >= 600)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _KpiCard(
                                          icon: Icons.percent_rounded,
                                          iconColor: AppTheme.accent,
                                          label: 'Aproveitamento',
                                          value:
                                              '${stats.averageAccuracy.toStringAsFixed(1)}%',
                                          subtitle:
                                              '${stats.totalCorrect}/${stats.totalQuestions} acertos',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _KpiCard(
                                          icon: Icons.bolt_rounded,
                                          iconColor: AppTheme.primary,
                                          label: 'Produtividade',
                                          value:
                                              '${(productivity * 100).round()}%',
                                          subtitle:
                                              '${weekHours.toStringAsFixed(1)}h / ${targetWeekHours.toStringAsFixed(0)}h',
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _KpiCard(
                                          icon: Icons.warning_amber_rounded,
                                          iconColor: riskColor,
                                          label: 'Risco de Atraso',
                                          value: riskLabel,
                                          valueColor: riskColor,
                                          subtitle: 'vs. meta semanal',
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _KpiCard(
                                        icon: Icons.percent_rounded,
                                        iconColor: AppTheme.accent,
                                        label: 'Aproveitamento',
                                        value:
                                            '${stats.averageAccuracy.toStringAsFixed(1)}%',
                                        subtitle:
                                            '${stats.totalCorrect}/${stats.totalQuestions} acertos',
                                      ),
                                      const SizedBox(height: 12),
                                      _KpiCard(
                                        icon: Icons.bolt_rounded,
                                        iconColor: AppTheme.primary,
                                        label: 'Produtividade',
                                        value:
                                            '${(productivity * 100).round()}%',
                                        subtitle:
                                            '${weekHours.toStringAsFixed(1)}h / ${targetWeekHours.toStringAsFixed(0)}h',
                                      ),
                                      const SizedBox(height: 12),
                                      _KpiCard(
                                        icon: Icons.warning_amber_rounded,
                                        iconColor: riskColor,
                                        label: 'Risco de Atraso',
                                        value: riskLabel,
                                        valueColor: riskColor,
                                        subtitle: 'vs. meta semanal',
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 20),
                                // ── Liquid vs Brute (Cognitive Efficiency) ──
                                _LiquidVsBruteCard(
                                  liquidMins: data.weekProductiveMinutes,
                                  bruteMins: data.weekMinutes,
                                ),
                                const SizedBox(height: 20),
                                // ── Gap Analysis ─────────────────────────────
                                _GapAnalysisSection(
                                  accuracyByTopic: stats.accuracyByTopic,
                                  allTopics: allTopics,
                                  subjects: subjects,
                                ),
                                const SizedBox(height: 20),
                                if (data.streakDays > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.orangeAccent
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥',
                                            style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${data.streakDays} dia${data.streakDays > 1 ? 's' : ''} seguido${data.streakDays > 1 ? 's' : ''}!',
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                if (stats.accuracyBySubject.isNotEmpty)
                                  _SectionCard(
                                    title: 'Aproveitamento por Matéria (%)',
                                    child: Column(
                                      children: stats.accuracyBySubject.entries
                                          .map((e) {
                                        final subject = subjects.firstWhere(
                                            (s) => s.id == e.key,
                                            orElse: () => subjects.first);
                                        final color = Color(int.parse(
                                            'FF${subject.color.replaceAll('#', '')}',
                                            radix: 16));
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(subject.name,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  Text(
                                                      '${e.value.toStringAsFixed(1)}%',
                                                      style: TextStyle(
                                                          color: color,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: e.value / 100,
                                                  minHeight: 8,
                                                  backgroundColor: color
                                                      .withValues(alpha: 0.1),
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          color),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                _SectionCard(
                                  title:
                                      'Evolução semanal de estudos (horas/dia)',
                                  child: SizedBox(
                                    height: 200,
                                    child: trend.isEmpty
                                        ? const Center(
                                            child: Text('Sem dados ainda',
                                                style: TextStyle(
                                                    color: Colors.grey)))
                                        : WeeklyBarChart(data: trend),
                                  ),
                                ),
                                _SectionCard(
                                  title: 'Atividade — Últimos 35 Dias',
                                  child: StudyHeatmap(
                                    dailyMinutes: ref
                                            .watch(thirtyDayHeatmapProvider)
                                            .valueOrNull ??
                                        {},
                                    isDark: Theme.of(context).brightness ==
                                        Brightness.dark,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // ➕ Botão para registrar questões manual
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showRecordQuestionsDialog(context),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Registrar Questões'),
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordQuestionsDialog(BuildContext context) {
    showDialog(
        context: context, builder: (context) => const _RecordQuestionsDialog());
  }

  void _showAIAnalysisDialog(BuildContext context, DashboardData data,
      PerformanceStats stats, Map<String, String> subjectNameMap) {
    showDialog(
        context: context,
        builder: (context) => _AIAnalysisDialog(
            data: data, stats: stats, subjectNameMap: subjectNameMap));
  }

  void _showGenerateAIDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => const _GenerateAIPortalDialog());
  }
}

class _GenerateAIPortalDialog extends ConsumerStatefulWidget {
  const _GenerateAIPortalDialog();

  @override
  ConsumerState<_GenerateAIPortalDialog> createState() =>
      _GenerateAIPortalDialogState();
}

class _GenerateAIPortalDialogState
    extends ConsumerState<_GenerateAIPortalDialog> {
  String? _selectedSubjectId;
  String? _selectedTopicId;
  int _count = 5;
  bool _isLoading = false;
  String? _status;

  Future<void> _generate() async {
    if (_selectedSubjectId == null) return;

    setState(() {
      _isLoading = true;
      _status = "A IA está elaborando as questões...";
    });

    try {
      final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
      final subject = subjects.firstWhere((s) => s.id == _selectedSubjectId);
      final topics = ref.read(allTopicsProvider).valueOrNull ?? [];
      final topicName = _selectedTopicId != null
          ? topics.firstWhere((t) => t.id == _selectedTopicId).name
          : "Geral";

      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) throw Exception("IA não configurada.");

      final generated = await aiService.generateQuestionsForBank(
        subject: subject.name,
        topic: topicName,
        count: _count,
      );

      setState(() => _status = "Alimentando o banco compartilhado...");

      final List<SharedQuestion> toAdd = generated.map((qData) {
        final statement = qData["statement"] as String;
        final options = Map<String, String>.from(qData["options"]);
        return SharedQuestion(
          id: "",
          statement: statement,
          options: options,
          correctAnswer: qData["correctAnswer"],
          subjectName: qData["subjectName"],
          topicName: qData["topicName"],
          source: "Gerado por IA",
          textHash: SharedQuestion.generateHash(statement, options),
        );
      }).toList();

      final bankService = ref.read(questionBankServiceProvider);
      final added = await bankService.addQuestions(toAdd);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = "Sucesso! $added novas questões geradas e adicionadas.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = "Erro: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final topics = _selectedSubjectId != null
        ? ref
                .watch(topicsForSubjectProvider(_selectedSubjectId!))
                .valueOrNull ??
            []
        : [];

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
          SizedBox(width: 12),
          Text("Gerar com IA"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "A IA vai buscar e elaborar questões reais ou similares para alimentar o banco global do StudyOps.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_status != null)
              Text(_status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.accent))
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matéria',
                  isDense: true,
                ),
                items: subjects
                    .map((s) => DropdownMenuItem<String>(
                        value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedSubjectId = val;
                  _selectedTopicId = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedTopicId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tópico (Opcional)',
                  isDense: true,
                ),
                items: topics
                    .map((t) => DropdownMenuItem<String>(
                        value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTopicId = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Quantidade: ", style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                            value: 3,
                            label: Text("3", style: TextStyle(fontSize: 12))),
                        ButtonSegment(
                            value: 5,
                            label: Text("5", style: TextStyle(fontSize: 12))),
                        ButtonSegment(
                            value: 10,
                            label: Text("10", style: TextStyle(fontSize: 12))),
                      ],
                      selected: {_count},
                      onSelectionChanged: (val) =>
                          setState(() => _count = val.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _selectedSubjectId == null ? null : _generate,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text("Iniciar Geração"),
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    minimumSize: const Size(double.infinity, 45)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Fechar"),
        ),
      ],
    );
  }
}

class _AIAnalysisDialog extends ConsumerStatefulWidget {
  final DashboardData data;
  final PerformanceStats stats;
  final Map<String, String> subjectNameMap;
  const _AIAnalysisDialog(
      {required this.data, required this.stats, required this.subjectNameMap});

  @override
  ConsumerState<_AIAnalysisDialog> createState() => _AIAnalysisDialogState();
}

class _AIAnalysisDialogState extends ConsumerState<_AIAnalysisDialog> {
  bool _isLoading = true;
  String? _analysis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateAnalysis();
  }

  Future<void> _generateAnalysis() async {
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) return;
      final aiService = await ref.read(aiServiceProvider.future);
      if (aiService == null) {
        throw Exception("A chave da IA não está configurada no Painel Admin.");
      }

      final accuracyByName = <String, double>{};
      widget.stats.accuracyBySubject.forEach((id, accuracy) {
        final name = widget.subjectNameMap[id] ?? "Desconhecida";
        accuracyByName[name] = accuracy;
      });

      final result = await aiService.analyzePerformance(
        userId: user.uid,
        accuracyBySubjectName: accuracyByName,
        totalQuestions: widget.stats.totalQuestions,
        consistencyPct: widget.data.consistencyPct,
        streakDays: widget.data.streakDays,
      );
      if (mounted) {
        setState(() {
          _analysis = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
        SizedBox(width: 12),
        Text("Mentor IA")
      ]),
      content: _isLoading
          ? const Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Analisando seus dados...")
            ])
          : _error != null
              ? Text("Erro: $_error",
                  style: const TextStyle(color: AppTheme.error))
              : SingleChildScrollView(
                  child: Text(_analysis ?? "",
                      style: const TextStyle(fontSize: 14, height: 1.5))),
      actions: [
        if (!_isLoading)
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendi"))
      ],
    );
  }
}

class _RecordQuestionsDialog extends ConsumerStatefulWidget {
  const _RecordQuestionsDialog();
  @override
  ConsumerState<_RecordQuestionsDialog> createState() =>
      _RecordQuestionsDialogState();
}

class _RecordQuestionsDialogState
    extends ConsumerState<_RecordQuestionsDialog> {
  String? _selectedSubjectId;
  String? _selectedTopicId;
  final _totalCtrl = TextEditingController();
  final _correctCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final topics = _selectedSubjectId != null
        ? ref
                .watch(topicsForSubjectProvider(_selectedSubjectId!))
                .valueOrNull ??
            []
        : [];
    return AlertDialog(
      title: const Text('Registrar Desempenho'),
      content: Form(
          key: _formKey,
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: subjects
                    .map((s) => DropdownMenuItem<String>(
                        value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => setState(() {
                      _selectedSubjectId = val;
                      _selectedTopicId = null;
                    }),
                validator: (v) => v == null ? 'Obrigatório' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
                initialValue: _selectedTopicId,
                decoration:
                    const InputDecoration(labelText: 'Tópico (Opcional)'),
                items: topics
                    .map((t) => DropdownMenuItem<String>(
                        value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTopicId = val)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      controller: _totalCtrl,
                      decoration: const InputDecoration(labelText: 'Total'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                          ? null
                          : 'Inválido')),
              const SizedBox(width: 16),
              Expanded(
                  child: TextFormField(
                      controller: _correctCtrl,
                      decoration: const InputDecoration(labelText: 'Acertos'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v ?? '') ?? 0;
                        final total = int.tryParse(_totalCtrl.text) ?? 0;
                        if (val < 0) return 'Inválido';
                        if (val > total) return 'Maior que total';
                        return null;
                      })),
            ]),
          ]))),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);
                    try {
                      await ref
                          .read(questionControllerProvider.notifier)
                          .addLog(
                              subjectId: _selectedSubjectId!,
                              topicId: _selectedTopicId,
                              total: int.parse(_totalCtrl.text),
                              correct: int.parse(_correctCtrl.text));
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() => _isLoading = false);
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : const Text('Salvar'))
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: (Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 16),
          child
        ]));
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final String subtitle;
  const _KpiCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value,
      this.valueColor,
      required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: (Theme.of(context).cardTheme.color ??
                Theme.of(context).cardTheme.color ??
                Theme.of(context).colorScheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: (Theme.of(context).textTheme.labelSmall?.color ??
                            Colors.grey),
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis))
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: valueColor ??
                      (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white),
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          Text(subtitle,
              style: TextStyle(
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey),
                  fontSize: 11))
        ]));
  }
}

class _LiquidVsBruteCard extends StatelessWidget {
  final int liquidMins;
  final int bruteMins;

  const _LiquidVsBruteCard({required this.liquidMins, required this.bruteMins});

  @override
  Widget build(BuildContext context) {
    final efficiency = bruteMins > 0 ? (liquidMins / bruteMins) : 0.0;
    final color = efficiency >= 0.8
        ? AppTheme.accent
        : efficiency >= 0.6
            ? AppTheme.primary
            : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cognitive Efficiency',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Qualidade do tempo líquido vs bruto',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(efficiency * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: efficiency.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.6), color]),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendItem(
                  label: 'Líquido',
                  value: '${(liquidMins / 60).toStringAsFixed(1)}h',
                  color: color),
              _LegendItem(
                  label: 'Bruto',
                  value: '${(bruteMins / 60).toStringAsFixed(1)}h',
                  color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LegendItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _GapAnalysisSection extends StatelessWidget {
  final Map<String, double> accuracyByTopic;
  final List<dynamic>
      allTopics; // Topic types vary, using dynamic for flexibility
  final List<dynamic> subjects;

  const _GapAnalysisSection({
    required this.accuracyByTopic,
    required this.allTopics,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    // Sort topics by accuracy (ascending) and filter those with enough data or poor performance
    final sortedGaps = accuracyByTopic.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final criticalGaps = sortedGaps.take(3).toList();

    if (criticalGaps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text('Gap Analysis (Focos de Atenção)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ...criticalGaps.map((gap) {
          final topic =
              allTopics.firstWhere((t) => t.id == gap.key, orElse: () => null);
          if (topic == null) return const SizedBox.shrink();

          final subject = subjects.firstWhere((s) => s.id == topic.subjectId,
              orElse: () => null);
          final subjectName = subject?.name ?? 'Geral';
          final color = subject != null
              ? Color(int.parse('FF${subject.color.replaceAll('#', '')}',
                  radix: 16))
              : Colors.grey;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subjectName,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${gap.value.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                    const Text('acerto',
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
