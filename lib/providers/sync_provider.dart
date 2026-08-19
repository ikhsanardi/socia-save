import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  factory SyncState.idle({String? message}) =>
      SyncState(status: SyncStatus.idle, message: message);
}

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;

  SyncNotifier(this.ref) : super(SyncState.idle());

  Future<void> triggerSync({bool silent = false}) async {
    final auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    // If user is guest / not signed in with Google
    if (currentUser == null || currentUser.isAnonymous) {
      if (!silent) {
        state = SyncState(
          status: SyncStatus.idle,
          message:
              'You are using a Guest account. Sign in with Google to sync bookmarks to the cloud.',
        );
      }
      return;
    }

    if (!silent) {
      state = SyncState(
        status: SyncStatus.syncing,
        message: 'Syncing with Google Cloud...',
      );
    }

    try {
      final userId = currentUser.uid;
      final isarService = ref.read(isarServiceProvider);
      final firestore = FirebaseFirestore.instance;
      final syncTimestamp = DateTime.now();

      // ========================================================
      // 1. TWO-WAY CATEGORY SYNC & CLOUD DEDUPLICATION
      // ========================================================
      final remoteCatSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      final localCategories = await isarService.getAllCategoriesForSync(userId);

      // Maps and sets for deduplication
      final Map<String, Category> canonicalByName = {};
      final Map<int, int> categoryRemap = {};
      final List<DocumentReference> duplicateRemoteDocsToDelete = [];
      final Set<int> duplicateLocalIdsToDelete = {};
      final Set<int> categoriesToPushRemote = {};
      final List<Category> localCategoriesToDeleteOnCloud = [];

      // A. Process Remote Documents from Firestore
      for (var doc in remoteCatSnap.docs) {
        final data = doc.data();
        final catId = data['id'] as int? ?? int.tryParse(doc.id) ?? 0;
        final isDeleted = data['isDeleted'] as bool? ?? false;
        final name = (data['name'] as String? ?? '').trim();
        final colorHex = data['colorHex'] as String? ?? '6366F1';
        final remoteCreatedAt =
            DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();
        final remoteUpdatedAt =
            DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now();

        if (catId <= 0 || name.isEmpty) {
          duplicateRemoteDocsToDelete.add(doc.reference);
          continue;
        }

        final normName = name.toLowerCase();

        if (isDeleted) {
          duplicateLocalIdsToDelete.add(catId);
          continue;
        }

        if (canonicalByName.containsKey(normName)) {
          // DUPLICATE IN FIRESTORE DETECTED!
          final canonicalCat = canonicalByName[normName]!;
          categoryRemap[catId] = canonicalCat.id;
          duplicateRemoteDocsToDelete.add(doc.reference);
          duplicateLocalIdsToDelete.add(catId);

          if (remoteUpdatedAt.isAfter(canonicalCat.updatedAt)) {
            canonicalCat.colorHex = colorHex;
            canonicalCat.updatedAt = remoteUpdatedAt;
            categoriesToPushRemote.add(canonicalCat.id);
          }
        } else {
          final cat = Category()
            ..id = catId
            ..userId = userId
            ..name = name
            ..colorHex = colorHex
            ..createdAt = remoteCreatedAt
            ..updatedAt = remoteUpdatedAt
            ..isDeleted = false;

          canonicalByName[normName] = cat;
        }
      }

      // B. Process Local Categories from Isar
      for (var localCat in localCategories) {
        if (localCat.isDeleted) {
          localCategoriesToDeleteOnCloud.add(localCat);
          duplicateLocalIdsToDelete.add(localCat.id);
          continue;
        }

        final normName = localCat.name.trim().toLowerCase();
        if (normName.isEmpty) {
          duplicateLocalIdsToDelete.add(localCat.id);
          continue;
        }

        if (canonicalByName.containsKey(normName)) {
          final canonicalCat = canonicalByName[normName]!;
          if (localCat.id != canonicalCat.id) {
            // Local category is a duplicate of a canonical category
            categoryRemap[localCat.id] = canonicalCat.id;
            duplicateLocalIdsToDelete.add(localCat.id);
            final dupDocRef = firestore
                .collection('users')
                .doc(userId)
                .collection('categories')
                .doc(localCat.id.toString());
            duplicateRemoteDocsToDelete.add(dupDocRef);

            if (localCat.updatedAt.isAfter(canonicalCat.updatedAt)) {
              canonicalCat.colorHex = localCat.colorHex;
              canonicalCat.updatedAt = localCat.updatedAt;
              categoriesToPushRemote.add(canonicalCat.id);
            }
          } else {
            // Same ID & same name: check which timestamp is newer
            if (localCat.updatedAt.isAfter(canonicalCat.updatedAt)) {
              canonicalCat.name = localCat.name.trim();
              canonicalCat.colorHex = localCat.colorHex;
              canonicalCat.updatedAt = localCat.updatedAt;
              categoriesToPushRemote.add(canonicalCat.id);
            }
          }
        } else {
          // Local category does not exist remotely yet
          canonicalByName[normName] = localCat;
          categoriesToPushRemote.add(localCat.id);
        }
      }

      // C. Handle possible ID collisions among different canonical categories
      final Set<int> usedIds = {};
      for (var cat in canonicalByName.values.toList()) {
        if (usedIds.contains(cat.id)) {
          final oldId = cat.id;
          final newCat = Category.create(
            userId: userId,
            name: cat.name,
            colorHex: cat.colorHex,
          );
          final newId = await isarService.addCategory(newCat);
          cat.id = newId;
          categoryRemap[oldId] = newId;
          categoriesToPushRemote.add(newId);
        }
        usedIds.add(cat.id);
      }

      // D. If user has NO categories remotely AND locally, seed defaults for this user
      if (canonicalByName.isEmpty) {
        final defaultCategories = [
          Category.create(userId: userId, name: 'General', colorHex: '6366F1'),
          Category.create(userId: userId, name: 'Recipes', colorHex: 'EF4444'),
          Category.create(userId: userId, name: 'Tech', colorHex: '3B82F6'),
          Category.create(userId: userId, name: 'Travel', colorHex: '10B981'),
          Category.create(userId: userId, name: 'Design', colorHex: '8B5CF6'),
        ];
        for (var cat in defaultCategories) {
          final id = await isarService.addCategory(cat);
          cat.id = id;
          canonicalByName[cat.name.trim().toLowerCase()] = cat;
          categoriesToPushRemote.add(cat.id);
        }
      }

      // E. Clean up local duplicate / deleted categories in Isar
      for (var dupId in duplicateLocalIdsToDelete) {
        if (!canonicalByName.values.any((c) => c.id == dupId)) {
          await isarService.hardDeleteCategory(dupId);
        }
      }

      // F. Save / Update canonical categories to local Isar with synced timestamp
      for (var canonicalCat in canonicalByName.values) {
        canonicalCat.syncedAt = syncTimestamp;
        canonicalCat.isDeleted = false;
        await isarService.saveSyncedCategory(canonicalCat);
      }

      // G. Delete remote duplicate documents from Firestore
      if (duplicateRemoteDocsToDelete.isNotEmpty) {
        final deleteBatch = firestore.batch();
        for (var docRef in duplicateRemoteDocsToDelete) {
          deleteBatch.delete(docRef);
        }
        await deleteBatch.commit();
      }

      // H. Push all canonical categories & delete removed category records in Firestore
      final catBatch = firestore.batch();
      for (var cat in canonicalByName.values) {
        final docRef = firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(cat.id.toString());

        catBatch.set(docRef, {
          'id': cat.id,
          'userId': userId,
          'name': cat.name.trim(),
          'colorHex': cat.colorHex,
          'createdAt': cat.createdAt.toIso8601String(),
          'updatedAt': cat.updatedAt.toIso8601String(),
          'isDeleted': false,
        }, SetOptions(merge: true));
      }
      for (var deletedCat in localCategoriesToDeleteOnCloud) {
        final docRef = firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(deletedCat.id.toString());

        catBatch.delete(docRef);
        await isarService.hardDeleteCategory(deletedCat.id);
      }
      await catBatch.commit();

      // ========================================================
      // 2. TWO-WAY SHARED CONTENT SYNC (WITH CATEGORY REMAPPING)
      // ========================================================
      final remoteContentSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('shared_content')
          .get();

      final localContents =
          await isarService.getAllSharedContentForSync(userId);
      final localContentMap = {for (var c in localContents) c.id: c};

      // 2.1 Remap any local items pointing to duplicate category IDs
      if (categoryRemap.isNotEmpty) {
        for (var item in localContentMap.values) {
          if (categoryRemap.containsKey(item.categoryId)) {
            item.categoryId = categoryRemap[item.categoryId]!;
            item.syncedAt = null; // Mark unsynced to push corrected categoryId
            await isarService.saveSyncedContent(item);
          }
        }
      }

      int pulledCount = 0;
      final List<DocumentReference> remoteContentToDelete = [];

      // A. Pull Remote Shared Content -> Local Isar
      for (var doc in remoteContentSnap.docs) {
        final data = doc.data();
        final contentId = data['id'] as int? ?? int.tryParse(doc.id) ?? 0;
        final isDeleted = data['isDeleted'] as bool? ?? false;
        final remoteUpdatedAt =
            DateTime.tryParse(data['updatedAt'] ?? '') ?? DateTime.now();

        if (contentId <= 0) continue;

        if (isDeleted) {
          if (localContentMap.containsKey(contentId)) {
            await isarService.hardDeleteSharedContent(contentId);
            localContentMap.remove(contentId);
          }
          remoteContentToDelete.add(doc.reference);
        } else {
          var categoryId = data['categoryId'] as int? ?? 0;
          if (categoryRemap.containsKey(categoryId)) {
            categoryId = categoryRemap[categoryId]!;
          }

          final localItem = localContentMap[contentId];
          if (localItem == null) {
            // New content downloaded from cloud (e.g. from previous phone)
            final newItem = SharedContent()
              ..id = contentId
              ..userId = userId
              ..rawUrl = data['rawUrl'] ?? ''
              ..title = data['title'] ?? ''
              ..thumbnailUrl = data['thumbnailUrl']
              ..socmedSource = data['socmedSource'] ?? 'Other'
              ..categoryId = categoryId
              ..createdAt = DateTime.tryParse(data['createdAt'] ?? '') ??
                  DateTime.now()
              ..updatedAt = remoteUpdatedAt
              ..syncedAt = syncTimestamp
              ..isDeleted = false;
            await isarService.saveSyncedContent(newItem);
            localContentMap[contentId] = newItem;
            pulledCount++;
          } else if (localItem.isDeleted) {
            if (remoteUpdatedAt.isAfter(localItem.updatedAt)) {
              // Remote update is newer than local deletion -> restore from cloud
              localItem.title = data['title'] ?? localItem.title;
              localItem.rawUrl = data['rawUrl'] ?? localItem.rawUrl;
              localItem.thumbnailUrl =
                  data['thumbnailUrl'] ?? localItem.thumbnailUrl;
              localItem.socmedSource =
                  data['socmedSource'] ?? localItem.socmedSource;
              localItem.categoryId = categoryId;
              localItem.updatedAt = remoteUpdatedAt;
              localItem.syncedAt = syncTimestamp;
              localItem.isDeleted = false;
              await isarService.saveSyncedContent(localItem);
            }
          } else if (remoteUpdatedAt.isAfter(localItem.updatedAt)) {
            // Remote update is newer
            localItem.title = data['title'] ?? localItem.title;
            localItem.rawUrl = data['rawUrl'] ?? localItem.rawUrl;
            localItem.thumbnailUrl =
                data['thumbnailUrl'] ?? localItem.thumbnailUrl;
            localItem.socmedSource =
                data['socmedSource'] ?? localItem.socmedSource;
            localItem.categoryId = categoryId;
            localItem.updatedAt = remoteUpdatedAt;
            localItem.syncedAt = syncTimestamp;
            await isarService.saveSyncedContent(localItem);
          }
        }
      }

      // Delete remote content documents marked isDeleted from Firestore
      if (remoteContentToDelete.isNotEmpty) {
        final deleteContentBatch = firestore.batch();
        for (var docRef in remoteContentToDelete) {
          deleteContentBatch.delete(docRef);
        }
        await deleteContentBatch.commit();
      }

      // B. Push Local Content -> Remote Firestore (delete removed, push active)
      final contentBatch = firestore.batch();
      bool hasPushes = false;
      for (var item in localContentMap.values) {
        final docRef = firestore
            .collection('users')
            .doc(userId)
            .collection('shared_content')
            .doc(item.id.toString());

        if (item.isDeleted) {
          contentBatch.delete(docRef);
          await isarService.hardDeleteSharedContent(item.id);
          hasPushes = true;
        } else if (item.syncedAt == null ||
            item.updatedAt.isAfter(item.syncedAt!)) {
          var categoryId = item.categoryId;
          if (categoryRemap.containsKey(categoryId)) {
            categoryId = categoryRemap[categoryId]!;
            item.categoryId = categoryId;
          }

          contentBatch.set(docRef, {
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

          await isarService.markContentSynced(item.id, syncTimestamp);
          hasPushes = true;
        }
      }
      if (hasPushes) {
        await contentBatch.commit();
      }

      // ========================================================
      // 3. REFRESH LOCAL NOTIFIERS
      // ========================================================
      ref.invalidate(categoryNotifierProvider);
      ref.invalidate(sharedContentNotifierProvider);
      ref.invalidate(unsyncedCountProvider);

      state = SyncState(
        status: SyncStatus.success,
        message: pulledCount > 0
            ? 'Synced! Restored $pulledCount items from cloud.'
            : 'Cloud sync complete! Everything is up to date.',
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
