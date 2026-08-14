import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/category.dart';
import '../models/shared_content.dart';
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

      // 3. Push local categories to Firestore
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

      // 4. Push local shared content items to Firestore
      final allLocalItems = await isarService.getSharedContent(userId: userId);
      final syncTimestamp = DateTime.now();

      for (var item in allLocalItems) {
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
      }

      // Propagate any deletions to Firestore and remove locally
      final deletedSyncedItems = await isarService.db.sharedContents
          .filter()
          .userIdEqualTo(userId)
          .isDeletedEqualTo(true)
          .findAll();

      for (var delItem in deletedSyncedItems) {
        final docRef = firestore
            .collection('users')
            .doc(userId)
            .collection('shared_content')
            .doc(delItem.id.toString());
        batch.delete(docRef);
        await isarService.db.writeTxn(
          () => isarService.db.sharedContents.delete(delItem.id),
        );
      }

      await batch.commit();

      // Mark pushed items as successfully synced in local Isar DB
      for (var item in allLocalItems) {
        await isarService.markContentSynced(item.id, syncTimestamp);
      }

      // 5. Pull remote categories from Firestore (for restore / multi-device)
      final remoteCatSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      for (var doc in remoteCatSnap.docs) {
        final data = doc.data();
        final catId = data['id'] as int? ?? int.tryParse(doc.id) ?? 0;
        if (catId > 0) {
          final existing = await isarService.db.categorys.get(catId);
          if (existing == null) {
            final cat = Category()
              ..id = catId
              ..userId = userId
              ..name = data['name'] ?? ''
              ..colorHex = data['colorHex'] ?? '6366F1'
              ..createdAt = DateTime.tryParse(data['createdAt'] ?? '') ??
                  DateTime.now()
              ..updatedAt = DateTime.tryParse(data['updatedAt'] ?? '') ??
                  DateTime.now()
              ..isDeleted = data['isDeleted'] ?? false;
            await isarService.saveSyncedCategory(cat);
          }
        }
      }

      // 6. Pull remote content items from Firestore (for restore / multi-device)
      final remoteContentSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('shared_content')
          .get();

      for (var doc in remoteContentSnap.docs) {
        final data = doc.data();
        final contentId = data['id'] as int? ?? int.tryParse(doc.id) ?? 0;
        if (contentId > 0) {
          final existing = await isarService.db.sharedContents.get(contentId);
          if (existing == null) {
            final item = SharedContent()
              ..id = contentId
              ..userId = userId
              ..rawUrl = data['rawUrl'] ?? ''
              ..title = data['title'] ?? ''
              ..thumbnailUrl = data['thumbnailUrl']
              ..socmedSource = data['socmedSource'] ?? 'Other'
              ..categoryId = data['categoryId'] ?? 0
              ..createdAt = DateTime.tryParse(data['createdAt'] ?? '') ??
                  DateTime.now()
              ..updatedAt = DateTime.tryParse(data['updatedAt'] ?? '') ??
                  DateTime.now()
              ..syncedAt = DateTime.now()
              ..isDeleted = data['isDeleted'] ?? false;
            await isarService.saveSyncedContent(item);
          }
        }
      }

      // 7. Refresh local UI states and counter
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
