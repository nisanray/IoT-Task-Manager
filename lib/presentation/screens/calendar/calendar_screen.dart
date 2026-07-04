import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/core/widgets/empty_state_widget.dart';
import 'package:iot_task_manager/domain/entities/task.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';
import 'package:iot_task_manager/presentation/screens/tasks/task_form_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDate = DateTime.now();
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calendar',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      _CircleButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed: () => setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month - 1);
                        }),
                      ),
                      const SizedBox(width: 8),
                      _CircleButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: () => setState(() {
                          _currentMonth = DateTime(
                              _currentMonth.year, _currentMonth.month + 1);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          tasksAsync.when(
            data: (tasks) => SliverToBoxAdapter(
              child: Column(
                children: [
                  _MonthHeader(month: _currentMonth, theme: theme),
                  _CalendarGrid(
                    month: _currentMonth,
                    selectedDate: _selectedDate,
                    tasks: tasks,
                    onDaySelected: (d) =>
                        setState(() => _selectedDate = d),
                    theme: theme,
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 8),
                    _DayTasksList(
                      date: _selectedDate!,
                      tasks: tasks,
                      onTaskTap: (task) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(task: task),
                          ),
                        );
                      },
                      theme: theme,
                    ),
                  ],
                ],
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final ThemeData theme;

  const _MonthHeader({required this.month, required this.theme});

  @override
  Widget build(BuildContext context) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Text(
            '${months[month.month - 1]} ${month.year}',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        onPressed: onPressed,
        color: Theme.of(context).colorScheme.primary,
        splashRadius: 22,
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDate;
  final List<Task> tasks;
  final ValueChanged<DateTime> onDaySelected;
  final ThemeData theme;

  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.tasks,
    required this.onDaySelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(d,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final day = index - firstWeekday + 2;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox();
              }
              final date = DateTime(month.year, month.month, day);
              final isToday = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              final isSelected = selectedDate != null &&
                  date.day == selectedDate!.day &&
                  date.month == selectedDate!.month &&
                  date.year == selectedDate!.year;

              final dayTasks = tasks.where((t) =>
                  t.scheduledDate.year == date.year &&
                  t.scheduledDate.month == date.month &&
                  t.scheduledDate.day == date.day && !t.deleted);
              final pendingCount = dayTasks.where((t) => !t.completed).length;
              final completedCount = dayTasks.where((t) => t.completed).length;

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF161B22)
                                : Colors.white)
                                .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected || isToday
                        ? null
                        : Border.all(
                            color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.white)
                                .withValues(alpha: 0.06),
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (pendingCount > 0)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (pendingCount > 0 && completedCount > 0)
                            const SizedBox(width: 3),
                          if (completedCount > 0)
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : theme.colorScheme.outline,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayTasksList extends StatelessWidget {
  final DateTime date;
  final List<Task> tasks;
  final void Function(Task) onTaskTap;
  final ThemeData theme;

  const _DayTasksList({
    required this.date,
    required this.tasks,
    required this.onTaskTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dayTasks = tasks.where((t) =>
        t.scheduledDate.year == date.year &&
        t.scheduledDate.month == date.month &&
        t.scheduledDate.day == date.day).toList();

    if (dayTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: EmptyStateWidget(
          icon: Icons.event_busy_rounded,
          title: 'No tasks',
          subtitle: 'Nothing scheduled for this day',
        ),
      );
    }

    final pending =
        dayTasks.where((t) => !t.completed && !t.deleted).toList();
    final completed = dayTasks.where((t) => t.completed).toList();
    final archived = dayTasks.where((t) => t.archived).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '${dayTasks.length} task${dayTasks.length != 1 ? 's' : ''}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (pending.isNotEmpty) ...[
            _TaskSection(
              title: 'Pending',
              count: pending.length,
              color: AppColors.primary,
              tasks: pending,
              onTaskTap: onTaskTap,
            ),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TaskSection(
              title: 'Completed',
              count: completed.length,
              color: AppColors.success,
              tasks: completed,
              onTaskTap: onTaskTap,
            ),
          ],
          if (archived.isNotEmpty) ...[
            const SizedBox(height: 8),
            _TaskSection(
              title: 'Archived',
              count: archived.length,
              color: theme.colorScheme.outline,
              tasks: archived,
              onTaskTap: onTaskTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final List<Task> tasks;
  final void Function(Task) onTaskTap;

  const _TaskSection({
    required this.title,
    required this.count,
    required this.color,
    required this.tasks,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('$title ($count)',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ...tasks.map((t) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (isDark ? const Color(0xFF161B22) : Colors.white)
                  .withValues(alpha: isDark ? 0.5 : 0.6),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.white)
                    .withValues(alpha: isDark ? 0.06 : 0.12),
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(t.title,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(t.category,
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
              onTap: () => onTaskTap(t),
            ),
          );
        }),
      ],
    );
  }
}
