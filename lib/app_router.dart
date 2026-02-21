import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'controllers/auth_controller.dart';
import 'controllers/study_plan_controller.dart';
import 'controllers/subject_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/daily_checklist_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/error_notebook_screen.dart';
import 'screens/subjects_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_sidebar.dart';

// Provides AppSidebar shell
class _ShellPage extends ConsumerWidget {
  final Widget child;
  const _ShellPage({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppSidebar(child: child);
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Track both the auth value AND the loading state
  final notifier = ValueNotifier<(bool, bool)>((true, false));

  ref.listen(authStateProvider, (_, next) {
    notifier.value = (next.isLoading, next.valueOrNull != null);
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final (isLoading, loggedIn) = notifier.value;
      final path = state.uri.path;

      // While auth is still resolving, stay on splash
      if (isLoading) return path == '/' ? null : '/';

      final isPublicRoute = path == '/login' || path == '/';

      if (!loggedIn && !isPublicRoute) return '/login';

      if (loggedIn && isPublicRoute) {
        // Check if user needs onboarding (no active plan and no subjects)
        final activePlan = ref.read(activePlanProvider).valueOrNull;
        final subjects = ref.read(subjectsProvider).valueOrNull ?? [];
        if (activePlan == null && subjects.isEmpty && path != '/onboarding') {
          return '/onboarding';
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => _ShellPage(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/checklist',
              builder: (_, __) => const DailyChecklistScreen()),
          GoRoute(
              path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(
              path: '/performance',
              builder: (_, __) => const PerformanceScreen()),
          GoRoute(
              path: '/errors', builder: (_, __) => const ErrorNotebookScreen()),
          GoRoute(
              path: '/subjects', builder: (_, __) => const SubjectsScreen()),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
