import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/core/constants/firestore_constants.dart';
import 'package:iot_task_manager/data/models/dashboard_model.dart';
import 'package:iot_task_manager/data/models/dashboard_settings_model.dart';

class DashboardRemoteDataSource {
  final FirebaseFirestore _firestore;
  final String _userId;

  DashboardRemoteDataSource(this._firestore, this._userId);

  DocumentReference get _dashboardRef =>
      _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.dashboard)
          .doc(FirestoreConstants.current);

  DocumentReference get _dashboardSettingsRef =>
      _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.settings)
          .doc('dashboard');

  Stream<DashboardModel?> getDashboard() {
    return _dashboardRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return DashboardModel.fromJson(snapshot.data() as Map<String, dynamic>);
    });
  }

  Future<void> generateDashboard(DashboardModel dashboard) async {
    await _dashboardRef.set(dashboard.toJson());
  }

  Future<DashboardSettingsModel> getDashboardSettings() async {
    final doc = await _dashboardSettingsRef.get();
    if (!doc.exists) return const DashboardSettingsModel();
    return DashboardSettingsModel.fromJson(
        doc.data() as Map<String, dynamic>);
  }

  Future<void> updateDashboardSettings(DashboardSettingsModel settings) async {
    await _dashboardSettingsRef.set(settings.toJson());
  }
}
