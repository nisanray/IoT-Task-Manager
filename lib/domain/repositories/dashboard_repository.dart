import 'package:iot_task_manager/domain/entities/dashboard.dart';
import 'package:iot_task_manager/domain/entities/dashboard_settings.dart';

abstract class DashboardRepository {
  Stream<Dashboard?> getDashboard();
  Future<void> generateDashboard(
      List<dynamic> tasks, DashboardSettings settings);
  Future<DashboardSettings> getDashboardSettings();
  Future<void> updateDashboardSettings(DashboardSettings settings);
}
