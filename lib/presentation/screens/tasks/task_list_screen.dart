import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/theme/app_theme.dart';
import 'package:iot_task_manager/core/widgets/empty_state_widget.dart';
import 'package:iot_task_manager/core/widgets/loading_widget.dart';
import 'package:iot_task_manager/domain/entities/task.dart';
import 'package:iot_task_manager/presentation/providers/task_provider.dart';
import 'package:iot_task_manager/presentation/screens/tasks/task_form_screen.dart';
import 'package:iot_task_manager/presentation/widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Tasks',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.search_rounded,
                            onPressed: () =>
                                _showSearch(context, ref),
                          ),
                          const SizedBox(width: 8),
                          _CircleIconButton(
                            icon: Icons.tune_rounded,
                            onPressed: () =>
                                _showFilterSheet(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(tasksAsync, filter),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          tasksAsync.when(
            data: (tasks) {
              final filtered = ref
                  .read(taskFilterProvider.notifier)
                  .applyFilters(tasks);

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 96,
                    ),
                    child: EmptyStateWidget(
                      icon: Icons.task_alt_rounded,
                      title: filter.searchQuery.isNotEmpty
                          ? 'No matches found'
                          : 'No tasks yet',
                      subtitle: filter.searchQuery.isNotEmpty
                          ? 'Try a different search term'
                          : 'Tap the + button to create your first task',
                      action: filter.searchQuery.isEmpty
                          ? FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TaskFormScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded,
                                  size: 18),
                              label: const Text('Create Task'),
                            )
                          : null,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = filtered[index];
                      return TaskCard(
                        task: task,
                        index: index,
                        onToggleComplete: () {
                          if (task.completed) {
                            ref
                                .read(taskActionsProvider.notifier)
                                .undoComplete(task.id);
                          } else {
                            ref
                                .read(taskActionsProvider.notifier)
                                .completeTask(task.id);
                          }
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            _buildTaskDetailRoute(task),
                          );
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 96,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TaskListShimmer(itemCount: 3),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your tasks...',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 40, right: 40, top: 40,
                  bottom: MediaQuery.of(context).padding.bottom + 96,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 36,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your connection and try again',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            _buildTaskDetailRoute(null),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  String _getSubtitle(
      AsyncValue<List<Task>> tasksAsync, TaskFilterState filter) {
    return tasksAsync.whenOrNull(
          data: (tasks) {
            if (filter.searchQuery.isNotEmpty) {
              return 'Searching "${filter.searchQuery}"';
            }
            final active = tasks.where((t) => t.isActive).length;
            final completed = tasks.where((t) => t.completed).length;
            return '$active active  ·  $completed completed';
          },
        ) ??
        '';
  }

  Route _buildTaskDetailRoute(Task? task) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          TaskFormScreen(task: task),
      transitionsBuilder:
          (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showSearch(
      context: context,
      delegate: _TaskSearchDelegate(ref),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final filter = ref.read(taskFilterProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FilterSheet(
        currentFilter: filter,
        onApply: (newFilter) {
          ref
              .read(taskFilterProvider.notifier)
              .setStatusFilter(newFilter.statusFilter);
          ref
              .read(taskFilterProvider.notifier)
              .setTypeFilter(newFilter.typeFilter);
          ref
              .read(taskFilterProvider.notifier)
              .setPriorityFilter(newFilter.priorityFilter);
          Navigator.of(ctx).pop();
        },
        onClear: () {
          ref.read(taskFilterProvider.notifier).clearAll();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

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

class _TaskSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;

  _TaskSearchDelegate(this.ref);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchList(context);

  Widget _buildSearchList(BuildContext context) {
    ref.read(taskFilterProvider.notifier).setSearchQuery(query);
    final tasksAsync = ref.watch(taskListProvider);

    return tasksAsync.when(
      data: (tasks) {
        final filtered =
            ref.read(taskFilterProvider.notifier).applyFilters(tasks);
        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No results',
            subtitle: query.isNotEmpty
                ? 'No tasks match "$query"'
                : 'Type to search tasks',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final task = filtered[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.task_alt_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(task.category,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textSecondary),
                onTap: () {
                  close(context, null);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(task: task),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const TaskListShimmer(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final TaskFilterState currentFilter;
  final Function(TaskFilterState) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.currentFilter,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _statusFilter;
  late String? _typeFilter;
  late String? _priorityFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.currentFilter.statusFilter;
    _typeFilter = widget.currentFilter.typeFilter;
    _priorityFilter = widget.currentFilter.priorityFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: (isDark ? const Color(0xFF161B22) : Colors.white)
            .withValues(alpha: isDark ? 0.6 : 0.7),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FilterSection(
            title: 'Status',
            options: const ['All', 'Pending', 'Completed', 'Archived', 'Deleted'],
            values: const [null, 'pending', 'completed', 'archived', 'deleted'],
            selected: _statusFilter,
            onSelected: (v) => setState(() => _statusFilter = v),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'Type',
            options: const [
              'All',
              'Today',
              'Daily',
              'Constant',
              'Weekly',
              'Monthly',
            ],
            values: const [
              null,
              'today',
              'daily',
              'constant',
              'weekly',
              'monthly',
            ],
            selected: _typeFilter,
            onSelected: (v) => setState(() => _typeFilter = v),
          ),
          const SizedBox(height: 20),
          _FilterSection(
            title: 'Priority',
            options: const ['All', 'Critical', 'High', 'Medium', 'Low'],
            values: const [null, 'critical', 'high', 'medium', 'low'],
            selected: _priorityFilter,
            onSelected: (v) => setState(() => _priorityFilter = v),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => widget.onApply(TaskFilterState(
                statusFilter: _statusFilter,
                typeFilter: _typeFilter,
                priorityFilter: _priorityFilter,
              )),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String?> values;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (i) {
            final isSelected = selected == values[i];
            return ChoiceChip(
              label: Text(options[i]),
              selected: isSelected,
              onSelected: (_) => onSelected(values[i]),
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              backgroundColor: Colors.transparent,
            );
          }),
        ),
      ],
    );
  }
}
