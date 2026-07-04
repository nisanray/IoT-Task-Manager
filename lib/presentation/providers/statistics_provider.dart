import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/domain/entities/task.dart';

class TaskStatistics {
  final int dailyCompleted;
  final int dailyPending;
  final double dailyCompletionPercentage;
  final int weeklyCompleted;
  final int weeklyPending;
  final int monthlyCompleted;
  final int monthlyCreated;
  final double monthlyCompletionPercentage;
  final int currentStreak;
  final int longestStreak;
  final int totalActive;
  final int totalCompleted;
  final int totalArchived;

  const TaskStatistics({
    this.dailyCompleted = 0,
    this.dailyPending = 0,
    this.dailyCompletionPercentage = 0,
    this.weeklyCompleted = 0,
    this.weeklyPending = 0,
    this.monthlyCompleted = 0,
    this.monthlyCreated = 0,
    this.monthlyCompletionPercentage = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalActive = 0,
    this.totalCompleted = 0,
    this.totalArchived = 0,
  });
}

final statisticsProvider = Provider.family<TaskStatistics, List<Task>>(
  (ref, tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final active = tasks.where((t) => t.isActive).toList();
    final completed = tasks.where((t) => t.completed).toList();
    final archived = tasks.where((t) => t.archived).toList();

    final dailyCompleted = completed.where((t) {
      if (t.completedAt == null) return false;
      final ct = t.completedAt!;
      return ct.year == today.year &&
          ct.month == today.month &&
          ct.day == today.day;
    }).length;

    final dailyPending = active.where((t) {
      return t.scheduledDate.year == today.year &&
          t.scheduledDate.month == today.month &&
          t.scheduledDate.day == today.day;
    }).length;

    final weeklyCompleted = completed.where((t) {
      if (t.completedAt == null) return false;
      return t.completedAt!.isAfter(weekStart);
    }).length;

    final weeklyPending = active.where((t) {
      return t.scheduledDate.isAfter(weekStart) &&
          t.scheduledDate.isBefore(weekStart.add(const Duration(days: 7)));
    }).length;

    final monthlyCompleted = completed.where((t) {
      if (t.completedAt == null) return false;
      return t.completedAt!.isAfter(monthStart);
    }).length;

    final monthlyCreated = tasks.where((t) {
      return t.createdAt.isAfter(monthStart);
    }).length;

    final totalDueToday = dailyCompleted + dailyPending;
    final dailyPercentage =
        totalDueToday > 0 ? (dailyCompleted / totalDueToday) * 100 : 0.0;
    final monthlyPercentage =
        monthlyCreated > 0 ? (monthlyCompleted / monthlyCreated) * 100 : 0.0;

    final completedDates = completed
        .where((t) => t.completedAt != null)
        .map((t) => t.completedAt!)
        .toList();

    int currentStreak = _calculateStreak(completedDates);
    int longestStreak = _calculateLongestStreak(completedDates);

    return TaskStatistics(
      dailyCompleted: dailyCompleted,
      dailyPending: dailyPending,
      dailyCompletionPercentage: dailyPercentage,
      weeklyCompleted: weeklyCompleted,
      weeklyPending: weeklyPending,
      monthlyCompleted: monthlyCompleted,
      monthlyCreated: monthlyCreated,
      monthlyCompletionPercentage: monthlyPercentage,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalActive: active.length,
      totalCompleted: completed.length,
      totalArchived: archived.length,
    );
  },
);

int _calculateStreak(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final sorted = List<DateTime>.from(dates)
    ..sort((a, b) => b.compareTo(a));
  final unique = <DateTime>{};
  for (final d in sorted) {
    unique.add(DateTime(d.year, d.month, d.day));
  }
  final uniqueSorted = unique.toList()..sort((a, b) => b.compareTo(a));
  int streak = 1;
  for (int i = 0; i < uniqueSorted.length - 1; i++) {
    final diff = uniqueSorted[i].difference(uniqueSorted[i + 1]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int _calculateLongestStreak(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final sorted = List<DateTime>.from(dates)..sort();
  final unique = <DateTime>{};
  for (final d in sorted) {
    unique.add(DateTime(d.year, d.month, d.day));
  }
  final uniqueSorted = unique.toList()..sort();
  int longest = 1;
  int current = 1;
  for (int i = 0; i < uniqueSorted.length - 1; i++) {
    final diff = uniqueSorted[i + 1].difference(uniqueSorted[i]).inDays;
    if (diff == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
