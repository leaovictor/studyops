import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_settings_controller.dart';
import '../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Account section
              const _SectionHeader(title: 'Conta'),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        user?.displayName ?? 'Usuário',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded,
                          color: AppTheme.error),
                      title: const Text('Sair da conta',
                          style: TextStyle(color: AppTheme.error)),
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pomodoro section
              const _SectionHeader(title: 'Pomodoro'),
              Consumer(builder: (context, ref, _) {
                final settingsAsync = ref.watch(pomodoroSettingsProvider);
                final settings = settingsAsync.valueOrNull;

                if (settingsAsync.hasError) {
                  return const _SettingsCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Erro ao carregar configurações',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ),
                  );
                }

                if (settings == null) {
                  return const _SettingsCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                return _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.timer_rounded,
                            color: AppTheme.primary),
                        title: const Text('Duração do foco',
                            style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${settings.workMinutes} min',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.workMinutes.toDouble(),
                            min: 5,
                            max: 90,
                            divisions: 17,
                            activeColor: AppTheme.primary,
                            onChanged: (v) => ref
                                .read(pomodoroSettingsProvider.notifier)
                                .updateSettings(
                                    v.toInt(), settings.breakMinutes),
                          ),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.coffee_rounded,
                            color: AppTheme.accent),
                        title: const Text('Pausa curta',
                            style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${settings.breakMinutes} min',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.breakMinutes.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            activeColor: AppTheme.accent,
                            onChanged: (v) => ref
                                .read(pomodoroSettingsProvider.notifier)
                                .updateSettings(
                                    settings.workMinutes, v.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
