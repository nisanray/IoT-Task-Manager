import 'package:equatable/equatable.dart';

enum TaskType { today, daily, constant, weekly, monthly, customDate }

enum TaskPriority { critical, high, medium, low }

enum TaskStatus { active, completed, archived, deleted }

class RepeatRule extends Equatable {
  final List<String> weekdays;
  final String? frequency; // 'monthly', 'yearly', 'custom'
  final int? interval;
  final DateTime? endDate;

  const RepeatRule({
    this.weekdays = const [],
    this.frequency,
    this.interval,
    this.endDate,
  });

  @override
  List<Object?> get props => [weekdays, frequency, interval, endDate];
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final DateTime scheduledDate;
  final RepeatRule? repeatRule;
  final TaskPriority priority;
  final String category;
  final bool completed;
  final bool enabled;
  final bool archived;
  final bool deleted;
  final bool showOnEsp32;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.type = TaskType.today,
    required this.scheduledDate,
    this.repeatRule,
    this.priority = TaskPriority.medium,
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

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    DateTime? scheduledDate,
    RepeatRule? repeatRule,
    bool clearRepeatRule = false,
    TaskPriority? priority,
    String? category,
    bool? completed,
    bool? enabled,
    bool? archived,
    bool? deleted,
    bool? showOnEsp32,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      repeatRule:
          clearRepeatRule ? null : repeatRule ?? this.repeatRule,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      enabled: enabled ?? this.enabled,
      archived: archived ?? this.archived,
      deleted: deleted ?? this.deleted,
      showOnEsp32: showOnEsp32 ?? this.showOnEsp32,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt:
          clearCompletedAt ? null : completedAt ?? this.completedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  bool get isActive => !completed && !archived && !deleted && enabled;

  bool get shouldShowToday {
    if (!isActive) return false;
    if (type == TaskType.today || type == TaskType.customDate) {
      final now = DateTime.now();
      return scheduledDate.year == now.year &&
          scheduledDate.month == now.month &&
          scheduledDate.day == now.day;
    }
    if (type == TaskType.daily || type == TaskType.constant) return true;
    if (type == TaskType.weekly && repeatRule != null) {
      final dayNames = [
        'monday', 'tuesday', 'wednesday', 'thursday',
        'friday', 'saturday', 'sunday',
      ];
      final todayName = dayNames[DateTime.now().weekday - 1];
      return repeatRule!.weekdays.contains(todayName);
    }
    if (type == TaskType.monthly) {
      return scheduledDate.day == DateTime.now().day;
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        scheduledDate,
        repeatRule,
        priority,
        category,
        completed,
        enabled,
        archived,
        deleted,
        showOnEsp32,
        order,
        createdAt,
        updatedAt,
        completedAt,
        deletedAt,
      ];
}
