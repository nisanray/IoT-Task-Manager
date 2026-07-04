import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/data/repositories/dashboard_repository_impl.dart';
import 'package:iot_task_manager/domain/entities/dashboard.dart';
import 'package:iot_task_manager/domain/entities/dashboard_settings.dart';
import 'package:iot_task_manager/domain/repositories/dashboard_repository.dart';
import 'package:iot_task_manager/presentation/providers/firebase_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = ref.read(dashboardRemoteDataSourceProvider);
  return DashboardRepositoryImpl(remote);
});

final dashboardProvider = StreamProvider<Dashboard?>((ref) {
  return ref.read(dashboardRepositoryProvider).getDashboard();
});

final dashboardSettingsProvider = FutureProvider<DashboardSettings>(
  (ref) async {
    return ref.read(dashboardRepositoryProvider).getDashboardSettings();
  },
);

class DashboardSettingsNotifier extends StateNotifier<AsyncValue<void>> {
  final DashboardRepository _repository;

  DashboardSettingsNotifier(this._repository) : super(const AsyncData(null));

  Future<void> updateSettings(DashboardSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.updateDashboardSettings(settings);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final dashboardSettingsActionsProvider =
    StateNotifierProvider<DashboardSettingsNotifier, AsyncValue<void>>(
  (ref) {
    return DashboardSettingsNotifier(ref.read(dashboardRepositoryProvider));
  },
);
