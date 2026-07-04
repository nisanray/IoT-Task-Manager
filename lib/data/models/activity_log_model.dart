import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/domain/entities/activity_log.dart';

class ActivityLogModel {
  final String id;
  final String action;
  final String description;
  final String? taskId;
  final String? taskTitle;
  final Timestamp createdAt;

  const ActivityLogModel({
    required this.id,
    required this.action,
    required this.description,
    this.taskId,
    this.taskTitle,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json, String id) {
    return ActivityLogModel(
      id: id,
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
      createdAt: (json['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'description': description,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'createdAt': createdAt,
    };
  }

  ActivityLog toEntity() {
    return ActivityLog(
      id: id,
      action: action,
      description: description,
      taskId: taskId,
      taskTitle: taskTitle,
      createdAt: createdAt.toDate(),
    );
  }

  factory ActivityLogModel.fromEntity(ActivityLog log) {
    return ActivityLogModel(
      id: log.id,
      action: log.action,
      description: log.description,
      taskId: log.taskId,
      taskTitle: log.taskTitle,
      createdAt: Timestamp.fromDate(log.createdAt),
    );
  }
}
