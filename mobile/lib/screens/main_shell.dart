import 'package:flutter/material.dart';

import '../theme.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/focus_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/tasks_tab.dart';

/// Root shell with a 5-tab bottom navigation bar. Each tab is rebuilt when
/// selected so it always shows fresh data.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Index of the Focus tab, so other tabs can jump straight to it.
  static const int _focusIndex = 1;

  Widget _tabFor(int i) {
    switch (i) {
      case 0:
        return DashboardTab(onStartFocus: () => setState(() => _index = _focusIndex));
      case _focusIndex:
        return const FocusTab();
      case 2:
        return const TasksTab();
      case 3:
        return const StatsTab();
      default:
        return const ProfileTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // KeyedSubtree forces a fresh tab (and a refetch) on every switch.
      body: KeyedSubtree(key: ValueKey(_index), child: _tabFor(_index)),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.accent.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.muted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.muted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          height: 66,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Focus',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
