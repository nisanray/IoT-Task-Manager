import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/presentation/providers/statistics_provider.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
                    const SizedBox(height: 20),
                    _buildSectionTitle(context, 'Today\'s Progress'),
                    const SizedBox(height: 8),
                    _buildTodayRing(context, stats),
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
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'Overview'),
                    const SizedBox(height: 12),
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
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        color: Colors.white.withValues(alpha: 0.9), size: 20),
                    const SizedBox(width: 6),
                    Text('Current Streak',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
                const SizedBox(height: 6),
                _AnimatedCounter(
                  value: stats.currentStreak,
                  animation: _animController,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                ),
                Text('days',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.6))),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Best',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                    const SizedBox(width: 6),
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.white.withValues(alpha: 0.9), size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                _AnimatedCounter(
                  value: stats.longestStreak,
                  animation: _animController,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                ),
                Text('days',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRing(BuildContext context, TaskStatistics stats) {
    final total = stats.dailyCompleted + stats.dailyPending;
    final ratio = total > 0 ? stats.dailyCompleted / total : 0.0;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (theme.brightness == Brightness.dark
            ? const Color(0xFF161B22)
            : Colors.white)
            .withValues(alpha: theme.brightness == Brightness.dark ? 0.5 : 0.6),
        border: Border.all(
          color: (theme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black)
              .withValues(alpha: theme.brightness == Brightness.dark ? 0.08 : 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _AnimatedCircularProgress(
            ratio: ratio,
            animation: _animController,
            color: AppColors.success,
            size: 80,
            strokeWidth: 8,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.dailyCompleted} of $total completed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.dailyCompletionPercentage.toStringAsFixed(0)}% complete today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                      : Colors.black)
                      .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.06),
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
                    _AnimatedCounter(
                      value: value,
                      animation: _animController,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, color: color),
                    ),
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
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return LinearProgressIndicator(
              value: ratio * _animController.value,
              backgroundColor:
                  Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context, TaskStatistics stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _OverviewCard(
              label: 'Active',
              value: stats.totalActive,
              icon: Icons.play_circle_rounded,
              color: AppColors.primary,
              animation: _animController,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OverviewCard(
              label: 'Completed',
              value: stats.totalCompleted,
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              animation: _animController,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OverviewCard(
              label: 'Archived',
              value: stats.totalArchived,
              icon: Icons.archive_rounded,
              color: AppColors.textSecondary,
              animation: _animController,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Animation<double> animation;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (isDark ? const Color(0xFF161B22) : Colors.white)
            .withValues(alpha: isDark ? 0.5 : 0.6),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isDark ? 0.08 : 0.06),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            _AnimatedCounter(
              value: value,
              animation: animation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final int value;
  final Animation<double> animation;
  final TextStyle? style;

  const _AnimatedCounter({
    required this.value,
    required this.animation,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final displayed = (value * animation.value).round();
        return Text(
          '$displayed',
          style: style,
        );
      },
    );
  }
}

class _AnimatedCircularProgress extends StatelessWidget {
  final double ratio;
  final Animation<double> animation;
  final Color color;
  final double size;
  final double strokeWidth;

  const _AnimatedCircularProgress({
    required this.ratio,
    required this.animation,
    required this.color,
    this.size = 80,
    this.strokeWidth = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: ratio * animation.value,
                  strokeWidth: strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(ratio * 100 * animation.value).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
