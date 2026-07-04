import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/core/constants/firestore_constants.dart';
import 'package:iot_task_manager/data/models/activity_log_model.dart';

class ActivityLogRemoteDataSource {
  final FirebaseFirestore _firestore;
  final String _userId;

  ActivityLogRemoteDataSource(this._firestore, this._userId);

  CollectionReference get _logsRef =>
      _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.activityLogs);

  Stream<List<ActivityLogModel>> getActivityLogs() {
    return _logsRef
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ActivityLogModel.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> logActivity(ActivityLogModel log) async {
    await _logsRef.doc(log.id).set(log.toJson());
  }
}
