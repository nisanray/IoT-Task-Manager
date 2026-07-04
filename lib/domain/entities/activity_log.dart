import 'package:equatable/equatable.dart';

class ActivityLog extends Equatable {
  final String id;
  final String action;
  final String description;
  final String? taskId;
  final String? taskTitle;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.action,
    required this.description,
    this.taskId,
    this.taskTitle,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, action, description, taskId, taskTitle, createdAt];
}
