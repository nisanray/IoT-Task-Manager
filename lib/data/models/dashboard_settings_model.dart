import 'package:iot_task_manager/domain/entities/dashboard_settings.dart';

class DashboardSettingsModel {
  final bool showTodayTasks;
  final bool showDailyTasks;
  final bool showConstantTasks;
  final bool showWeeklyTasks;
  final bool showMonthlyTasks;
  final String displayMode;
  final int rotationInterval;
  final int maxTasksPerSection;
  final String sortOrder;
  final bool compactMode;
  final bool largeTextMode;

  const DashboardSettingsModel({
    this.showTodayTasks = true,
    this.showDailyTasks = true,
    this.showConstantTasks = true,
    this.showWeeklyTasks = false,
    this.showMonthlyTasks = false,
    this.displayMode = 'rotate',
    this.rotationInterval = 15,
    this.maxTasksPerSection = 20,
    this.sortOrder = 'priority',
    this.compactMode = false,
    this.largeTextMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'showTodayTasks': showTodayTasks,
      'showDailyTasks': showDailyTasks,
      'showConstantTasks': showConstantTasks,
      'showWeeklyTasks': showWeeklyTasks,
      'showMonthlyTasks': showMonthlyTasks,
      'displayMode': displayMode,
      'rotationInterval': rotationInterval,
      'maxTasksPerSection': maxTasksPerSection,
      'sortOrder': sortOrder,
      'compactMode': compactMode,
      'largeTextMode': largeTextMode,
    };
  }

  factory DashboardSettingsModel.fromJson(Map<String, dynamic> json) {
    return DashboardSettingsModel(
      showTodayTasks: json['showTodayTasks'] as bool? ?? true,
      showDailyTasks: json['showDailyTasks'] as bool? ?? true,
      showConstantTasks: json['showConstantTasks'] as bool? ?? true,
      showWeeklyTasks: json['showWeeklyTasks'] as bool? ?? false,
      showMonthlyTasks: json['showMonthlyTasks'] as bool? ?? false,
      displayMode: json['displayMode'] as String? ?? 'rotate',
      rotationInterval: json['rotationInterval'] as int? ?? 15,
      maxTasksPerSection: json['maxTasksPerSection'] as int? ?? 20,
      sortOrder: json['sortOrder'] as String? ?? 'priority',
      compactMode: json['compactMode'] as bool? ?? false,
      largeTextMode: json['largeTextMode'] as bool? ?? false,
    );
  }

  DashboardSettings toEntity() {
    return DashboardSettings(
      showTodayTasks: showTodayTasks,
      showDailyTasks: showDailyTasks,
      showConstantTasks: showConstantTasks,
      showWeeklyTasks: showWeeklyTasks,
      showMonthlyTasks: showMonthlyTasks,
      displayMode: displayMode,
      rotationInterval: rotationInterval,
      maxTasksPerSection: maxTasksPerSection,
      sortOrder: sortOrder,
      compactMode: compactMode,
      largeTextMode: largeTextMode,
    );
  }

  factory DashboardSettingsModel.fromEntity(DashboardSettings settings) {
    return DashboardSettingsModel(
      showTodayTasks: settings.showTodayTasks,
      showDailyTasks: settings.showDailyTasks,
      showConstantTasks: settings.showConstantTasks,
      showWeeklyTasks: settings.showWeeklyTasks,
      showMonthlyTasks: settings.showMonthlyTasks,
      displayMode: settings.displayMode,
      rotationInterval: settings.rotationInterval,
      maxTasksPerSection: settings.maxTasksPerSection,
      sortOrder: settings.sortOrder,
      compactMode: settings.compactMode,
      largeTextMode: settings.largeTextMode,
    );
  }
}
