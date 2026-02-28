import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/daily_task_controller.dart';
import '../controllers/subject_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../models/topic_model.dart';
import '../controllers/study_plan_controller.dart';
import '../widgets/study_plan_wizard_dialog.dart';
import '../controllers/quote_controller.dart';
import '../core/theme/theme_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/study_plan_model.dart';
import '../widgets/weakness_insight_card.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onRefresh() async {
    ref.invalidate(dailyTasksProvider);
    ref.invalidate(subjectsProvider);
    ref.invalidate(allTopicsProvider);
    try {
      await ref.read(dailyTasksProvider.future);
    } catch (_) {}
    _refreshController.refreshCompleted();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final subjectMap = {for (final s in subjects) s.id: s};
    final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? <Topic>[];
    final topicMap = {for (final t in allTopics) t.id: t};
    final activePlan = ref.watch(activePlanProvider).valueOrNull;

    final tasks = ref.watch(dailyTasksProvider).valueOrNull ?? [];
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width >= 600 ? 24 : 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Text(
                  'Cronograma',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                  ),
                ),
                if (activePlan != null)
                  FilledButton.tonalIcon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) =>
                          StudyPlanWizardDialog(activePlan: activePlan),
                    ),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                    label: const Text('Ajustar Plano'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : AppTheme.primary.withValues(alpha: 0.12),
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
              ],
            ),

            if (activePlan == null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comece com um Plano',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Organize seus estudos gerando um plano.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const StudyPlanWizardDialog(),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Criar Agora',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Calendar
            Container(
              decoration: BoxDecoration(
                color: (Theme.of(context).cardTheme.color ??
                    Theme.of(context).colorScheme.surface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  ref.read(selectedDateProvider.notifier).state = selected;
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _buildCalendarCell(context, day, activePlan),
                  todayBuilder: (context, day, focusedDay) =>
                      _buildCalendarCell(context, day, activePlan,
                          isToday: true),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.white)),
                  weekendTextStyle: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey)),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: (Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.white),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey)),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey)),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontSize: 12),
                  weekendStyle: TextStyle(
                      color: (Theme.of(context).textTheme.labelSmall?.color ??
                          Colors.grey),
                      fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🧠 Adaptive Weakness Insights (shown only when plan is active)
            if (activePlan != null) ...[
              const WeaknessInsightCard(),
              const SizedBox(height: 16),
            ],

            // Tasks for selected day
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Tarefas — ${AppDateUtils.displayDate(_selectedDay!)}'
                        : 'Selecione um dia',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      header: const WaterDropMaterialHeader(
                        backgroundColor: AppTheme.primary,
                      ),
                      child: tasks.isEmpty
                          ? const _EmptyScheduleQuote()
                          : AnimationLimiter(
                              child: ListView.separated(
                                itemCount: tasks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final task = tasks[i];
                                  final subject = subjectMap[task.subjectId];
                                  final topic = topicMap[task.topicId];
                                  final color = subject != null
                                      ? Color(int.parse(
                                          'FF${subject.color.replaceAll('#', '')}',
                                          radix: 16))
                                      : AppTheme.primary;
                                  return AnimationConfiguration.staggeredList(
                                    position: i,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: (Theme.of(context)
                                                    .cardTheme
                                                    .color ??
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surface),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: task.done
                                                  ? Theme.of(context)
                                                      .dividerColor
                                                  : color.withValues(
                                                      alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                task.done
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                color: task.done
                                                    ? AppTheme.accent
                                                    : (Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.color ??
                                                        Colors.grey),
                                                size: 18,
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    subject?.name ?? 'Matéria',
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  topic?.name ?? 'Tópico',
                                                  style: TextStyle(
                                                    color: task.done
                                                        ? (Theme.of(context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.color ??
                                                            Colors.grey)
                                                        : (Theme.of(context)
                                                                .textTheme
                                                                .bodyLarge
                                                                ?.color ??
                                                            Colors.white),
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                AppDateUtils.formatMinutes(
                                                    task.plannedMinutes),
                                                style: TextStyle(
                                                  color: (Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.color ??
                                                      Colors.grey),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCalendarCell(
      BuildContext context, DateTime day, StudyPlan? plan,
      {bool isToday = false}) {
    final isInPlan = plan != null &&
        day.isAfter(plan.startDate.subtract(const Duration(seconds: 1))) &&
        day.isBefore(plan.endDate.add(const Duration(seconds: 1)));

    if (isInPlan) {
      final isWeekend =
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
      Color textColor;
      if (isToday) {
        textColor = AppTheme.primary;
      } else if (isWeekend) {
        textColor =
            (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey);
      } else {
        textColor =
            (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white);
      }

      return Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: isToday ? 0.25 : 0.12),
          shape: BoxShape.circle,
          border: isToday
              ? Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday
                ? FontWeight.w900
                : (isWeekend ? FontWeight.normal : FontWeight.w600),
          ),
        ),
      );
    }
    return null; // Let default builder handle it
  }
}

class _EmptyScheduleQuote extends ConsumerWidget {
  const _EmptyScheduleQuote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  Icons.coffee_rounded,
                  color: (Theme.of(context).textTheme.labelSmall?.color ??
                      Colors.grey),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhuma tarefa planejada.',
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.white),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              quoteAsync.when(
                loading: () => const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                ),
                error: (e, _) => const SizedBox(),
                data: (quote) => Column(
                  children: [
                    Text(
                      '"${quote.text}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "- ${quote.author}",
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.labelSmall?.color ??
                            Colors.grey),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
