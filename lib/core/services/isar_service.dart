import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/category.dart';
import '../../models/shared_content.dart';

class IsarService {
  late Isar _isar;

  Isar get db => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [CategorySchema, SharedContentSchema],
      directory: dir.path,
      name: 'socmed_share_saver_db',
    );

    // Seed default categories if database is empty
    await seedDefaultCategoriesIfNeeded('local_user');
  }

  Future<void> seedDefaultCategoriesIfNeeded(String userId) async {
    final count = await _isar.categorys.count();
    if (count == 0) {
      final defaultCategories = [
        Category.create(userId: userId, name: 'General', colorHex: '6366F1'),
        Category.create(userId: userId, name: 'Recipes', colorHex: 'EF4444'),
        Category.create(userId: userId, name: 'Tech', colorHex: '3B82F6'),
        Category.create(userId: userId, name: 'Travel', colorHex: '10B981'),
        Category.create(userId: userId, name: 'Design', colorHex: '8B5CF6'),
      ];

      await _isar.writeTxn(() async {
        await _isar.categorys.putAll(defaultCategories);
      });
    }
  }

  // --- Category Operations ---
  Future<List<Category>> getAllCategories(String userId) async {
    return await _isar.categorys
        .filter()
        .userIdEqualTo(userId)
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  Future<int> addCategory(Category category) async {
    return await _isar.writeTxn(() async {
      return await _isar.categorys.put(category);
    });
  }

  Future<void> updateCategory(Category category) async {
    category.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    await _isar.writeTxn(() async {
      final category = await _isar.categorys.get(categoryId);
      if (category != null) {
        category.isDeleted = true;
        category.updatedAt = DateTime.now();
        await _isar.categorys.put(category);
      }
    });
  }

  // --- SharedContent Operations ---
  Future<List<SharedContent>> getSharedContent({
    required String userId,
    int? categoryId,
    String? searchQuery,
  }) async {
    var query = _isar.sharedContents
        .filter()
        .userIdEqualTo(userId)
        .isDeletedEqualTo(false);

    if (categoryId != null && categoryId > 0) {
      query = query.categoryIdEqualTo(categoryId);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.trim().toLowerCase();
      query = query.and().titleContains(term, caseSensitive: false);
    }

    return await query.sortByCreatedAtDesc().findAll();
  }

  Future<int> addSharedContent(SharedContent content) async {
    return await _isar.writeTxn(() async {
      return await _isar.sharedContents.put(content);
    });
  }

  Future<void> updateSharedContent(
    SharedContent content, {
    bool resetSynced = true,
  }) async {
    content.updatedAt = DateTime.now();
    if (resetSynced) {
      content.syncedAt = null;
    }
    await _isar.writeTxn(() async {
      await _isar.sharedContents.put(content);
    });
  }

  Future<void> markContentSynced(int contentId, DateTime syncedAt) async {
    await _isar.writeTxn(() async {
      final item = await _isar.sharedContents.get(contentId);
      if (item != null) {
        item.syncedAt = syncedAt;
        await _isar.sharedContents.put(item);
      }
    });
  }

  Future<void> deleteSharedContent(int contentId) async {
    await _isar.writeTxn(() async {
      final item = await _isar.sharedContents.get(contentId);
      if (item != null) {
        if (item.syncedAt == null) {
          // Never uploaded to cloud: completely delete from local DB
          await _isar.sharedContents.delete(contentId);
        } else {
          // Was uploaded to cloud: mark as deleted with reset syncedAt so cloud deletes it
          item.isDeleted = true;
          item.updatedAt = DateTime.now();
          item.syncedAt = null;
          await _isar.sharedContents.put(item);
        }
      }
    });
  }

  // --- Unsynced Count for UI Badge ---
  Future<int> getUnsyncedCount(String userId) async {
    // Purge any legacy soft-deleted items that were never synced
    await _isar.writeTxn(() async {
      final orphans = await _isar.sharedContents
          .filter()
          .isDeletedEqualTo(true)
          .syncedAtIsNull()
          .findAll();
      for (var orphan in orphans) {
        await _isar.sharedContents.delete(orphan.id);
      }
    });

    return await _isar.sharedContents
        .filter()
        .group((q) => q.userIdEqualTo(userId).or().userIdEqualTo('local_user'))
        .isDeletedEqualTo(false)
        .syncedAtIsNull()
        .count();
  }

  // --- User Data Migration ---
  Future<void> migrateUserRecords({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;
    await _isar.writeTxn(() async {
      // 1. Migrate categories
      final categories = await _isar.categorys
          .filter()
          .userIdEqualTo(fromUserId)
          .findAll();
      for (var cat in categories) {
        cat.userId = toUserId;
        await _isar.categorys.put(cat);
      }

      // 2. Migrate shared content items
      final contents = await _isar.sharedContents
          .filter()
          .userIdEqualTo(fromUserId)
          .findAll();
      for (var item in contents) {
        item.userId = toUserId;
        await _isar.sharedContents.put(item);
      }
    });
  }

  Future<void> saveSyncedCategory(Category category) async {
    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });
  }

  Future<void> saveSyncedContent(SharedContent content) async {
    await _isar.writeTxn(() async {
      await _isar.sharedContents.put(content);
    });
  }
}
