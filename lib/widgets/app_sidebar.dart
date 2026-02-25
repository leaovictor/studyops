import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import 'goal_switcher.dart';
import 'pomodoro_global_listener.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSidebar extends StatelessWidget {
  final Widget child;

  const AppSidebar({super.key, required this.child});

  static const _destinations = [
    _Dest(
        icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/dashboard'),
    _Dest(
        icon: Icons.checklist_rounded, label: 'Checklist', path: '/checklist'),
    _Dest(
        icon: Icons.calendar_month_rounded,
        label: 'Cronograma',
        path: '/schedule'),
    _Dest(
        icon: Icons.bar_chart_rounded,
        label: 'Performance',
        path: '/performance'),
    _Dest(icon: Icons.book_rounded, label: 'Caderno', path: '/errors'),
    _Dest(icon: Icons.school_rounded, label: 'Matérias', path: '/subjects'),
    _Dest(icon: Icons.style_rounded, label: 'Flashcards', path: '/flashcards'),
    _Dest(
        icon: Icons.help_outline_rounded,
        label: 'Guia do App',
        path: '/manual'),
    _Dest(icon: Icons.settings_rounded, label: 'Config', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    if (isDesktop) {
      return PomodoroGlobalListener(
        child: Scaffold(
          body: Row(
            children: [
              const _ExpandedSidebar(destinations: _destinations),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    if (isTablet) {
      return PomodoroGlobalListener(
        child: Scaffold(
          body: Row(
            children: [
              const _CompactRail(destinations: _destinations),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // Mobile: drawer + app bar
    return PomodoroGlobalListener(
      child: Scaffold(
        appBar: AppBar(
          title: const _Logo(),
          // Removed explicit IconButton from actions since 'drawer' automatically
          // adds a hamburger menu as the leading widget.
        ),
        drawer: const _MobileDrawer(destinations: _destinations),
        body: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: full expanded sidebar (240px)
// ---------------------------------------------------------------------------
class _ExpandedSidebar extends StatelessWidget {
  final List<_Dest> destinations;
  const _ExpandedSidebar({required this.destinations});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _Logo(),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: GoalSwitcher(),
                ),
                const SizedBox(height: 8),
                ...destinations.map((d) {
                  final selected = location.startsWith(d.path);
                  return _SidebarItem(
                    dest: d,
                    selected: selected,
                    onTap: () => context.go(d.path),
                  );
                }),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _ThemeToggle(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Left accent bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 3,
              height: 18,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Icon(
              dest.icon,
              size: 20,
              color: selected
                  ? AppTheme.primary
                  : (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dest.label,
                style: TextStyle(
                  color: selected
                      ? AppTheme.primary
                      : (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet: compact icon-only rail (72px)
// ---------------------------------------------------------------------------
class _CompactRail extends StatelessWidget {
  final List<_Dest> destinations;
  const _CompactRail({required this.destinations});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Container(
      width: 72,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child:
                  Icon(Icons.school_rounded, color: AppTheme.primary, size: 28),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: 8),
          const GoalSwitcher(compact: true),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: destinations.map((d) {
                final selected = location.startsWith(d.path);
                return Tooltip(
                  message: d.label,
                  preferBelow: false,
                  child: GestureDetector(
                    onTap: () => context.go(d.path),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        d.icon,
                        size: 22,
                        color: selected
                            ? AppTheme.primary
                            : (Theme.of(context).textTheme.bodySmall?.color ??
                                Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: _ThemeToggle(compact: true),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile: drawer
// ---------------------------------------------------------------------------
class _MobileDrawer extends StatelessWidget {
  final List<_Dest> destinations;
  const _MobileDrawer({required this.destinations});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: _Logo(),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: GoalSwitcher(),
                  ),
                  const Divider(),
                  ...destinations.map((d) {
                    final selected = location.startsWith(d.path);
                    return _SidebarItem(
                      dest: d,
                      selected: selected,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(d.path);
                      },
                    );
                  }),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _ThemeToggle(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo
// ---------------------------------------------------------------------------
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'StudyOps',
          style: TextStyle(
            color:
                (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------
class _Dest {
  final IconData icon;
  final String label;
  final String path;
  const _Dest({required this.icon, required this.label, required this.path});
}

// ---------------------------------------------------------------------------
// Theme Toggle
// ---------------------------------------------------------------------------
class _ThemeToggle extends ConsumerWidget {
  final bool compact;

  const _ThemeToggle({this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    if (compact) {
      return IconButton(
        icon: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
          size: 22,
        ),
        onPressed: () {
          ref.read(themeProvider.notifier).setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
        },
        tooltip: isDark ? 'Modo Claro' : 'Modo Escuro',
      );
    }

    return InkWell(
      onTap: () {
        ref.read(themeProvider.notifier).setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            );
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isDark ? 'Modo Claro' : 'Modo Escuro',
                style: TextStyle(
                  color: (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
