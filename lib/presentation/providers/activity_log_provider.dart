import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/data/repositories/activity_log_repository_impl.dart';
import 'package:iot_task_manager/domain/entities/activity_log.dart';
import 'package:iot_task_manager/presentation/providers/firebase_providers.dart';

final activityLogRepositoryProvider =
    Provider<ActivityLogRepositoryImpl>((ref) {
  final remote = ref.read(activityLogRemoteDataSourceProvider);
  return ActivityLogRepositoryImpl(remote);
});

final activityLogsProvider = StreamProvider<List<ActivityLog>>((ref) {
  return ref.read(activityLogRepositoryProvider).getActivityLogs();
});
