import 'package:iot_task_manager/domain/entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> getTasks();
  Future<Task> getTask(String taskId);
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String taskId);
  Future<void> completeTask(String taskId);
  Future<void> undoCompleteTask(String taskId);
  Future<void> archiveTask(String taskId);
  Future<void> restoreTask(String taskId);
  Future<void> duplicateTask(String taskId);
  Future<void> toggleEnabled(String taskId);
  Future<void> reorderTasks(List<Task> tasks);
  Future<void> permanentlyDeleteTask(String taskId);
}
