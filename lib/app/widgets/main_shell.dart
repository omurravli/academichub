import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:studiq/app/theme/app_theme.dart';
import 'package:studiq/features/today/presentation/screens/today_screen.dart';
import 'package:studiq/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:studiq/features/planner/presentation/screens/planner_screen.dart';
import 'package:studiq/features/timer/presentation/screens/timer_screen.dart';
import 'package:studiq/features/projects/presentation/screens/projects_screen.dart';
import 'package:studiq/features/settings/presentation/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _paths = [
    '/today',
    '/calendar',
    '/planner',
    '/focus',
    '/projects',
    '/settings',
  ];

  static const _pages = [
    TodayScreen(),
    CalendarScreen(),
    PlannerScreen(),
    TimerScreen(),
    ProjectsScreen(),
    SettingsScreen(),
  ];

  static const _tabs = [
    _NavTab(label: 'Today', icon: Icons.today_outlined, selectedIcon: Icons.today),
    _NavTab(label: 'Calendar', icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
    _NavTab(label: 'Planner', icon: Icons.checklist_outlined, selectedIcon: Icons.checklist),
    _NavTab(label: 'Focus', icon: Icons.timer_outlined, selectedIcon: Icons.timer),
    _NavTab(label: 'Projects', icon: Icons.folder_outlined, selectedIcon: Icons.folder),
    _NavTab(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    context.go(_paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          ColoredBox(
            color: cs.surface,
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).padding.top + 12,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                context.go(_paths[index]);
              },
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(cs, isDark),
    );
  }

  Widget _buildBottomNav(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark
                ? AppColors.darkSurfaceContainerLow
                : AppColors.lightSurfaceContainerLowest)
            .withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.softShadowDark : AppColors.softShadowLight,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final selected = i == _currentIndex;
              return GestureDetector(
                onTap: () => _onTabTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Icon(
                          selected ? tab.selectedIcon : tab.icon,
                          color:
                              selected ? cs.primary : cs.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: AppTextStyles.labelSm(
                          color: selected
                              ? cs.primary
                              : cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}