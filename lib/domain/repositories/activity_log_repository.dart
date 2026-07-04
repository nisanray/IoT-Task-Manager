import 'package:iot_task_manager/domain/entities/activity_log.dart';

abstract class ActivityLogRepository {
  Stream<List<ActivityLog>> getActivityLogs();
  Future<void> logActivity(String action, String description,
      {String? taskId, String? taskTitle});
}
