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
import 'screens/manual_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/flashcard_study_screen.dart';
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
  // Track auth + loading state of data providers to avoid race conditions
  final notifier = ValueNotifier<Object>(0);

  ref.listen(authStateProvider, (_, __) => notifier.value = Object());
  ref.listen(subjectsProvider, (_, __) => notifier.value = Object());
  ref.listen(activePlanProvider, (_, __) => notifier.value = Object());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final path = state.uri.path;

      // While auth is still resolving, stay on splash
      if (authAsync.isLoading) return path == '/' ? null : '/';

      final loggedIn = authAsync.valueOrNull != null;
      final isPublicRoute = path == '/login' || path == '/';

      if (!loggedIn && !isPublicRoute) return '/login';

      if (loggedIn && isPublicRoute) {
        final planAsync = ref.read(activePlanProvider);
        final subjectsAsync = ref.read(subjectsProvider);

        // Wait for data providers to finish loading before deciding
        if (planAsync.isLoading || subjectsAsync.isLoading) {
          return path == '/' ? null : '/';
        }

        final activePlan = planAsync.valueOrNull;
        final subjects = subjectsAsync.valueOrNull ?? [];

        // Only redirect to onboarding when data is confirmed empty
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
              path: '/flashcards',
              builder: (_, __) => const FlashcardsScreen()),
          GoRoute(
              path: '/flashcards/study',
              builder: (_, state) {
                final subjectId = state.uri.queryParameters['subjectId'];
                return FlashcardStudyScreen(subjectId: subjectId);
              }),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/manual', builder: (_, __) => const ManualScreen()),
        ],
      ),
    ],
  );
});
