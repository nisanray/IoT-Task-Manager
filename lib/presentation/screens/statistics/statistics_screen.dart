import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/presentation/providers/statistics_provider.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 8),
              child: Text('Statistics',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          tasksAsync.when(
            data: (tasks) {
              final stats = ref.read(statisticsProvider(tasks));
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStreakSection(context, stats),
                    const SizedBox(height: 16),
                    _buildSectionTitle(context, 'Today'),
                    _buildStatRow(context, [
                      ('Completed', stats.dailyCompleted, AppColors.success, Icons.check_circle_rounded),
                      ('Pending', stats.dailyPending, AppColors.warning, Icons.pending_rounded),
                    ], stats.dailyCompleted + stats.dailyPending),
                    _buildProgressBar(
                        context,
                        stats.dailyCompleted,
                        stats.dailyCompleted + stats.dailyPending,
                        AppColors.success),
                    Text(
                      '${stats.dailyCompletionPercentage.toStringAsFixed(1)}% complete',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'This Week'),
                    _buildStatRow(context, [
                      ('Completed', stats.weeklyCompleted, AppColors.success, Icons.check_circle_rounded),
                      ('Pending', stats.weeklyPending, AppColors.warning, Icons.pending_rounded),
                    ], stats.weeklyCompleted + stats.weeklyPending),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'This Month'),
                    _buildStatRow(context, [
                      ('Completed', stats.monthlyCompleted, AppColors.success, Icons.check_circle_rounded),
                      ('Created', stats.monthlyCreated, AppColors.info, Icons.add_circle_rounded),
                    ], stats.monthlyCreated),
                    _buildProgressBar(
                        context,
                        stats.monthlyCompleted,
                        stats.monthlyCreated,
                        AppColors.info),
                    Text(
                      '${stats.monthlyCompletionPercentage.toStringAsFixed(1)}% completion rate',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'All Time'),
                    const SizedBox(height: 8),
                    _buildOverviewGrid(context, stats),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context, TaskStatistics stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Streak',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text('${stats.currentStreak}',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                Text('days',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            width: 1, height: 50,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Longest Streak',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text('${stats.longestStreak}',
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                Text('days',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStatRow(BuildContext context,
      List<(String, int, Color, IconData)> stats, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats.map((s) {
          final (label, value, color, icon) = s;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF161B22)
                    : Colors.white)
                    .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.6),
                border: Border.all(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.white)
                      .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(height: 8),
                    Text('$value',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: color)),
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, int completed, int total, Color color) {
    final ratio = total > 0 ? completed / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: ratio,
          backgroundColor:
              Theme.of(context).colorScheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(
      BuildContext context, TaskStatistics stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _overviewCard(
              context, 'Active', stats.totalActive, Icons.play_circle_rounded, AppColors.primary),
          _overviewCard(
              context, 'Completed', stats.totalCompleted, Icons.check_circle_rounded, AppColors.success),
          _overviewCard(
              context, 'Archived', stats.totalArchived, Icons.archive_rounded, AppColors.textSecondary),
        ].map((w) => SizedBox(width: (MediaQuery.of(context).size.width - 40) / 3 - 6, child: w)).toList(),
      ),
    );
  }

  Widget _overviewCard(BuildContext context, String label, int value,
      IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (isDark ? const Color(0xFF161B22) : Colors.white)
            .withValues(alpha: isDark ? 0.5 : 0.6),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.white)
              .withValues(alpha: isDark ? 0.08 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text('$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
