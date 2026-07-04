import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/data/repositories/task_repository_impl.dart';
import 'package:iot_task_manager/domain/entities/task.dart';
import 'package:iot_task_manager/domain/repositories/task_repository.dart';
import 'package:iot_task_manager/presentation/providers/firebase_providers.dart';
import 'package:uuid/uuid.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remote = ref.read(taskRemoteDataSourceProvider);
  final local = ref.read(taskLocalDataSourceProvider);
  final dashboard = ref.read(dashboardRemoteDataSourceProvider);
  final activityLog = ref.read(activityLogRemoteDataSourceProvider);
  return TaskRepositoryImpl(remote, local, dashboard, activityLog);
});

final taskListProvider = StreamProvider<List<Task>>((ref) {
  return ref.read(taskRepositoryProvider).getTasks();
});

final taskDetailProvider = FutureProvider.family<Task, String>(
  (ref, taskId) async {
    return ref.read(taskRepositoryProvider).getTask(taskId);
  },
);

class TaskFilterState {
  final String searchQuery;
  final String? statusFilter;
  final String? typeFilter;
  final String? categoryFilter;
  final String? priorityFilter;
  final DateTime? dateFilter;

  const TaskFilterState({
    this.searchQuery = '',
    this.statusFilter,
    this.typeFilter,
    this.categoryFilter,
    this.priorityFilter,
    this.dateFilter,
  });

  TaskFilterState copyWith({
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
    String? categoryFilter,
    String? priorityFilter,
    DateTime? dateFilter,
    bool clearDate = false,
  }) {
    return TaskFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      dateFilter: clearDate ? null : dateFilter ?? this.dateFilter,
    );
  }
}

final taskFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>(
  (ref) => TaskFilterNotifier(),
);

class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(const TaskFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type);
  }

  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
  }

  void setPriorityFilter(String? priority) {
    state = state.copyWith(priorityFilter: priority);
  }

  void setDateFilter(DateTime? date) {
    state = state.copyWith(dateFilter: date, clearDate: date == null);
  }

  void clearAll() {
    state = const TaskFilterState();
  }

  List<Task> applyFilters(List<Task> tasks) {
    var filtered = tasks;

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query);
      }).toList();
    }

    switch (state.statusFilter) {
      case 'pending':
        filtered = filtered.where((t) => t.isActive && !t.completed).toList();
      case 'completed':
        filtered = filtered.where((t) => t.completed).toList();
      case 'archived':
        filtered = filtered.where((t) => t.archived).toList();
      case 'deleted':
        filtered = filtered.where((t) => t.deleted).toList();
    }

    if (state.typeFilter != null) {
      filtered =
          filtered.where((t) => t.type.name == state.typeFilter).toList();
    }

    if (state.categoryFilter != null) {
      filtered =
          filtered.where((t) => t.category == state.categoryFilter).toList();
    }

    if (state.priorityFilter != null) {
      filtered =
          filtered.where((t) => t.priority.name == state.priorityFilter).toList();
    }

    if (state.dateFilter != null) {
      filtered = filtered.where((t) {
        return t.scheduledDate.year == state.dateFilter!.year &&
            t.scheduledDate.month == state.dateFilter!.month &&
            t.scheduledDate.day == state.dateFilter!.day;
      }).toList();
    }

    return filtered;
  }
}

class TaskActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskRepository _repository;

  TaskActionsNotifier(this._repository) : super(const AsyncData(null));

  Future<void> createTask(Task task) async {
    state = const AsyncLoading();
    try {
      final newTask = Task(
        id: const Uuid().v4(),
        title: task.title,
        description: task.description,
        type: task.type,
        scheduledDate: task.scheduledDate,
        repeatRule: task.repeatRule,
        priority: task.priority,
        category: task.category,
        order: task.order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.createTask(newTask);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    state = const AsyncLoading();
    try {
      await _repository.updateTask(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> completeTask(String taskId) async {
    await _repository.completeTask(taskId);
  }

  Future<void> undoComplete(String taskId) async {
    await _repository.undoCompleteTask(taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
  }

  Future<void> archiveTask(String taskId) async {
    await _repository.archiveTask(taskId);
  }

  Future<void> restoreTask(String taskId) async {
    await _repository.restoreTask(taskId);
  }

  Future<void> duplicateTask(String taskId) async {
    await _repository.duplicateTask(taskId);
  }

  Future<void> toggleEnabled(String taskId) async {
    await _repository.toggleEnabled(taskId);
  }
}

final taskActionsProvider =
    StateNotifierProvider<TaskActionsNotifier, AsyncValue<void>>(
  (ref) => TaskActionsNotifier(ref.read(taskRepositoryProvider)),
);
