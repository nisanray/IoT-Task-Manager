import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot_task_manager/data/models/task_model.dart';

class TaskLocalDataSource {
  static const String _tasksKey = 'cached_tasks';
  static const String _pendingOpsKey = 'pending_operations';

  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_tasksKey, jsonList);
  }

  Future<List<TaskModel>> getCachedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_tasksKey);
    if (jsonList == null) return [];
    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return TaskModel.fromJson(map, map['id'] as String);
    }).toList();
  }

  Future<void> addPendingOperation(Map<String, dynamic> operation) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = prefs.getStringList(_pendingOpsKey) ?? [];
    ops.add(jsonEncode(operation));
    await prefs.setStringList(_pendingOpsKey, ops);
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final ops = prefs.getStringList(_pendingOpsKey);
    if (ops == null) return [];
    return ops.map((o) => jsonDecode(o) as Map<String, dynamic>).toList();
  }

  Future<void> clearPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOpsKey);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_pendingOpsKey);
  }
}
