import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_task_manager/core/constants/firestore_constants.dart';
import 'package:iot_task_manager/data/models/task_model.dart';

class TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  final String _userId;

  TaskRemoteDataSource(this._firestore, this._userId);

  CollectionReference get _tasksRef =>
      _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.tasks);

  Stream<List<TaskModel>> getTasks() {
    return _tasksRef
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<TaskModel> getTask(String taskId) async {
    final doc = await _tasksRef.doc(taskId).get();
    if (!doc.exists) throw Exception('Task not found');
    return TaskModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> createTask(TaskModel task) async {
    await _tasksRef.doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksRef.doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
