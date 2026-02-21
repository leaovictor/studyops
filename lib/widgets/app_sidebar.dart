import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

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
    _Dest(icon: Icons.settings_rounded, label: 'Config', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const _DesktopRail(destinations: _destinations),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyOps'),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const _MobileDrawer(destinations: _destinations),
      body: child,
    );
  }
}

class _DesktopRail extends StatelessWidget {
  final List<_Dest> destinations;
  const _DesktopRail({required this.destinations});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex =
        destinations.indexWhere((d) => location.startsWith(d.path));

    return NavigationRail(
      extended: false,
      destinations: destinations
          .map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                label: Text(d.label),
              ))
          .toList(),
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onDestinationSelected: (i) => context.go(destinations[i].path),
      leading: const Padding(
        padding: EdgeInsets.only(top: 16, bottom: 24),
        child: _Logo(),
      ),
    );
  }
}

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
            ...destinations.map((d) {
              final selected = location.startsWith(d.path);
              return ListTile(
                leading: Icon(d.icon,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary),
                title: Text(d.label,
                    style: TextStyle(
                      color:
                          selected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    )),
                tileColor: selected ? AppTheme.primary.withOpacity(0.1) : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  context.go(d.path);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Study',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Ops',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final String label;
  final String path;
  const _Dest({required this.icon, required this.label, required this.path});
}
