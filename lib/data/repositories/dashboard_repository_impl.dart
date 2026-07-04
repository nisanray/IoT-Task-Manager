import 'package:iot_task_manager/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:iot_task_manager/data/models/dashboard_settings_model.dart';
import 'package:iot_task_manager/domain/entities/dashboard.dart';
import 'package:iot_task_manager/domain/entities/dashboard_settings.dart';
import 'package:iot_task_manager/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Stream<Dashboard?> getDashboard() {
    return _remoteDataSource.getDashboard().map((model) {
      return model?.toEntity();
    });
  }

  @override
  Future<void> generateDashboard(
      List<dynamic> tasks, DashboardSettings settings) async {
  }

  @override
  Future<DashboardSettings> getDashboardSettings() async {
    final model = await _remoteDataSource.getDashboardSettings();
    return model.toEntity();
  }

  @override
  Future<void> updateDashboardSettings(DashboardSettings settings) async {
    final model = DashboardSettingsModel.fromEntity(settings);
    await _remoteDataSource.updateDashboardSettings(model);
  }
}
