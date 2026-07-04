import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/core/constants/firestore_constants.dart';
import 'package:iot_task_manager/domain/entities/category.dart';
import 'package:iot_task_manager/presentation/providers/auth_provider.dart';
import 'package:iot_task_manager/presentation/providers/firebase_providers.dart';
import 'package:uuid/uuid.dart';

final categoriesProvider = StreamProvider<List<TaskCategory>>((ref) async* {
  final firestore = ref.read(firebaseFirestoreProvider);
  final userId = ref.watch(currentUserIdProvider) ?? 'default_user';
  await for (final snapshot in firestore
      .collection(FirestoreConstants.users)
      .doc(userId)
      .collection(FirestoreConstants.categories)
      .orderBy('order')
      .snapshots()) {
    yield snapshot.docs.map((doc) {
      final data = doc.data();
      return TaskCategory(
        id: doc.id,
        name: data['name'] as String? ?? '',
        color: data['color'] as int? ?? 0xFF4F46E5,
        order: data['order'] as int? ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      );
    }).toList();
  }
});

class CategoryActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _userId;

  CategoryActionsNotifier(this._firestore, this._userId)
      : super(const AsyncData(null));

  Future<void> createCategory(String name, int color) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      await _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.categories)
          .doc(id)
          .set({
        'name': name,
        'color': color,
        'order': FieldValue.increment(1),
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    state = const AsyncLoading();
    try {
      await _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.categories)
          .doc(categoryId)
          .delete();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateCategory(
      String categoryId, String name, int color) async {
    state = const AsyncLoading();
    try {
      await _firestore
          .collection(FirestoreConstants.users)
          .doc(_userId)
          .collection(FirestoreConstants.categories)
          .doc(categoryId)
          .update({'name': name, 'color': color});
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final categoryActionsProvider =
    StateNotifierProvider<CategoryActionsNotifier, AsyncValue<void>>(
  (ref) {
    final firestore = ref.read(firebaseFirestoreProvider);
    final userId = ref.watch(currentUserIdProvider) ?? 'default_user';
    return CategoryActionsNotifier(firestore, userId);
  },
);
