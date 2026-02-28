import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'controllers/auth_controller.dart';
import 'controllers/study_plan_controller.dart';
import 'controllers/subject_controller.dart';
import 'controllers/goal_controller.dart';
import 'screens/login_screen.dart';
import 'screens/landing_screen.dart';
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
import 'screens/admin_dashboard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/achievements_screen.dart';
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
  final notifier = ValueNotifier<Object>(0);

  // Use listenSelf or similar to avoid race conditions if needed,
  // but here we just want to refresh GoRouter when these providers change.
  void refresh() => notifier.value = Object();

  ref.listen(authControllerProvider, (_, __) => refresh());
  ref.listen(subjectsProvider, (_, __) => refresh());
  ref.listen(activePlanProvider, (_, __) => refresh());
  ref.listen(goalsProvider, (_, __) => refresh());

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.uri.path;

      // While auth is still resolving, stay on splash or login
      if (authState.isLoading) {
        if (path == '/' || path == '/login') return null;
        return '/';
      }

      final user = authState.valueOrNull;
      final loggedIn = user != null;
      final isLandingRoute = path == '/';
      final isLoginRoute = path == '/login';

      if (!loggedIn) {
        if (isLandingRoute || isLoginRoute) return null;
        return '/'; // Go to landing page
      }

      // If logged in and on a public route, determine where to go next
      if (isLandingRoute || isLoginRoute) {
        final planAsync = ref.read(activePlanProvider);
        final subjectsAsync = ref.read(subjectsProvider);
        final goalsAsync = ref.read(goalsProvider);

        // Wait for essential data providers to finish loading before deciding
        if (planAsync.isLoading ||
            subjectsAsync.isLoading ||
            goalsAsync.isLoading) {
          return path == '/' ? null : '/';
        }

        final goals = goalsAsync.valueOrNull ?? [];

        // Only redirect to onboarding when data is confirmed empty
        if (goals.isEmpty && path != '/onboarding') {
          return '/onboarding';
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LandingScreen(),
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
          GoRoute(
              path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/quiz', builder: (_, __) => const QuizScreen()),
          GoRoute(
              path: '/achievements',
              builder: (_, __) => const AchievementsScreen()),
        ],
      ),
    ],
  );
});
