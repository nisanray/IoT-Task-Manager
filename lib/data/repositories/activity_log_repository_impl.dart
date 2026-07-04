import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/data/datasources/remote/activity_log_remote_datasource.dart';
import 'package:iot_task_manager/data/models/activity_log_model.dart';
import 'package:iot_task_manager/domain/entities/activity_log.dart';
import 'package:iot_task_manager/domain/repositories/activity_log_repository.dart';
import 'package:uuid/uuid.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final ActivityLogRemoteDataSource _remoteDataSource;

  ActivityLogRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<ActivityLog>> getActivityLogs() {
    return _remoteDataSource.getActivityLogs().map((models) {
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<void> logActivity(String action, String description,
      {String? taskId, String? taskTitle}) async {
    final log = ActivityLogModel(
      id: const Uuid().v4(),
      action: action,
      description: description,
      taskId: taskId,
      taskTitle: taskTitle,
      createdAt: Timestamp.now(),
    );
    await _remoteDataSource.logActivity(log);
  }
}
