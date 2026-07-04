import 'package:equatable/equatable.dart';

class DashboardSettings extends Equatable {
  final bool showTodayTasks;
  final bool showDailyTasks;
  final bool showConstantTasks;
  final bool showWeeklyTasks;
  final bool showMonthlyTasks;
  final String displayMode; // 'today', 'daily', 'constant', 'rotate'
  final int rotationInterval;
  final int maxTasksPerSection;
  final String sortOrder; // 'priority', 'date', 'order', 'title'
  final bool compactMode;
  final bool largeTextMode;

  const DashboardSettings({
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

  DashboardSettings copyWith({
    bool? showTodayTasks,
    bool? showDailyTasks,
    bool? showConstantTasks,
    bool? showWeeklyTasks,
    bool? showMonthlyTasks,
    String? displayMode,
    int? rotationInterval,
    int? maxTasksPerSection,
    String? sortOrder,
    bool? compactMode,
    bool? largeTextMode,
  }) {
    return DashboardSettings(
      showTodayTasks: showTodayTasks ?? this.showTodayTasks,
      showDailyTasks: showDailyTasks ?? this.showDailyTasks,
      showConstantTasks: showConstantTasks ?? this.showConstantTasks,
      showWeeklyTasks: showWeeklyTasks ?? this.showWeeklyTasks,
      showMonthlyTasks: showMonthlyTasks ?? this.showMonthlyTasks,
      displayMode: displayMode ?? this.displayMode,
      rotationInterval: rotationInterval ?? this.rotationInterval,
      maxTasksPerSection: maxTasksPerSection ?? this.maxTasksPerSection,
      sortOrder: sortOrder ?? this.sortOrder,
      compactMode: compactMode ?? this.compactMode,
      largeTextMode: largeTextMode ?? this.largeTextMode,
    );
  }

  @override
  List<Object?> get props => [
        showTodayTasks,
        showDailyTasks,
        showConstantTasks,
        showWeeklyTasks,
        showMonthlyTasks,
        displayMode,
        rotationInterval,
        maxTasksPerSection,
        sortOrder,
        compactMode,
        largeTextMode,
      ];
}
