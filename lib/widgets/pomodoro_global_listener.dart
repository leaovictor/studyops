import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/subject_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_log_model.dart';
import '../core/theme/app_theme.dart';
import '../widgets/pomodoro_timer.dart';
import '../core/utils/app_date_utils.dart';

class PomodoroGlobalListener extends ConsumerStatefulWidget {
  final Widget child;

  const PomodoroGlobalListener({super.key, required this.child});

  @override
  ConsumerState<PomodoroGlobalListener> createState() =>
      _PomodoroGlobalListenerState();
}

class _PomodoroGlobalListenerState
    extends ConsumerState<PomodoroGlobalListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pomNotifier = ref.read(pomodoroProvider.notifier);
      pomNotifier.onSessionComplete = _showSaveDialog;
    });
  }

  void _showSaveDialog(int minutes) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SaveLogDialog(minutesCompleted: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SaveLogDialog extends ConsumerStatefulWidget {
  final int minutesCompleted;
  const _SaveLogDialog({required this.minutesCompleted});

  @override
  ConsumerState<_SaveLogDialog> createState() => _SaveLogDialogState();
}

class _SaveLogDialogState extends ConsumerState<_SaveLogDialog> {
  String? _selectedSubjectId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider).valueOrNull ?? [];

    return AlertDialog(
      backgroundColor: AppTheme.bg1,
      title: const Text('🎉 Pomodoro Finalizado!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Você focou por ${widget.minutesCompleted} minutos. Onde devemos alocar este estudo?',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.bg2,
            value: _selectedSubjectId,
            hint: const Text('Selecione uma Matéria'),
            items: subjects.map((sub) {
              return DropdownMenuItem(
                value: sub.id,
                child: Text(sub.name),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedSubjectId = val),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Descartar'),
        ),
        ElevatedButton(
          onPressed: (_selectedSubjectId == null || _saving)
              ? null
              : () async {
                  if (_selectedSubjectId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Selecione uma matéria antes de salvar.')),
                    );
                    return;
                  }

                  setState(() => _saving = true);
                  final user = ref.read(authStateProvider).valueOrNull;

                  if (user != null) {
                    final dateKey = AppDateUtils.todayKey();
                    final logId =
                        'log_${DateTime.now().millisecondsSinceEpoch}';

                    final log = StudyLog(
                      id: logId,
                      userId: user.uid,
                      date: dateKey,
                      subjectId: _selectedSubjectId!,
                      minutes: widget.minutesCompleted,
                    );

                    // Using FirebaseFirestore directly since service might not have a public create method exposed exactly
                    await FirebaseFirestore.instance
                        .collection('study_logs')
                        .doc(logId)
                        .set(log.toMap());

                    // Also invalidate dashboard metrics so it computes real time addition
                    ref.invalidate(dashboardProvider);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Salvar Log'),
        ),
      ],
    );
  }
}
