import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/domain/entities/task.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String scheduledDate;
  final Map<String, dynamic>? repeatRule;
  final String priority;
  final String category;
  final bool completed;
  final bool enabled;
  final bool archived;
  final bool deleted;
  final bool showOnEsp32;
  final int order;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? completedAt;
  final Timestamp? deletedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.type = 'today',
    required this.scheduledDate,
    this.repeatRule,
    this.priority = 'medium',
    this.category = 'General',
    this.completed = false,
    this.enabled = true,
    this.archived = false,
    this.deleted = false,
    this.showOnEsp32 = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, String id) {
    return TaskModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'today',
      scheduledDate: json['scheduledDate'] as String? ?? '',
      repeatRule: json['repeatRule'] as Map<String, dynamic>?,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'General',
      completed: json['completed'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      archived: json['archived'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      showOnEsp32: json['showOnEsp32'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: (json['updatedAt'] as Timestamp?) ?? Timestamp.now(),
      completedAt: json['completedAt'] as Timestamp?,
      deletedAt: json['deletedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'scheduledDate': scheduledDate,
      'repeatRule': repeatRule,
      'priority': priority,
      'category': category,
      'completed': completed,
      'enabled': enabled,
      'archived': archived,
      'deleted': deleted,
      'showOnEsp32': showOnEsp32,
      'order': order,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'deletedAt': deletedAt,
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      type: _parseTaskType(type),
      scheduledDate: DateTime.parse(scheduledDate),
      repeatRule: repeatRule != null ? _parseRepeatRule(repeatRule!) : null,
      priority: _parsePriority(priority),
      category: category,
      completed: completed,
      enabled: enabled,
      archived: archived,
      deleted: deleted,
      showOnEsp32: showOnEsp32,
      order: order,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      completedAt: completedAt?.toDate(),
      deletedAt: deletedAt?.toDate(),
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      type: _taskTypeToString(task.type),
      scheduledDate:
          '${task.scheduledDate.year.toString().padLeft(4, '0')}-${task.scheduledDate.month.toString().padLeft(2, '0')}-${task.scheduledDate.day.toString().padLeft(2, '0')}',
      repeatRule: task.repeatRule != null
          ? {
              'weekdays': task.repeatRule!.weekdays,
              if (task.repeatRule!.frequency != null)
                'frequency': task.repeatRule!.frequency,
              if (task.repeatRule!.interval != null)
                'interval': task.repeatRule!.interval,
              if (task.repeatRule!.endDate != null)
                'endDate':
                    '${task.repeatRule!.endDate!.year.toString().padLeft(4, '0')}-${task.repeatRule!.endDate!.month.toString().padLeft(2, '0')}-${task.repeatRule!.endDate!.day.toString().padLeft(2, '0')}',
            }
          : null,
      priority: _priorityToString(task.priority),
      category: task.category,
      completed: task.completed,
      enabled: task.enabled,
      archived: task.archived,
      deleted: task.deleted,
      showOnEsp32: task.showOnEsp32,
      order: task.order,
      createdAt: Timestamp.fromDate(task.createdAt),
      updatedAt: Timestamp.fromDate(task.updatedAt),
      completedAt:
          task.completedAt != null ? Timestamp.fromDate(task.completedAt!) : null,
      deletedAt:
          task.deletedAt != null ? Timestamp.fromDate(task.deletedAt!) : null,
    );
  }

  static TaskType _parseTaskType(String type) {
    switch (type) {
      case 'today':
        return TaskType.today;
      case 'daily':
        return TaskType.daily;
      case 'constant':
        return TaskType.constant;
      case 'weekly':
        return TaskType.weekly;
      case 'monthly':
        return TaskType.monthly;
      case 'custom_date':
        return TaskType.customDate;
      default:
        return TaskType.today;
    }
  }

  static String _taskTypeToString(TaskType type) {
    switch (type) {
      case TaskType.today:
        return 'today';
      case TaskType.daily:
        return 'daily';
      case TaskType.constant:
        return 'constant';
      case TaskType.weekly:
        return 'weekly';
      case TaskType.monthly:
        return 'monthly';
      case TaskType.customDate:
        return 'custom_date';
    }
  }

  static TaskPriority _parsePriority(String priority) {
    switch (priority) {
      case 'critical':
        return TaskPriority.critical;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return 'critical';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.low:
        return 'low';
    }
  }

  static RepeatRule _parseRepeatRule(Map<String, dynamic> rule) {
    return RepeatRule(
      weekdays: List<String>.from(rule['weekdays'] ?? []),
      frequency: rule['frequency'] as String?,
      interval: rule['interval'] as int?,
      endDate: rule['endDate'] != null
          ? DateTime.parse(rule['endDate'] as String)
          : null,
    );
  }
}
