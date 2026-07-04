import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/data/datasources/local/task_local_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/activity_log_remote_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/task_remote_datasource.dart';
import 'package:iot_task_manager/data/models/activity_log_model.dart';
import 'package:iot_task_manager/data/models/dashboard_model.dart';
import 'package:iot_task_manager/data/models/dashboard_settings_model.dart';
import 'package:iot_task_manager/data/models/task_model.dart';
import 'package:iot_task_manager/domain/entities/dashboard.dart';
import 'package:iot_task_manager/domain/entities/task.dart';
import 'package:iot_task_manager/domain/repositories/task_repository.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;
  final TaskLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _dashboardRemoteDataSource;
  final ActivityLogRemoteDataSource _activityLogRemoteDataSource;

  TaskRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._dashboardRemoteDataSource,
    this._activityLogRemoteDataSource,
  );

  @override
  Stream<List<Task>> getTasks() {
    return _remoteDataSource.getTasks().map((models) {
      final tasks = models.map((m) => m.toEntity()).toList();
      _localDataSource.cacheTasks(models);
      return tasks;
    });
  }

  @override
  Future<Task> getTask(String taskId) async {
    final model = await _remoteDataSource.getTask(taskId);
    return model.toEntity();
  }

  @override
  Future<void> createTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    await _remoteDataSource.createTask(model);
    await _logActivity('Task Created', 'Created task "${task.title}"',
        taskId: task.id, taskTitle: task.title);
    await _regenerateDashboard();
  }

  @override
  Future<void> updateTask(Task task) async {
    final model = TaskModel.fromEntity(
      task.copyWith(updatedAt: DateTime.now()),
    );
    await _remoteDataSource.updateTask(model);
    await _logActivity('Task Updated', 'Updated task "${task.title}"',
        taskId: task.id, taskTitle: task.title);
    await _regenerateDashboard();
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      deleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
    await _logActivity('Task Deleted', 'Deleted task "${task.title}"',
        taskId: taskId, taskTitle: task.title);
  }

  @override
  Future<void> completeTask(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      completed: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
    await _logActivity('Task Completed', 'Completed task "${task.title}"',
        taskId: taskId, taskTitle: task.title);
  }

  @override
  Future<void> undoCompleteTask(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      completed: false,
      clearCompletedAt: true,
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
    await _logActivity('Task Restored', 'Restored task "${task.title}"',
        taskId: taskId, taskTitle: task.title);
  }

  @override
  Future<void> archiveTask(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
    await _logActivity('Task Archived', 'Archived task "${task.title}"',
        taskId: taskId, taskTitle: task.title);
  }

  @override
  Future<void> restoreTask(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      archived: false,
      deleted: false,
      deletedAt: null,
      clearDeletedAt: true,
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
    await _logActivity('Task Restored', 'Restored task "${task.title}"',
        taskId: taskId, taskTitle: task.title);
  }

  @override
  Future<void> duplicateTask(String taskId) async {
    final task = await getTask(taskId);
    final newTask = Task(
      id: const Uuid().v4(),
      title: '${task.title} (Copy)',
      description: task.description,
      type: task.type,
      scheduledDate: task.scheduledDate,
      repeatRule: task.repeatRule,
      priority: task.priority,
      category: task.category,
      order: task.order + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await createTask(newTask);
  }

  @override
  Future<void> toggleEnabled(String taskId) async {
    final task = await getTask(taskId);
    final updated = task.copyWith(
      enabled: !task.enabled,
      updatedAt: DateTime.now(),
    );
    await updateTask(updated);
  }

  @override
  Future<void> reorderTasks(List<Task> tasks) async {
    for (int i = 0; i < tasks.length; i++) {
      final model = TaskModel.fromEntity(
        tasks[i].copyWith(order: i, updatedAt: DateTime.now()),
      );
      await _remoteDataSource.updateTask(model);
    }
    await _regenerateDashboard();
  }

  @override
  Future<void> permanentlyDeleteTask(String taskId) async {
    await _remoteDataSource.deleteTask(taskId);
  }

  Future<void> _logActivity(String action, String description,
      {String? taskId, String? taskTitle}) async {
    final log = ActivityLogModel(
      id: const Uuid().v4(),
      action: action,
      description: description,
      taskId: taskId,
      taskTitle: taskTitle,
      createdAt: Timestamp.now(),
    );
    await _activityLogRemoteDataSource.logActivity(log);
  }

  Future<void> _regenerateDashboard() async {
    try {
      final tasks = await _remoteDataSource.getTasks().first;
      final settings = await _dashboardRemoteDataSource.getDashboardSettings();
      final dashboard = _buildDashboard(tasks, settings);
      await _dashboardRemoteDataSource.generateDashboard(dashboard);
    } catch (_) {}
  }

  DashboardModel _buildDashboard(
      List<TaskModel> tasks, DashboardSettingsModel settings) {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final activeTasks = tasks
        .where((t) =>
            !t.deleted && !t.archived && t.enabled && !t.completed && t.showOnEsp32)
        .map((t) => t.toEntity())
        .toList();

    final todayItems = <DashboardItem>[];
    final dailyItems = <DashboardItem>[];
    final constantItems = <DashboardItem>[];

    for (final task in activeTasks) {
      switch (task.type) {
        case TaskType.today:
        case TaskType.customDate:
          if (task.scheduledDate.year == now.year &&
              task.scheduledDate.month == now.month &&
              task.scheduledDate.day == now.day) {
            todayItems.add(DashboardItem(
                id: task.id, text: task.title, description: task.description));
          }
        case TaskType.daily:
          dailyItems.add(DashboardItem(
              id: task.id, text: task.title, description: task.description));
        case TaskType.constant:
          constantItems.add(DashboardItem(
              id: task.id, text: task.title, description: task.description));
        case TaskType.weekly:
          if (settings.showWeeklyTasks && task.repeatRule != null) {
            final dayNames = [
              'monday', 'tuesday', 'wednesday', 'thursday',
              'friday', 'saturday', 'sunday',
            ];
            final todayName = dayNames[now.weekday - 1];
            if (task.repeatRule!.weekdays.contains(todayName)) {
              todayItems.add(DashboardItem(
                  id: task.id, text: task.title, description: task.description));
            }
          }
        case TaskType.monthly:
          if (settings.showMonthlyTasks &&
              task.scheduledDate.day == now.day) {
            todayItems.add(DashboardItem(
                id: task.id, text: task.title, description: task.description));
          }
      }
    }

    final maxItems = settings.maxTasksPerSection;

    return DashboardModel(
      version: 1,
      generatedDate: todayStr,
      generatedAt: DateTime.now().toIso8601String(),
      displayMode: settings.displayMode,
      rotationInterval: settings.rotationInterval,
      today: settings.showTodayTasks
          ? todayItems
              .take(maxItems)
              .map((e) => DashboardItemModel(
                  id: e.id, text: e.text, description: e.description))
              .toList()
          : [],
      daily: settings.showDailyTasks
          ? dailyItems
              .take(maxItems)
              .map((e) => DashboardItemModel(
                  id: e.id, text: e.text, description: e.description))
              .toList()
          : [],
      constant: settings.showConstantTasks
          ? constantItems
              .take(maxItems)
              .map((e) => DashboardItemModel(
                  id: e.id, text: e.text, description: e.description))
              .toList()
          : [],
    );
  }
}
