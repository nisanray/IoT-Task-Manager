import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/data/datasources/local/task_local_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/activity_log_remote_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:iot_task_manager/data/datasources/remote/task_remote_datasource.dart';
import 'package:iot_task_manager/firebase_options.dart';
import 'auth_provider.dart';

final firebaseAppProvider = FutureProvider<FirebaseApp>((ref) async {
  return Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return TaskRemoteDataSource(firestore, userId ?? 'default_user');
});

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return DashboardRemoteDataSource(firestore, userId ?? 'default_user');
});

final activityLogRemoteDataSourceProvider =
    Provider<ActivityLogRemoteDataSource>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ActivityLogRemoteDataSource(firestore, userId ?? 'default_user');
});

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSource();
});
