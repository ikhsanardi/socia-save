import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'shared_content_provider.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? message;

  SyncState({required this.status, this.message});

  factory SyncState.idle() => SyncState(status: SyncStatus.idle);
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;

  SyncNotifier(this.ref) : super(SyncState.idle());

  Future<void> triggerSync() async {
    state = SyncState(status: SyncStatus.syncing, message: 'Syncing with cloud...');
    try {
      final auth = FirebaseAuth.instance;
      User? currentUser = auth.currentUser;

      // Anonymous sign in fallback if not logged in
      if (currentUser == null) {
        final userCredential = await auth.signInAnonymously();
        currentUser = userCredential.user;
      }

      if (currentUser == null) {
        state = SyncState(
          status: SyncStatus.error,
          message: 'Failed to authenticate user.',
        );
        return;
      }

      final userId = currentUser.uid;
      ref.read(userIdProvider.notifier).state = userId;

      final isarService = ref.read(isarServiceProvider);
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch local unsynced categories
      final categories = await isarService.getAllCategories(userId);
      final batch = firestore.batch();

      for (var cat in categories) {
        final docRef = firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(cat.id.toString());

        batch.set(docRef, {
          'id': cat.id,
          'userId': userId,
          'name': cat.name,
          'colorHex': cat.colorHex,
          'createdAt': cat.createdAt.toIso8601String(),
          'updatedAt': cat.updatedAt.toIso8601String(),
          'isDeleted': cat.isDeleted,
        }, SetOptions(merge: true));
      }

      // 2. Fetch local unsynced content items
      final unsyncedItems = await isarService.getSharedContent(userId: userId);
      for (var item in unsyncedItems) {
        if (item.syncedAt == null || item.updatedAt.isAfter(item.syncedAt!)) {
          final docRef = firestore
              .collection('users')
              .doc(userId)
              .collection('shared_content')
              .doc(item.id.toString());

          batch.set(docRef, {
            'id': item.id,
            'userId': userId,
            'rawUrl': item.rawUrl,
            'title': item.title,
            'thumbnailUrl': item.thumbnailUrl,
            'socmedSource': item.socmedSource,
            'categoryId': item.categoryId,
            'createdAt': item.createdAt.toIso8601String(),
            'updatedAt': item.updatedAt.toIso8601String(),
            'isDeleted': item.isDeleted,
          }, SetOptions(merge: true));

          item.syncedAt = DateTime.now();
          await isarService.updateSharedContent(item);
        }
      }

      await batch.commit();

      // Refresh local UI states
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(sharedContentNotifierProvider);

      state = SyncState(
        status: SyncStatus.success,
        message: 'Cloud sync complete!',
      );
    } catch (e) {
      state = SyncState(
        status: SyncStatus.error,
        message: 'Sync error: $e',
      );
    }
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
