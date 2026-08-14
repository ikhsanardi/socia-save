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

      // 1. Sign in anonymously if not already authenticated
      if (currentUser == null) {
        try {
          final userCredential = await auth.signInAnonymously();
          currentUser = userCredential.user;
        } on FirebaseAuthException catch (authError) {
          if (authError.code == 'admin-restricted-operation' ||
              authError.code == 'operation-not-allowed') {
            state = SyncState(
              status: SyncStatus.error,
              message:
                  'Please enable Anonymous Sign-in in Firebase Console > Authentication > Sign-in method.',
            );
            return;
          }
          rethrow;
        }
      }

      if (currentUser == null) {
        state = SyncState(
          status: SyncStatus.error,
          message: 'Failed to authenticate user.',
        );
        return;
      }

      final userId = currentUser.uid;
      final isarService = ref.read(isarServiceProvider);

      // 2. Migrate legacy 'local_user' data to the authenticated Firebase UID
      await isarService.migrateUserRecords(
        fromUserId: 'local_user',
        toUserId: userId,
      );

      // Update the active userIdProvider state
      ref.read(userIdProvider.notifier).state = userId;

      final firestore = FirebaseFirestore.instance;
      final syncTimestamp = DateTime.now();

      // 3. Fetch active local categories and content items
      final localCategories = await isarService.getAllCategories(userId);
      final localContents = await isarService.getSharedContent(userId: userId);
      final activeCategoryIds = localCategories.map((c) => c.id).toSet();
      final activeContentIds = localContents.map((c) => c.id).toSet();

      // 4. Push all active local categories to Firestore
      final batch = firestore.batch();
      for (var cat in localCategories) {
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
          'isDeleted': false,
        }, SetOptions(merge: true));
      }

      // 5. Push all active local content items to Firestore
      for (var item in localContents) {
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
          'isDeleted': false,
        }, SetOptions(merge: true));
      }

      await batch.commit();

      // 6. Prune deleted items from Firestore: delete remote documents not in active local items
      final remoteContentSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('shared_content')
          .get();

      for (var doc in remoteContentSnap.docs) {
        final docId = int.tryParse(doc.id) ?? (doc.data()['id'] as int? ?? 0);
        if (docId > 0 && !activeContentIds.contains(docId)) {
          // Document was deleted locally -> delete it from Firestore!
          await doc.reference.delete();
        }
      }

      // Prune deleted categories from Firestore
      final remoteCatSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      for (var doc in remoteCatSnap.docs) {
        final docId = int.tryParse(doc.id) ?? (doc.data()['id'] as int? ?? 0);
        if (docId > 0 && !activeCategoryIds.contains(docId)) {
          await doc.reference.delete();
        }
      }

      // 7. Mark pushed items as successfully synced in local Isar DB
      for (var item in localContents) {
        await isarService.markContentSynced(item.id, syncTimestamp);
      }

      // 8. Refresh local UI states and counter
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(sharedContentNotifierProvider);
      ref.invalidate(unsyncedCountProvider);

      state = SyncState(
        status: SyncStatus.success,
        message: 'Cloud sync complete! Data backed up to Firestore.',
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
