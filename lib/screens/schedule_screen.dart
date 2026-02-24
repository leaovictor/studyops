import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../controllers/daily_task_controller.dart';
import '../controllers/subject_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_date_utils.dart';
import '../models/topic_model.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];
    final subjectMap = {for (final s in subjects) s.id: s};
    final allTopics = ref.watch(allTopicsProvider).valueOrNull ?? <Topic>[];
    final topicMap = {for (final t in allTopics) t.id: t};

    // Watch tasks for selected day
    final tasks = ref.watch(dailyTasksProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cronograma',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Calendar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
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
                calendarStyle: CalendarStyle(
                  defaultTextStyle:
                      const TextStyle(color: AppTheme.textPrimary),
                  weekendTextStyle:
                      const TextStyle(color: AppTheme.textSecondary),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.3),
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
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left_rounded,
                      color: AppTheme.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  weekendStyle:
                      TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tasks for selected day
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Tarefas — ${AppDateUtils.displayDate(_selectedDay!)}'
                        : 'Selecione um dia',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'Sem tarefas neste dia',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
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
                                          color: AppTheme.bg2,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: task.done
                                                ? AppTheme.border
                                                : color.withOpacity(0.3),
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
                                                  : AppTheme.textMuted,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
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
                                            Expanded(
                                              child: Text(
                                                topic?.name ?? 'Tópico',
                                                style: TextStyle(
                                                  color: task.done
                                                      ? AppTheme.textMuted
                                                      : AppTheme.textPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              AppDateUtils.formatMinutes(
                                                  task.plannedMinutes),
                                              style: const TextStyle(
                                                color: AppTheme.textMuted,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
