import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/presentation/screens/calendar/calendar_screen.dart';
import 'package:iot_task_manager/presentation/screens/dashboard/dashboard_settings_screen.dart';
import 'package:iot_task_manager/presentation/screens/statistics/statistics_screen.dart';
import 'package:iot_task_manager/presentation/screens/tasks/task_list_screen.dart';
import 'package:iot_task_manager/presentation/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const <Widget>[
    TaskListScreen(),
    CalendarScreen(),
    StatisticsScreen(),
    DashboardSettingsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF161B22) : Colors.white)
                    .withValues(alpha: isDark ? 0.75 : 0.82),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: isDark ? 0.08 : 0.06),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationBarTheme: Theme.of(context)
                      .navigationBarTheme
                      .copyWith(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
                      ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _currentIndex = index),
                  height: 70,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  animationDuration: const Duration(milliseconds: 400),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.task_outlined),
                      selectedIcon: Icon(Icons.task_alt_rounded),
                      label: 'Tasks',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: 'Calendar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: 'Stats',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Display',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
